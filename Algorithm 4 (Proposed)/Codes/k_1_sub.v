`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.11.2025 21:20:48
// Design Name: 
// Module Name: k_1_sub
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module full_adder (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire cout
);

    // Sum is the XOR of all three inputs
    assign sum = a ^ b ^ cin;
    
    // Carry-out is true if at least two inputs are true
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


module Subtractor_k_plus_1_logical #(
    parameter K_BITS = 256
) (
    input  wire [K_BITS:0] i_A,
    input  wire [K_BITS:0] i_B,
    output wire [K_BITS:0] o_Diff
);    

    // Width is k+1
    localparam WIDTH = K_BITS + 1;

    // Internal wire for the inverted B input
    wire [WIDTH-1:0] b_inv;
    
    // Internal wire for the carry chain
    // We need WIDTH+1 bits for the carries [0] to [WIDTH]
    wire [WIDTH:0]   carry_wire;

    // --- Two's Complement Logic ---
    
    // 1. Invert i_B (this is the '~B' part)
    assign b_inv = ~i_B;
    
    // 2. Set the initial carry-in to 1 (this is the '+ 1' part for 2's complement)
    assign carry_wire[0] = 1'b1;

    // 3. Generate the (k+1)-bit ripple-carry adder chain
    // This performs i_A + b_inv + 1

    generate
        genvar i;
        for (i = 0; i < WIDTH; i = i + 1) begin : fa_chain
            
            full_adder fa_inst (
                .a    (i_A[i]),
                .b    (b_inv[i]),
                .cin  (carry_wire[i]),
                .sum  (o_Diff[i]),       // The i-th bit of the result
                .cout (carry_wire[i+1])  // The carry-out to the next stage
            );
            
        end
    endgenerate
    
    // The final carry-out is carry_wire[WIDTH]
    // It is not used for the result o_Diff

endmodule
