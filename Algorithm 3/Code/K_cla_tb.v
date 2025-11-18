`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.11.2025 00:19:33
// Design Name: 
// Module Name: K_cla_tb
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

module tb_cla_adder;

    parameter K = 8;

    reg  [K-1:0] A, B;
    reg           Cin;
    wire [K-1:0]  Sum;
    wire          Cout;

    // Instantiate the CLA Adder
    cla_adder #(K) uut (
        .A(A),
        .B(B),
        .Cin(Cin),
        .Sum(Sum),
        .Cout(Cout)
    );

    initial begin
        $monitor("Time=%0t | A=%b (%0d) | B=%b (%0d) | Cin=%b | => Sum=%b (%0d) | Cout=%b",
                  $time, A, A, B, B, Cin, Sum, Sum, Cout);

        // Test 1: simple addition
        A = 8'b00001111; B = 8'b00000001; Cin = 0; #10;
        // Expected: 16 (00010000)

        // Test 2: with carry
        A = 8'b11110000; B = 8'b00010000; Cin = 0; #10;

        // Test 3: with carry-in
        A = 8'b11111111; B = 8'b00000001; Cin = 1; #10;

        // Test 4: random values
        A = 8'b10101010; B = 8'b01010101; Cin = 0; #10;
        A = 8'b11111111; B = 8'b11111111; Cin = 0; #10;

        $finish;
    end
endmodule

