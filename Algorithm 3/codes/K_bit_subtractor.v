`timescale 1ns / 1ps

// A - B = A + (~B + 1)
// o_Cout = 1 → A >= B
// o_Cout = 0 → A < B (borrow happened)

module full_adder (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule


module ripple_carry_adder #(
    parameter K = 9 // K is the total width
) (
    input  wire [K-1:0] i_A,
    input  wire [K-1:0] i_B,
    input  wire         i_Cin,
    output wire [K-1:0] o_Sum,
    output wire         o_Cout
);
    wire [K:0] carry_wire;
    assign carry_wire[0] = i_Cin;
    generate
        genvar i;
        for (i = 0; i < K; i = i + 1) begin : rca_chain
            full_adder fa_inst (
                .a    (i_A[i]),
                .b    (i_B[i]),
                .cin  (carry_wire[i]),
                .sum  (o_Sum[i]),
                .cout (carry_wire[i+1])
            );
        end
    endgenerate
    assign o_Cout = carry_wire[K];
endmodule

module k_bit_subtractor #(
    parameter K = 8
)(
    input  wire [K-1:0] i_A,
    input  wire [K-1:0] i_B,
    output wire [K-1:0] o_Diff,
    output wire         o_Cout
);

    // Invert B
    wire [K-1:0] b_inv = ~i_B;

    // Two's complement: A + (~B) + 1
    cla_adder #(
        .K(K)
    ) SUB_ADDER (
        .A   (i_A),
        .B   (b_inv),
        .Cin (1'b1),     // add +1
        .Sum (o_Diff),
        .Cout(o_Cout)    // "NOT BORROW" bit
    );

endmodule
