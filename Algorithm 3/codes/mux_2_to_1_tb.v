`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.11.2025 00:22:40
// Design Name: 
// Module Name: mux_2_to_1_tb
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


`timescale 1ns/1ps

module tb_mux2to1_1bit;

    reg a, b, s;
    wire y;

    mux2to1_1bit uut (.a(a), .b(b), .s(s), .y(y));

    initial begin
        $monitor("Time=%0t | a=%b | b=%b | s=%b | y=%b", $time, a, b, s, y);

        // Case 1: s = 0 → y = a
        a = 0; b = 1; s = 0; #10;
        a = 1; b = 0; s = 0; #10;

        // Case 2: s = 1 → y = b
        a = 0; b = 1; s = 1; #10;
        a = 1; b = 0; s = 1; #10;

        // Random
        a = 1; b = 1; s = 0; #10;
        a = 1; b = 1; s = 1; #10;

        $finish;
    end
endmodule

