`timescale 1ns / 1ps

module tb_subtractor_k_plus_1;

    // Set 'k' to 8 for this test. k+1 = 9 bits.
    parameter K_BITS = 8;
    localparam WIDTH = K_BITS + 1; // 9 bits

    // Inputs to the DUT
    reg  [K_BITS:0] tb_A;
    reg  [K_BITS:0] tb_B;
    
    // Output from the DUT
    wire [K_BITS:0] tb_Diff;

    // Instantiate the Device Under Test (DUT)
    Subtractor_k_plus_1_logical #(
        .K_BITS(K_BITS)
    ) dut (
        .i_A    (tb_A),
        .i_B    (tb_B),
        .o_Diff (tb_Diff)
    );

    // Initial block for stimulus
    initial begin
        // Initialize inputs
        tb_A = 0;
        tb_B = 0;

        // VCD file for waveform viewing (e.g., in Gtkwave)
        $dumpfile("tb_subtractor.vcd");
        $dumpvars(0, tb_subtractor_k_plus_1);

        // Display a header
        $display("Time | A (in) | B (in) | Diff (out) | Diff (signed)");
        $display("-------------------------------------------------------");
        $monitor(" %0t |  %d   |  %d   |    %d    |     %d", 
                 $time, tb_A, tb_B, tb_Diff, $signed(tb_Diff));

        // Test Case 1: 100 - 25 = 75
        #10;
        tb_A = 100;
        tb_B = 25;

        // Test Case 2: 50 - 50 = 0
        #10;
        tb_A = 50;
        tb_B = 50;

        // Test Case 3: 10 - 20 = -10
        // Expected unsigned output for -10 (9-bit): 2^9 - 10 = 512 - 10 = 502
        #10;
        tb_A = 10;
        tb_B = 20;

        // Test Case 4: 0 - 1 = -1
        // Expected unsigned output for -1 (9-bit): 511
        #10;
        tb_A = 0;
        tb_B = 1;

        // Test Case 5: 150 - 160 = -10 (same as case 3)
        #10;
        tb_A = 150;
        tb_B = 160;

        // Test Case 6: Max positive (255) - 1 = 254
        #10;
        tb_A = 255; // 9'b011111111
        tb_B = 1;
        
        // Test Case 7: Min negative (-256) - 1 = -257 (wraps to 255)
        #10;
        tb_A = 256; // 9'b100000000 (this is -256 signed)
        tb_B = 1;   // 9'b000000001
        
        // Finish simulation
        #10;
        $finish;
    end

endmodule