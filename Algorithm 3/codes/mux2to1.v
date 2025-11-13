`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.11.2025 10:47:32
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


// ================================================================
// N-bit 2:1 Multiplexer
// ================================================================
module mux2to1 #(parameter WIDTH = 8)(
    input  [WIDTH-1:0] A, B,
    input              s,
    output [WIDTH-1:0] Y
);
    assign Y = (A & {WIDTH{~s}}) | (B & {WIDTH{s}});
endmodule

