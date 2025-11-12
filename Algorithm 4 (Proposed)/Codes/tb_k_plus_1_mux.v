`timescale 1ns / 1ps

module tb_mux_k_plus_1;

    // Set 'k' to 8 for this test. k+1 = 9 bits.
    parameter K_BITS = 8;
    localparam WIDTH = K_BITS + 1; // 9 bits

    // Inputs to the DUT
    reg  [K_BITS:0] tb_A;
    reg  [K_BITS:0] tb_B;
    reg             tb_Sel;
    
    // Output from the DUT
    wire [K_BITS:0] tb_Y;

    // Instantiate the Device Under Test (DUT)
    Mux_2to1_k_plus_1_logical #(
        .K_BITS(K_BITS)
    ) dut (
        .i_A    (tb_A),
        .i_B    (tb_B),
        .i_Sel  (tb_Sel),
        .o_Y    (tb_Y)
    );

    // Initial block for stimulus
    initial begin
        // Initialize inputs
        tb_A = 0;
        tb_B = 0;
        tb_Sel = 0;

        // VCD file for waveform viewing (e.g., in Gtkwave)
        $dumpfile("tb_mux.vcd");
        $dumpvars(0, tb_mux_k_plus_1);

        // Display a header
        $display("Time | Sel | A (in) | B (in) | Y (out)");
        $display("----------------------------------------");
        $monitor(" %0t |  %b  |  %d   |  %d   |   %d", 
                 $time, tb_Sel, tb_A, tb_B, tb_Y);

        // Test Case 1: Select A (Sel=0)
        #10;
        tb_A = 123;
        tb_B = 456; // This value (9-bit) is fine
        tb_Sel = 0;
        // Expected Y = 123

        // Test Case 2: Select B (Sel=1)
        #10;
        tb_Sel = 1;
        // Expected Y = 456
        
        // Test Case 3: Change inputs while Sel=1
        #10;
        tb_A = 99;
        tb_B = 88;
        // Expected Y = 88
        
        // Test Case 4: Select A again (Sel=0)
        #10;
        tb_Sel = 0;
        // Expected Y = 99
        
        // Test Case 5: All 1s and All 0s
        #10;
        tb_A = {WIDTH{1'b1}}; // 9'h1FF (511)
        tb_B = {WIDTH{1'b0}}; // 9'h000 (0)
        // Expected Y = 511
        
        // Test Case 6: Select B
        #10;
        tb_Sel = 1;
        // Expected Y = 0
        
        // Finish simulation
        #10;
        $finish;
    end

endmodule