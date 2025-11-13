`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.11.2025 22:08:03
// Design Name: 
// Module Name: cla
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


module cla_adder #(parameter K = 32)(
    input  [K-1:0] A, B,
    input          Cin,
    output [K-1:0] Sum,
    output         Cout
);
    localparam N = (K + 3) / 4;

    wire [N:0] carry;
    assign carry[0] = Cin;

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : CLA_BLOCKS
            wire [3:0] Ablk = A[i*4 +: 4];
            wire [3:0] Bblk = B[i*4 +: 4];
            wire [3:0] Sblk;
            wire cout_blk, g_blk, p_blk;

            cla4 C4 (
                .A(Ablk), .B(Bblk), .Cin(carry[i]),
                .Sum(Sblk), .Cout(cout_blk),
                .Gout(g_blk), .Pout(p_blk)
            );

            assign Sum[i*4 +: 4] = Sblk;
            assign carry[i+1] = g_blk | (p_blk & carry[i]);
        end
    endgenerate

    assign Cout = carry[N];
endmodule
