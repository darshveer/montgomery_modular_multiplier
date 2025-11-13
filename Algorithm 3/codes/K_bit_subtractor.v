`timescale 1ns / 1ps

// A - B = A + (~B + 1)
// o_Cout = 1 → A >= B
// o_Cout = 0 → A < B (borrow happened)

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
