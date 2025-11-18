`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.11.2025 22:10:21
// Design Name: 
// Module Name: mux2to1
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


module Mux_2to1_k_plus_1_logical #(
    parameter K_BITS = 256
) (
    input  wire [K_BITS:0] i_A,
    input  wire [K_BITS:0] i_B,
    input  wire          i_Sel,
    output wire [K_BITS:0] o_Y
);

    // Width is k+1
    localparam WIDTH = K_BITS + 1;

    // Internal wires to "expand" the 1-bit i_Sel 
    // to match the (k+1) bus width for bitwise operations
    wire [WIDTH-1:0] sel_A;
    wire [WIDTH-1:0] sel_B;
    
    // sel_A will be all 1s if i_Sel is 0, and all 0s if i_Sel is 1
    assign sel_A = {WIDTH{~i_Sel}}; 
    
    // sel_B will be all 0s if i_Sel is 0, and all 1s if i_Sel is 1
    assign sel_B = {WIDTH{i_Sel}};

    // --- Bitwise Mux Logic ---
    assign o_Y = (i_A & sel_A) | (i_B & sel_B);

endmodule