`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.11.2025 16:27:03
// Design Name: 
// Module Name: top_vio_ila
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


module top_vio_ila_Alg3 (
    input wire i_Clk // Connect this to your 100MHz clock in the .xdc file
);

    // Set K_BITS=8 for on-board testing
    localparam K_BITS = 8;
    
    //----------------------------------------------------------------
    // 1. Wires controlled by VIO (Virtual Inputs)
    //----------------------------------------------------------------
    wire                    dut_Rst;
    wire                    dut_Start;
    wire [K_BITS-1:0]       dut_A;
    wire [K_BITS-1:0]       dut_B;
    wire [K_BITS-1:0]       dut_m;
    
    //----------------------------------------------------------------
    // 2. Wires monitored by VIO (Virtual Outputs)
    //----------------------------------------------------------------
    wire [K_BITS-1:0]       dut_P_final;
    wire                    dut_Done;

    //----------------------------------------------------------------
    // 3. Instantiate the DUT (Algorithm 3 Module)
    //----------------------------------------------------------------
    Montgomery_MMM_Alg3 #(
        .K_BITS(K_BITS)
    ) dut (
        .i_Clk     (i_Clk),
        .i_Rst     (dut_Rst),
        .i_Start   (dut_Start),
        .i_A       (dut_A),
        .i_B       (dut_B),
        .i_m       (dut_m),
        .o_P_final (dut_P_final),
        .o_Done    (dut_Done)
    );

    //----------------------------------------------------------------
    // 4. Instantiate the VIO IP
    //----------------------------------------------------------------
    vio_0 vio_inst (
      .clk        (i_Clk),
      // VIO Inputs (from DUT)
      .probe_in0  (dut_P_final), // 8 bits
      .probe_in1  (dut_Done),    // 1 bit
      
      // VIO Outputs (to DUT)
      .probe_out0 (dut_Rst),     // 1 bit
      .probe_out1 (dut_Start),   // 1 bit
      .probe_out2 (dut_A),       // 8 bits
      .probe_out3 (dut_B),       // 8 bits
      .probe_out4 (dut_m)        // 8 bits
    );

    //----------------------------------------------------------------
    // 5. Instantiate the ILA IP
    //----------------------------------------------------------------
    ila_0 ila_inst (
    	.clk        (i_Clk),
    	.probe0     (dut.state_reg),    
    	.probe1     (dut.counter_reg),  
    	.probe2     (dut.A_i),         
    	.probe3     (dut.P_reg),        
    	.probe4     (dut.t),      
    	.probe5     (dut.P_next),    
    	.probe6     (dut.final_sub_borrow) 
    );

endmodule
