module ModMult_Normal #(parameter K = 8)(
    input              clk,
    input              rst,
    input              start,
    input  [K-1:0]     A,
    input  [K-1:0]     B,
    input  [K-1:0]     m,
    output reg [K-1:0] C,
    output reg         done
);

    // --------------------------------------------
    // Internal Montgomery Parameters
    // --------------------------------------------
    localparam W = 32;   // internal MM3 width

    // FSM states
    localparam S_IDLE = 0,
               S_A_M  = 1,
               S_B_M  = 2,
               S_C_M  = 3,
               S_OUT  = 4,
               S_DONE = 5;

    reg [2:0] state, next_state;

    // MM3 interface
    reg        start_mm;
    wire       done_mm;
    wire [K-1:0] mm_out;

    // values fed to MM3
    reg [K-1:0] opA, opB;

    // stored Montgomery results
    reg [K-1:0] A_M, B_M, C_M;

    // precomputed R and R^2 mod m
    reg [K-1:0] R_mod_m, R2_mod_m;

    // --------------------------------------------
    // Instantiate Algorithm 3 Montgomery Multiplier
    // --------------------------------------------
    MMM_Algo3 #(K) MM3 (
        .clk(clk),
        .rst(rst),
        .start(start_mm),
        .A(opA),
        .B(opB),
        .m(m),
        .P_out(mm_out),
        .done(done_mm)
    );

    // --------------------------------------------
    // Precompute R mod m and R^2 mod m
    // R = 2^K
    // R mod m = (1<<K) % m
    // R² mod m = (R mod m)^2 % m
    // --------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            R_mod_m  <= 0;
            R2_mod_m <= 0;
        end 
        else if (start) begin
            R_mod_m  <= ((1 << K) % m);
            R2_mod_m <= (((1 << K) % m) * ((1 << K) % m)) % m;
        end
    end

    // --------------------------------------------
    // MAIN SEQUENTIAL FSM
    // --------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state    <= S_IDLE;
            done     <= 0;
            C        <= 0;
            start_mm <= 0;
        end 
        else begin
            state <= next_state;

            case (state)

                S_IDLE: begin
                    done     <= 0;
                    start_mm <= 0;
                end

                S_A_M: begin
                    if (done_mm) begin
                        A_M     <= mm_out;
                        start_mm <= 0;
                    end
                end

                S_B_M: begin
                    if (done_mm) begin
                        B_M     <= mm_out;
                        start_mm <= 0;
                    end
                end

                S_C_M: begin
                    if (done_mm) begin
                        C_M     <= mm_out;
                        start_mm <= 0;
                    end
                end

                S_OUT: begin
                    if (done_mm) begin
                        C       <= mm_out;
                        start_mm <= 0;
                    end
                end

                S_DONE: begin
                    done <= 1;
                end
            endcase
        end
    end

    // --------------------------------------------
    // NEXT-STATE LOGIC + MM3 START CONTROL
    // --------------------------------------------
    always @(*) begin
        next_state = state;
        start_mm = 0;
        opA = A_M;
        opB = B_M;

        case (state)

            // ------------------------------------
            // Start sequence when TB pulses start
            // ------------------------------------
            S_IDLE: begin
                if (start) begin
                    opA     = A;
                    opB     = R2_mod_m;
                    start_mm = 1;
                    next_state = S_A_M;
                end
            end

            // ------------------------------------
            // Compute A_M = MM(A, R²)
            // ------------------------------------
            S_A_M: begin
                if (done_mm) begin
                    opA     = B;
                    opB     = R2_mod_m;
                    start_mm = 1;
                    next_state = S_B_M;
                end
            end

            // ------------------------------------
            // Compute B_M = MM(B, R²)
            // ------------------------------------
            S_B_M: begin
                if (done_mm) begin
                    opA     = A_M;
                    opB     = B_M;
                    start_mm = 1;
                    next_state = S_C_M;
                end
            end

            // ------------------------------------
            // Compute C_M = MM(A_M, B_M)
            // ------------------------------------
            S_C_M: begin
                if (done_mm) begin
                    opA     = C_M;
                    opB     = 1;
                    start_mm = 1;
                    next_state = S_OUT;
                end
            end

            // ------------------------------------
            // Convert back: C = MM(C_M, 1)
            // ------------------------------------
            S_OUT: begin
                if (done_mm)
                    next_state = S_DONE;
            end

            S_DONE: begin
                if (!start)
                    next_state = S_IDLE;
            end
        endcase
    end

endmodule
