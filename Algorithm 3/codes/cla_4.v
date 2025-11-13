`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.11.2025 22:07:03
// Design Name: 
// Module Name: cla_4
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

module cla4 (
    input  [3:0] A, B,
    input        Cin,
    output [3:0] Sum,
    output       Cout,
    output       Gout, Pout
);
    wire [3:0] G, P, C;

    assign G = A & B;
    assign P = A ^ B;

    assign C[0] = Cin;
    assign C[1] = G[0] | (P[0] & C[0]);
    assign C[2] = G[1] | (P[1] & G[0]) | (P[1] & P[0] & C[0]);
    assign C[3] = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0])
                | (P[2] & P[1] & P[0] & C[0]);

    assign Cout = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1])
                | (P[3] & P[2] & P[1] & G[0])
                | (P[3] & P[2] & P[1] & P[0] & C[0]);

    assign Sum = P ^ C;

    assign Gout = Cout;
    assign Pout = &P;
endmodule