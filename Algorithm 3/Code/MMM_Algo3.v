`timescale 1ns / 1ps

module Montgomery_MMM_Alg3 #(
    parameter K_BITS = 256
)(
    input  wire          i_Clk,
    input  wire          i_Rst,
    input  wire          i_Start,
    input  wire [K_BITS-1:0] i_A,
    input  wire [K_BITS-1:0] i_B,
    input  wire [K_BITS-1:0] i_m,
    output wire [K_BITS-1:0] o_P_final,
    output wire          o_Done
);

// ----------------------------------------------------
// FSM
// ----------------------------------------------------
localparam STATE_IDLE    = 3'b000;
localparam STATE_INIT    = 3'b001;
localparam STATE_COMPUTE = 3'b010;
localparam STATE_FINISH  = 3'b011;
localparam STATE_DONE    = 3'b100;

reg [2:0] state_reg, state_next;
reg [$clog2(K_BITS):0] counter_reg, counter_next;

always @(posedge i_Clk or posedge i_Rst) begin
    if (i_Rst) begin
        state_reg   <= STATE_IDLE;
        counter_reg <= 0;
    end else begin
        state_reg   <= state_next;
        counter_reg <= counter_next;
    end
end

always @(*) begin
    state_next   = state_reg;
    counter_next = counter_reg;

    case (state_reg)
        STATE_IDLE:   if (i_Start)         state_next = STATE_INIT;

        STATE_INIT:   begin counter_next=0; state_next = STATE_COMPUTE; end

        STATE_COMPUTE: if (counter_reg == K_BITS-1)
                           state_next = STATE_FINISH;
                       else
                           counter_next = counter_reg + 1;

        STATE_FINISH:  state_next = STATE_DONE;
        STATE_DONE:    if (!i_Start) state_next = STATE_IDLE;
    endcase
end

assign o_Done = (state_reg == STATE_DONE);

// ----------------------------------------------------
// DATA PATH
// ----------------------------------------------------
reg [K_BITS-1:0] P_reg;
wire [K_BITS-1:0] P_next;

wire A_i     = (state_reg == STATE_COMPUTE) ? i_A[counter_reg] : 1'b0;
wire B0      = i_B[0];
wire t       = P_reg[0] ^ (A_i & B0);

// MUX: A_i ? B : 0
wire [K_BITS-1:0] term_AB;
Mux_2to1_k_plus_1_logical #(.K_BITS(K_BITS-1)) M1 (
    .i_A({K_BITS{1'b0}}),
    .i_B(i_B),
    .i_Sel(A_i),
    .o_Y(term_AB)
);

// MUX: t ? m : 0
wire [K_BITS-1:0] term_tm;
Mux_2to1_k_plus_1_logical #(.K_BITS(K_BITS-1)) M2 (
    .i_A({K_BITS{1'b0}}),
    .i_B(i_m),
    .i_Sel(t),
    .o_Y(term_tm)
);

// -------------------------------
// First add:   sum1 = P + A_i*B
// -------------------------------
wire [K_BITS-1:0] sum1_sum;
wire sum1_cout;

// --- FIX 1: ADDED THIS MISSING INSTANTIATION ---
cla_adder #(.K(K_BITS)) ADD1 (
    .A(P_reg),
    .B(term_AB),
    .Cin(1'b0),
    .Sum(sum1_sum),
    .Cout(sum1_cout)
);

wire [K_BITS:0] sum1_full = {sum1_cout, sum1_sum};

// -------------------------------
// Second add: sum1 + t*m
// -------------------------------
wire [K_BITS:0] term_tm_ext = {1'b0, term_tm};
wire [K_BITS:0] P_new_full;
wire cout2;

// --- FIX 2: CORRECTED PORT NAMES FOR RIPPLE_CARRY_ADDER ---
ripple_carry_adder #(.K(K_BITS+1)) ADD2 (
    .i_A    (sum1_full),
    .i_B    (term_tm_ext),
    .i_Cin  (1'b0),
    .o_Sum  (P_new_full),
    .o_Cout (cout2)
);

// divide by 2
assign P_next = P_new_full[K_BITS:1];

// -------------------------------
// FINAL SUBTRACTION (if P >= m)
// -------------------------------
wire [K_BITS-1:0] final_sub_diff;
wire final_sub_borrow;

// subtractor: P_reg - m
k_bit_subtractor #(.K(K_BITS)) SUB_FINAL (
    .i_A(P_reg),
    .i_B(i_m),
    .o_Diff(final_sub_diff),
    .o_Cout(final_sub_borrow)   // borrow=1 -> P_reg >= m
);

// finalize output
Mux_2to1_k_plus_1_logical #(.K_BITS(K_BITS-1)) M3 (
    .i_A(P_reg),
    .i_B(final_sub_diff),
    .i_Sel(final_sub_borrow),
    .o_Y(o_P_final)
);

// ----------------------------------------------------
// UPDATE P REGISTER
// ----------------------------------------------------
always @(posedge i_Clk or posedge i_Rst) begin
    if (i_Rst) begin
        P_reg <= {K_BITS{1'b0}};
    end else begin
        case (state_reg)
            STATE_INIT:   P_reg <= 0;
            STATE_COMPUTE: P_reg <= P_next;
        endcase
    end
end

endmodule