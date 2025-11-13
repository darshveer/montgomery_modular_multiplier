// ====================================================================
// FINAL STABLE MONTGOMERY MULTIPLIER (ALGORITHM 3)
// Inputs: 8-bit  A, B, m (must be odd for Montgomery)
// Output: 8-bit Montgomery result
// Internal datapath: FULL 32-BIT - prevents ANY overflow
// ====================================================================
module MMM_Algo3 #(parameter K = 8)(
    input                 clk,
    input                 rst,
    input                 start,
    input  [K-1:0]        A,
    input  [K-1:0]        B,
    input  [K-1:0]        m,
    output reg [K-1:0]    P_out,
    output reg            done
);

    // FIXED INTERNAL WIDTH = 32 BITS → no overflow ever
    localparam W = 32;

    reg [W-1:0] T;
    reg [$clog2(K+1)-1:0] cnt;
    reg [1:0] state, next_state;

    localparam IDLE = 2'b00;
    localparam ITER = 2'b01;
    localparam DONE = 2'b10;

    // ------------------------------------------------------------
    // gamma = Ai ? B : 0
    // ------------------------------------------------------------
    wire Ai = A[cnt];
    wire [K-1:0] gamma_small;
    wire [K-1:0] zero_small = {K{1'b0}};

    mux2to1 #(K) M1 (
        .A(zero_small),
        .B(B),
        .s(Ai),
        .Y(gamma_small)
    );

    wire [W-1:0] gamma = { {(W-K){1'b0}}, gamma_small };

    // ------------------------------------------------------------
    // T + gamma  (full 32-bit add)
    // ------------------------------------------------------------
    wire [W-1:0] T_plus_gamma;
    wire cout1;

    cla_adder #(W) ADD1 (
        .A(T),
        .B(gamma),
        .Cin(1'b0),
        .Sum(T_plus_gamma),
        .Cout(cout1)
    );

    wire q = T_plus_gamma[0];

    // ------------------------------------------------------------
    // q ? m : 0  (extend to 32 bits)
    // ------------------------------------------------------------
    wire [K-1:0] qm_small;
    mux2to1 #(K) M2 (
        .A(zero_small),
        .B(m),
        .s(q),
        .Y(qm_small)
    );

    wire [W-1:0] qm = { {(W-K){1'b0}}, qm_small };

    // ------------------------------------------------------------
    // T + gamma + q*m (full 32-bit add)
    // ------------------------------------------------------------
    wire [W-1:0] T_plus_qm;
    wire cout2;

    cla_adder #(W) ADD2 (
        .A(T_plus_gamma),
        .B(qm),
        .Cin(1'b0),
        .Sum(T_plus_qm),
        .Cout(cout2)
    );

    wire [W-1:0] T_next = T_plus_qm >> 1;

    // ------------------------------------------------------------
    // FSM
    // ------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            T <= 0;
            cnt <= 0;
            done <= 0;
            P_out <= 0;
        end else begin
            state <= next_state;
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        T <= 0;
                        cnt <= 0;
                    end
                end
                ITER: begin
                    T <= T_next;
                    if (cnt < K-1)
                        cnt <= cnt + 1;
                end
                DONE: begin
                    done <= 1;
                    P_out <= T[K-1:0];
                end
            endcase
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: if (start) next_state = ITER;
            ITER: if (cnt == K-1) next_state = DONE;
            DONE: if (!start) next_state = IDLE;
        endcase
    end

endmodule
