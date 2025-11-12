`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.11.2025 14:43:38
// Design Name: 
// Module Name: top_MMM
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


module top_vio_ila (
    input wire i_Clk // Connect this to your 100MHz clock in the .xdc file
);

    // Set K_BITS for the DUT here
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
    // 3. Instantiate the DUT (your Montgomery module)
    //----------------------------------------------------------------
    Montgomery_MMM_Datapath #(
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
    // 4. Instantiate the VIO IP (Virtual Input/Output)
    //----------------------------------------------------------------
    // This instantiation matches the new configuration with
    // separate probes for each signal.
    vio_0 u_vio (
      .clk        (i_Clk),
      
      // VIO Inputs (from DUT)
      .probe_in0  (dut_P_final), // probe_in0 is 8 bits
      .probe_in1  (dut_Done),    // probe_in1 is 1 bit
      
      // VIO Outputs (to DUT)
      .probe_out0 (dut_Rst),     // probe_out0 is 1 bit
      .probe_out1 (dut_Start),   // probe_out1 is 1 bit
      .probe_out2 (dut_A),       // probe_out2 is 8 bits
      .probe_out3 (dut_B),       // probe_out3 is 8 bits
      .probe_out4 (dut_m)        // probe_out4 is 8 bits
    );

    //----------------------------------------------------------------
    // 5. Instantiate the ILA IP (Integrated Logic Analyzer)
    //----------------------------------------------------------------
    // This IP is unchanged from the previous answer.
    ila_0 u_ila (
    	.clk        (i_Clk),
    	.probe0     (dut.state_reg),    // 2 bits
    	.probe1     (dut.counter_reg),  // 4 bits
    	.probe2     (dut.A_i_wire),     // 1 bit
    	.probe3     (dut.P_reg),        // 8 bits
    	.probe4     (dut.tau_wire),     // 9 bits
    	.probe5     (dut.Z_wire),       // 9 bits
    	.probe6     (dut.P_next)        // 8 bits
    );

endmodule
