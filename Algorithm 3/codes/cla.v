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
            
            // --- BUG FIX ---
            // This logic safely handles K values that are not multiples of 4
            // It pads the last (partial) block with zeros.
            wire [3:0] Ablk = (i*4 + 4 > K) ? {4'b0, A[K-1 : i*4]} : A[i*4 +: 4];
            wire [3:0] Bblk = (i*4 + 4 > K) ? {4'b0, B[K-1 : i*4]} : B[i*4 +: 4];
            // --- END BUG FIX ---
            
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
            
            // --- BUG FIX ---
            // This logic correctly assigns the Sum for the last partial block
            if (i*4 + 4 > K)
                assign Sum[K-1 : i*4] = Sblk[K - 1 - i*4 : 0];
            else
                assign Sum[i*4 +: 4] = Sblk;
            // --- END BUG FIX ---
                
            assign Gg[i] = Gblk;
            assign Pg[i] = Pblk;
            assign carry[i+1] = Gblk | (Pblk & carry[i]);
        end
    endgenerate

    assign Cout = carry[N];
endmodule
