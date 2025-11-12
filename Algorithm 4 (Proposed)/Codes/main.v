`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.11.2025 13:58:31
// Design Name: 
// Module Name: main
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

module Montgomery_MMM_Datapath #(
    parameter K_BITS = 256 // 'k' (bit-length)
) (
    // Control Signals
    input  wire          i_Clk,
    input  wire          i_Rst,
    input  wire          i_Start, // Start signal
    
    // Data Inputs
    input  wire [K_BITS-1:0] i_A, // Multiplier A
    input  wire [K_BITS-1:0] i_B, // Multiplicand B
    input  wire [K_BITS-1:0] i_m, // Modulus m
    
    // Data Outputs
    output wire [K_BITS-1:0] o_P_final, // Final result P
    output wire          o_Done     // Operation finished
);

    // --- FSM State Definitions ---
    localparam STATE_IDLE    = 2'b00;
    localparam STATE_INIT    = 2'b11; // New state to initialize P
    localparam STATE_COMPUTE = 2'b01;
    localparam STATE_DONE    = 2'b10;

    reg [1:0] state_reg, state_next;

    // --- Main Registers ---
    reg [K_BITS-1:0] P_reg;  // P register (k bits)
    wire [K_BITS-1:0] P_next;   // Combinational Wire for next P
    
    // Counter for k iterations
    reg [$clog2(K_BITS):0] counter_reg, counter_next;

    // --- Combinational Datapath Wires ---
    
    // Stage 1 Wires (P + γ)
    wire             A_i_wire;    // Current bit of A
    wire [K_BITS-1:0]  gamma_wire;  // Output of Mux 1 (k bits)
    wire [K_BITS-1:0]  adder1_sum;  // Sum from k-bit adder
    wire             adder1_cout; // Carry from k-bit adder
    wire [K_BITS:0]    tau_wire;    // τ value (k+1 bits)

    // Stage 2 Wires (τ ± m)
    wire [K_BITS:0]  m_extended;  // m extended to k+1 bits
    wire [K_BITS:0]  add_m_result;// (τ + m) result
    wire             add_m_carry; // C_out(τ + m)
    wire [K_BITS:0]  sub_m_result;// (τ - m) result
    wire [K_BITS:0]  Z_wire;      // Output of Mux 2

    // Stage 3 Wires (α and >> 1)
    wire             tau_0_wire;  // LSB of τ
    wire [K_BITS:0]  alpha_wire;  // Output of Mux 3
    // P_next is the output of this stage
    
    //==================================================================
    // 1. CONTROL UNIT (FSM)
    //==================================================================

    // FSM sequential logic (state and counter registers)
    always @(posedge i_Clk or posedge i_Rst) begin
        if (i_Rst) begin
            state_reg   <= STATE_IDLE;
            counter_reg <= 0;
        end else begin
            state_reg   <= state_next;
            counter_reg <= counter_next;
        end
    end

    // FSM combinational logic
    always @(*) begin
        // Default values
        state_next   = state_reg;
        counter_next = counter_reg;
        
        case (state_reg)
            STATE_IDLE: begin
                if (i_Start) begin
                    state_next = STATE_INIT;
                end
            end
            
            STATE_INIT: begin
                // This state loads P=0 and counter=0
                state_next   = STATE_COMPUTE;
                counter_next = 0;
            end
            
            STATE_COMPUTE: begin
                // Check if this is the LAST iteration (e.g., 7 for k=8)
                if (counter_reg == (K_BITS - 1)) begin
                    // Go to DONE next cycle.
                    // The P_reg will latch the final P_next value on this edge.
                    state_next = STATE_DONE;
                end else begin
                    // Not done, just increment the counter
                    counter_next = counter_reg + 1;
                end
            end
            
            STATE_DONE: begin
                // Wait for Start to go low before returning to IDLE
                if (!i_Start) begin
                    state_next = STATE_IDLE;
                end
            end
        endcase
    end
    
    // Control signals
    assign o_Done = (state_reg == STATE_DONE);
    
    // Latch P_reg to o_P_final when done
    assign o_P_final = P_reg;


    //==================================================================
    // 2. COMBINATIONAL DATAPATH
    // (Implements Steps 3-7 of Algorithm 4)
    //==================================================================

    // --- STAGE 1: Fetch A_i, compute τ = P + γ ---
    
    // Select current bit A_i. 
    assign A_i_wire = (state_reg == STATE_COMPUTE) ? i_A[counter_reg] : 1'b0;

    // Mux 1 (k bits): Selects 0 or B (Step 3)
    Mux_2to1_k_plus_1_logical #(
        .K_BITS(K_BITS - 1)  // Set parameter to k-1 to get k-bit width
    ) inst_mux_gamma (
        .i_A    ( {K_BITS{1'b0}} ), // Input 0
        .i_B    ( i_B ),            // Input B
        .i_Sel  ( A_i_wire ),       // Select (A_i)
        .o_Y    ( gamma_wire )
    );

    // Adder 1 (k bits): P + γ (Step 4)
    cla_adder #(
        .K(K_BITS)
    ) inst_adder_k_bit (
        .A      ( P_reg ),      // Current P
        .B      ( gamma_wire ),
        .Cin    ( 1'b0 ),
        .Sum    ( adder1_sum ),
        .Cout   ( adder1_cout )
    );
    
    // Combine sum and carry to form (k+1)-bit τ
    assign tau_wire = {adder1_cout, adder1_sum};

    
    // --- STAGE 2: Compute τ ± m, Select Z ---
    
    // Extend modulus m to (k+1) bits
    assign m_extended = {1'b0, i_m};

    // Adder 2 (k+1 bits): τ + m
    ripple_carry_adder #(
        .K(K_BITS + 1)
    ) inst_adder_k_plus_1_bit (
        .i_A    ( tau_wire ),
        .i_B    ( m_extended ),
        .i_Cin  ( 1'b0 ),
        .o_Sum  ( add_m_result ),
        .o_Cout ( add_m_carry ) // C_out(τ+m)
    );

    // Subtractor (k+1 bits): τ - m
    Subtractor_k_plus_1_logical #(
        .K_BITS(K_BITS)
    ) inst_subtractor (
        .i_A    ( tau_wire ),
        .i_B    ( m_extended ),
        .o_Diff ( sub_m_result )
    );

    // Mux 2 (k+1 bits): Selects Z (Step 5)
    // If C_out(τ+m) is '0', Z = τ+m
    // If C_out(τ+m) is '1', Z = τ-m
    Mux_2to1_k_plus_1_logical #(
        .K_BITS(K_BITS)
    ) inst_mux_Z (
        .i_A    ( add_m_result ),
        .i_B    ( sub_m_result ),
        .i_Sel  ( add_m_carry ), // Select
        .o_Y    ( Z_wire )
    );

    
    // --- STAGE 3: Select α, Shift (>> 1), find P_next ---
    
    // LSB of τ
    assign tau_0_wire = tau_wire[0];
    
    // Mux 3 (k+1 bits): Selects α (Step 6)
    // If τ_0 is '0', α = τ
    // If τ_0 is '1', α = Z
    Mux_2to1_k_plus_1_logical #(
        .K_BITS(K_BITS)
    ) inst_mux_alpha (
        .i_A    ( tau_wire ), 
        .i_B    ( Z_wire ),        
        .i_Sel  ( tau_0_wire ),    
        .o_Y    ( alpha_wire )
    );
    
    // Shift right by 1 (P = α >> 1) (Step 7)
    // This is the value P will have in the *next* cycle
    assign P_next = alpha_wire[K_BITS : 1];

    
    //==================================================================
    // 3. P_reg REGISTER (Sequential Logic)
    //==================================================================
    
    always @(posedge i_Clk or posedge i_Rst) begin
        if (i_Rst) begin
            P_reg <= {K_BITS{1'b0}};
        end else begin
            // P_reg is updated based on FSM state
            case (state_reg)
                STATE_IDLE: begin
                    // Do nothing, hold P
                end
                
                STATE_INIT: begin
                    P_reg <= {K_BITS{1'b0}}; // Clear P to 0
                end
                
                STATE_COMPUTE: begin
                    P_reg <= P_next; // Load result of this iteration
                end
                
                STATE_DONE: begin
                    // Hold final P value
                end
            endcase
        end
    end
    
endmodule