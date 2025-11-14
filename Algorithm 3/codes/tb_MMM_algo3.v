`timescale 1ns / 1ps

module tb_montgomery_alg3;

    //================================================================
    // Test Parameters
    //================================================================
    
    // Override K_BITS to 8 for simulation
    localparam K_BITS = 8;
    
    // Clock period (10 ns = 100 MHz)
    localparam CLK_PERIOD = 10;
    
    //================================================================
    // Testbench Signals
    //================================================================

    // --- Registers for DUT Inputs ---
    reg                    tb_clk;
    reg                    tb_rst;
    reg                    tb_start;
    reg [K_BITS-1:0]       tb_A;
    reg [K_BITS-1:0]       tb_B;
    reg [K_BITS-1:0]       tb_m;

    // --- Wires for DUT Outputs ---
    wire [K_BITS-1:0]      tb_P_final;
    wire                   tb_done;

    // --- Test Case Counter ---
    integer test_case_count = 0;

    //================================================================
    // Instantiate the Device Under Test (DUT)
    //================================================================
    
    Montgomery_MMM_Alg3 #(
        .K_BITS(K_BITS) // Override parameter to 8
    ) dut (
        .i_Clk     (tb_clk),
        .i_Rst     (tb_rst),
        .i_Start   (tb_start),
        
        .i_A       (tb_A),
        .i_B       (tb_B),
        .i_m       (tb_m),
        
        .o_P_final (tb_P_final),
        .o_Done    (tb_done)
    );

    //================================================================
    // Clock Generator
    //================================================================
    
    always begin
        tb_clk = 1'b0;
        #(CLK_PERIOD / 2);
        tb_clk = 1'b1;
        #(CLK_PERIOD / 2);
    end

    //================================================================
    // Reusable Test Task
    //================================================================
    
    // This task runs one complete test.
    task run_test;
        input [K_BITS-1:0] A_in;
        input [K_BITS-1:0] B_in;
        input [K_BITS-1:0] m_in;
        input [K_BITS-1:0] P_expected;
        
        begin
            test_case_count = test_case_count + 1;
            $display("-----------------------------------------------------------------");
            $display("Time: %0t | --- STARTING TEST CASE %0d ---", $time, test_case_count);
            $display("Time: %0t | A=%d, B=%d, m=%d. Expected P = %d", $time, A_in, B_in, m_in, P_expected);
            
            // 1. Apply inputs
            @(posedge tb_clk);
            tb_A = A_in;
            tb_B = B_in;
            tb_m = m_in;
            
            // 2. Send 1-cycle start pulse
            tb_start = 1'b1;
            @(posedge tb_clk);
            tb_start = 1'b0;
            
            // 3. Wait for the 'Done' signal
            @(posedge tb_done);
            $display("Time: %0t | --- OPERATION DONE (o_Done = 1) ---", $time);

            // 4. Check the result
            #1; // Wait 1ns for signals to settle
            if (tb_P_final == P_expected) begin
                $display("Time: %0t | +++ TEST %0d SUCCESS! Result P = %d +++", 
                         $time, test_case_count, tb_P_final);
            end else begin
                $display("Time: %0t | *** TEST %0d FAILED! Result P = %d (Expected %d) ***", 
                         $time, test_case_count, tb_P_final, P_expected);
            end

            // 5. Wait for FSM to return to IDLE
            @(negedge tb_done);
            $display("Time: %0t | --- FSM returned to IDLE (o_Done = 0) ---", $time);
            @(posedge tb_clk);
        end
    endtask

    //================================================================
    // Stimulus
    //================================================================
    
    initial begin
        // --- 1. Initialize all inputs ---
        $display("Time: %0t | --- SIMULATION START (K_BITS=%0d) ---", $time, K_BITS);
        tb_clk = 0;
        tb_rst = 1'b1; // Assert reset
        tb_start = 1'b0;
        tb_A = 0;
        tb_B = 0;
        tb_m = 0;
        
        // --- 2. Wait for 2 cycles with reset asserted ---
        #(CLK_PERIOD * 2);
        
        // --- 3. De-assert reset ---
        $display("Time: %0t | --- RELEASING RESET ---", $time);
        tb_rst = 1'b0;

        // --- 4. Run all test cases ---
        // Test vectors are for (A * B * R_inv) % m
        // For K=8, R=256.
        
        // Test 1: A=211, B=198, m=225. R_inv=196.
        // P = (211 * 198 * 196) % 225 = 63
        run_test(8'd10, 8'd11, 8'd225, 8'd63);
        
        // Test 2: A=10, B=20, m=101. R_inv=58.
        // P = (10 * 20 * 58) % 101 = 86
        run_test(8'd10,  8'd20,  8'd101, 8'd86);
        
        // Test 3: Zero A
        // P = (0 * 198 * 196) % 225 = 0
        run_test(8'd0,   8'd198, 8'd225, 8'd0);
        
        // Test 4: Simple case
        // P = (1 * 2 * 196) % 225 = 392 % 225 = 167
        run_test(8'd1,   8'd2,   8'd225, 8'd167);

        // --- 5. Finish simulation ---
        $display("-----------------------------------------------------------------");
        $display("Time: %0t | --- ALL TESTS COMPLETE ---", $time);
        #(CLK_PERIOD * 3);
        $finish;
    end
    

endmodule