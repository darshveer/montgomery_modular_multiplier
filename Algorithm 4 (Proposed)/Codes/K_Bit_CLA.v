`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.11.2025 21:50:36
// Design Name: 
// Module Name: K_Bit_CLA
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
    assign C[3] = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) |
                  (P[2] & P[1] & P[0] & C[0]);
    assign Cout = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) |
                  (P[3] & P[2] & P[1] & G[0]) |
                  (P[3] & P[2] & P[1] & P[0] & C[0]);

    assign Sum = P ^ C[3:0];

    assign Gout = Cout;
    assign Pout = &P; 
endmodule

module cla_adder #(parameter K = 32) (
    input  [K-1:0] A, B,
    input          Cin,
    output [K-1:0] Sum,
    output         Cout
);
    localparam N = (K + 3) / 4;  
    wire [N:0] carry;
    wire [N-1:0] Gg, Pg;
    assign carry[0] = Cin;

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : CLA_BLOCKS
            wire [3:0] Ablk = A[i*4 +: 4];
            wire [3:0] Bblk = B[i*4 +: 4];
            wire [3:0] Sblk;
            wire Cout_blk, Gblk, Pblk;

            cla4 cla_block (
                .A(Ablk),
                .B(Bblk),
                .Cin(carry[i]),
                .Sum(Sblk),
                .Cout(Cout_blk),
                .Gout(Gblk),
                .Pout(Pblk)
            );

            assign Sum[i*4 +: 4] = Sblk;
            assign Gg[i] = Gblk;
            assign Pg[i] = Pblk;
            assign carry[i+1] = Gblk | (Pblk & carry[i]);
        end
    endgenerate

    assign Cout = carry[N];
endmodule
