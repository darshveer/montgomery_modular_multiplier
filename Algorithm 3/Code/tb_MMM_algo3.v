`timescale 1ns / 1ps

module tb_montgomery_alg3;

    localparam K_BITS     = 8;
    localparam CLK_PERIOD = 10;

    reg                  tb_clk;
    reg                  tb_rst;
    reg                  tb_start;
    reg  [K_BITS-1:0]    tb_A, tb_B, tb_m;
    wire [K_BITS-1:0]    tb_P_final;
    wire                 tb_done;

    integer test_case_count = 0;
    integer expected;   // for automatic calculation
    integer R, R_inv;   // Montgomery parameters

    // ---------------- DUT ----------------
    Montgomery_MMM_Alg3 #(.K_BITS(K_BITS)) dut (
        .i_Clk(tb_clk),
        .i_Rst(tb_rst),
        .i_Start(tb_start),
        .i_A(tb_A),
        .i_B(tb_B),
        .i_m(tb_m),
        .o_P_final(tb_P_final),
        .o_Done(tb_done)
    );

    // Clock generation
    always begin
        tb_clk = 1'b0; #(CLK_PERIOD/2);
        tb_clk = 1'b1; #(CLK_PERIOD/2);
    end

    // ----------------------------------------------------------
    // Function to compute modular inverse of R mod m (small m)
    // ----------------------------------------------------------
    function integer modinv;
        input integer a;
        input integer m;
        integer x;
    begin
        for (x = 0; x < m; x = x + 1)
            if (((a * x) % m) == 1)
                modinv = x;
    end
    endfunction

    // ----------------------------------------------------------
    // TASK: Perform one Montgomery multiplication test
    // ----------------------------------------------------------
    task run_test;
        input [K_BITS-1:0] A_in;
        input [K_BITS-1:0] B_in;
        input [K_BITS-1:0] m_in;
    begin
        test_case_count = test_case_count + 1;

        //------------------------------------------------------
        // Compute expected result automatically
        //------------------------------------------------------
        R = (1 << K_BITS) % m_in;     // R = 256 mod m
        R_inv = modinv(R, m_in);      // inverse of R mod m

        expected = (A_in * B_in * R_inv) % m_in;

        $display("------------------------------------------------------------");
        $display("TEST %0d: A=%0d, B=%0d, m=%0d  | Expected=%0d",
                 test_case_count, A_in, B_in, m_in, expected);

        //------------------------------------------------------
        // Apply inputs
        //------------------------------------------------------
        @(posedge tb_clk);
        tb_A = A_in;
        tb_B = B_in;
        tb_m = m_in;

        tb_start = 1;
        @(posedge tb_clk);
        tb_start = 0;

        //------------------------------------------------------
        // Wait until Done
        //------------------------------------------------------
        @(posedge tb_done);

        //------------------------------------------------------
        // PASS / FAIL check
        //------------------------------------------------------
        #1;
        if (tb_P_final == expected)
            $display("PASS: Output=%0d  (expected %0d)", tb_P_final, expected);
        else
            $display("FAIL: Output=%0d  (expected %0d)", tb_P_final, expected);

        //------------------------------------------------------
        // Wait for IDLE
        //------------------------------------------------------
        @(negedge tb_done);
        @(posedge tb_clk);
    end
    endtask

    // ----------------------------------------------------------
    // Initial stimulus
    // ----------------------------------------------------------
    initial begin
        tb_clk = 0;
        tb_rst = 1;
        tb_start = 0;

        #(CLK_PERIOD*2);
        tb_rst = 0;

        
        run_test(8'd5,   8'd7,   8'd19);
        run_test(8'd10,  8'd3,   8'd17);
        run_test(8'd20,  8'd6,   8'd23);
        run_test(8'd4,   8'd9,   8'd21);
        run_test(8'd15,  8'd11,  8'd27);
        run_test(8'd3,   8'd3,   8'd13);
        run_test(8'd7,   8'd8,   8'd29);

        $display("------------------------------------------------------------");
        $display("ALL TESTS COMPLETE");
        #(CLK_PERIOD*5);
        $finish;
    end

endmodule
