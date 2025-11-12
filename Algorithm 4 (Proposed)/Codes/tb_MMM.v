`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.11.2025 14:21:03
// Design Name: 
// Module Name: tb_MMM
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


module tb_montgomery_mmm;

    //================================================================
    // Test Parameters
    //================================================================
    
    // We will use k=8 to match the paper's example
    localparam K_BITS = 8;
    
    // Clock period (10 ns = 100 MHz)
    localparam CLK_PERIOD = 10;

    //================================================================
    // Testbench Signals
    //================================================================

    // --- Registers for DUT Inputs ---
    reg                    tb_Clk;
    reg                    tb_Rst;
    reg                    tb_Start;
    reg [K_BITS-1:0]       tb_A;
    reg [K_BITS-1:0]       tb_B;
    reg [K_BITS-1:0]       tb_m;

    // --- Wires for DUT Outputs ---
    wire [K_BITS-1:0]      tb_P_final;
    wire                   tb_Done;

    // --- Test Case Counter ---
    integer test_case_count = 0;

    //================================================================
    // Instantiate the Device Under Test (DUT)
    //================================================================
    
    Montgomery_MMM_Datapath #(
        .K_BITS(K_BITS) // Override parameter to 8
    ) dut (
        .i_Clk     (tb_Clk),
        .i_Rst     (tb_Rst),
        .i_Start   (tb_Start),
        .i_A       (tb_A),
        .i_B       (tb_B),
        .i_m       (tb_m),
        .o_P_final (tb_P_final),
        .o_Done    (tb_Done)
    );

    //================================================================
    // Clock Generator
    //================================================================
    
    always begin
        tb_Clk = 1'b0;
        #(CLK_PERIOD / 2);
        tb_Clk = 1'b1;
        #(CLK_PERIOD / 2);
    end

    //================================================================
    // Test Task
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
            $display("Time: %0t | A=%d, B=%d, m=%d", $time, A_in, B_in, m_in);
            
            // 1. Apply inputs and start
            @(posedge tb_Clk);
            tb_A = A_in;
            tb_B = B_in;
            tb_m = m_in;
            tb_Start = 1'b1;
            
            // 2. Wait for the 'Done' signal
            @(posedge tb_Done);
            $display("Time: %0t | --- OPERATION DONE (o_Done = 1) ---", $time);

            // 3. Check the result
            #1; // Wait 1ns for signals to settle
            if (tb_P_final == P_expected) begin
                $display("Time: %0t | +++ TEST %0d SUCCESS! Result P = %d (Expected %d) +++", 
                         $time, test_case_count, tb_P_final, P_expected);
            end else begin
                $display("Time: %0t | *** TEST %0d FAILED! Result P = %d (Expected %d) ***", 
                         $time, test_case_count, tb_P_final, P_expected);
            end

            // 4. De-assert Start and wait for FSM to return to IDLE
            @(posedge tb_Clk);
            tb_Start = 1'b0;
            
            // Wait for o_Done to go low
            @(negedge tb_Done);
            $display("Time: %0t | --- FSM returned to IDLE ---", $time);
        end
    endtask

    //================================================================
    // Stimulus
    //================================================================
    
    initial begin
        // --- 1. Initialize all inputs ---
        $display("Time: %0t | --- SIMULATION START (K_BITS=%0d) ---", $time, K_BITS);
        tb_Clk = 0;
        tb_Rst = 1'b1; // Assert reset
        tb_Start = 1'b0;
        tb_A = 0;
        tb_B = 0;
        tb_m = 0;
        
        // --- 2. Wait for 2 cycles with reset asserted ---
        #(CLK_PERIOD * 2);
        
        // --- 3. De-assert reset ---
        $display("Time: %0t | --- RELEASING RESET ---", $time);
        tb_Rst = 1'b0;

        // --- 4. Run all test cases ---
        run_test(8'd211, 8'd198, 8'd225, 8'd63);  // Test 1: Paper's example
        run_test(8'd0,   8'd198, 8'd225, 8'd0);   // Test 2: Zero A
        run_test(8'd211, 8'd0,   8'd225, 8'd0);   // Test 3: Zero B
        run_test(8'd1,   8'd2,   8'd225, 8'd167); // Test 4: Simple case
        run_test(8'd10,  8'd20,  8'd101, 8'd86);  // Test 5: New modulus
        
        // --- 5. Finish simulation ---
        $display("-----------------------------------------------------------------");
        $display("Time: %0t | --- ALL TESTS COMPLETE ---", $time);
        #(CLK_PERIOD * 3);
        $finish;
    end
    
    initial begin
        $dumpfile("tb_montgomery.vcd");
        $dumpvars(0, tb_montgomery_mmm);
        
        $monitor("Time: %0t | State: %b | Count: %d | A_i: %b | P_reg: %d | tau: %d | Z: %d | P_next: %d",
            $time,
            dut.state_reg, dut.counter_reg,
            dut.A_i_wire,
            dut.P_reg,
            dut.tau_wire,
            dut.Z_wire,
            dut.P_next);
    end

endmodule