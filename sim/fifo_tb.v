`timescale 1ns / 1ps

module fifo_tb();

    // Parameters
    parameter DATA_WIDTH = 8;
    parameter ADDR_SPACE = 4;
    parameter FIFO_DEPTH = 2**ADDR_SPACE;
    parameter CLK_PERIOD = 10; // 100 MHz clock
    
    // Testbench signals
    reg tb_clk;
    reg tb_reset;
    reg tb_wr_en;
    reg tb_rd_en;
    reg [DATA_WIDTH-1:0] tb_data_in;
    wire [DATA_WIDTH-1:0] tb_data_out;
    wire tb_full;
    wire tb_empty;
    
    // Test control
    integer i;
    reg [DATA_WIDTH-1:0] expected_data;
    integer error_count;
    
    // Instantiate the FIFO
    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_SPACE(ADDR_SPACE)
    ) uut (
        .i_clk(tb_clk),
        .i_reset(tb_reset),
        .i_wr_en(tb_wr_en),
        .i_rd_en(tb_rd_en),
        .i_data(tb_data_in),
        .o_data(tb_data_out),
        .o_full(tb_full),
        .o_empty(tb_empty)
    );

    initial begin
        $dumpfile("fifo_tb.vcd");
        $dumpvars(0, fifo_tb);
    end
    
    // Clock generation
    initial begin
        tb_clk = 0;
        forever #(CLK_PERIOD/2) tb_clk = ~tb_clk;
    end
    
    // Test sequence
    initial begin
        // Initialize signals
        tb_reset = 1;
        tb_wr_en = 0;
        tb_rd_en = 0;
        tb_data_in = 0;
        error_count = 0;
        
        $display("=== FIFO Testbench Started ===");
        $display("FIFO Depth: %0d", FIFO_DEPTH);
        $display("Data Width: %0d", DATA_WIDTH);
        
        // Wait for a few clock cycles
        repeat(3) @(posedge tb_clk);
        
        // Test 1: Reset Test
        $display("\n[TEST 1] Reset Test");
        tb_reset = 1;
        @(posedge tb_clk);
        tb_reset = 0;
        @(posedge tb_clk);
        if (tb_empty !== 1'b1) begin
            $display("ERROR: FIFO should be empty after reset");
            error_count = error_count + 1;
        end else begin
            $display("PASS: FIFO empty after reset");
        end
        if (tb_full !== 1'b0) begin
            $display("ERROR: FIFO should not be full after reset");
            error_count = error_count + 1;
        end else begin
            $display("PASS: FIFO not full after reset");
        end
        
        // Test 2: Write Single Data
        $display("\n[TEST 2] Write Single Data");
        tb_data_in = 8'hAA;
        #1; // Ensure data is stable
        tb_wr_en = 1;
        @(posedge tb_clk);
        tb_wr_en = 0;
        @(posedge tb_clk);
        if (tb_empty !== 1'b0) begin
            $display("ERROR: FIFO should not be empty after write");
            error_count = error_count + 1;
        end else begin
            $display("PASS: FIFO contains data after write");
        end
        
        // Test 3: Read Single Data
        $display("\n[TEST 3] Read Single Data");
        @(posedge tb_clk); // Wait for stable state
        #1; // Small delay to ensure combinational output is stable
        if (tb_data_out !== 8'hAA) begin
            $display("ERROR: Read data mismatch. Expected: 0xAA, Got: 0x%h", tb_data_out);
            error_count = error_count + 1;
        end else begin
            $display("PASS: Correct data read (0xAA)");
        end
        tb_rd_en = 1;
        @(posedge tb_clk);
        tb_rd_en = 0;
        @(posedge tb_clk);
        if (tb_empty !== 1'b1) begin
            $display("ERROR: FIFO should be empty after reading last element");
            error_count = error_count + 1;
        end else begin
            $display("PASS: FIFO empty after reading last element");
        end
        
        // Test 4: Fill FIFO completely
        $display("\n[TEST 4] Fill FIFO to Full");
        // Reset FIFO to start with clean pointers
        tb_reset = 1;
        @(posedge tb_clk);
        tb_reset = 0;
        @(posedge tb_clk);
        
        tb_wr_en = 0;
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            tb_data_in = i;
            tb_wr_en = 1;
            @(posedge tb_clk);
        end
        tb_wr_en = 0;
        @(posedge tb_clk);
        if (tb_full !== 1'b1) begin
            $display("ERROR: FIFO should be full after %0d writes", FIFO_DEPTH);
            error_count = error_count + 1;
        end else begin
            $display("PASS: FIFO full flag asserted");
        end
        
        // Test 5: Attempt to write when full
        $display("\n[TEST 5] Write Overflow Protection");
        tb_wr_en = 1;
        tb_data_in = 8'hFF;
        @(posedge tb_clk);
        tb_wr_en = 0;
        @(posedge tb_clk);
        $display("INFO: Write attempted on full FIFO (should be ignored)");
        
        // Test 6: Read all data from FIFO
        $display("\n[TEST 6] Read All Data from FIFO");
        tb_rd_en = 0;
        @(posedge tb_clk); 
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            expected_data = i;
            // Data is available immediately (combinational)
            if (tb_data_out !== expected_data) begin
                $display("ERROR: Data mismatch at position %0d. Expected: 0x%h, Got: 0x%h", 
                         i, expected_data, tb_data_out);
                error_count = error_count + 1;
            end
            // Enable read to advance pointer on next clock
            tb_rd_en = 1;
            @(posedge tb_clk);
        end
        tb_rd_en = 0;
        @(posedge tb_clk);
        if (tb_empty !== 1'b1) begin
            $display("ERROR: FIFO should be empty after reading all elements");
            error_count = error_count + 1;
        end else begin
            $display("PASS: All data read correctly, FIFO empty");
        end
        
        // Test 7: Attempt to read when empty
        $display("\n[TEST 7] Read Underflow Protection");
        tb_rd_en = 1;
        @(posedge tb_clk);
        tb_rd_en = 0;
        @(posedge tb_clk);
        $display("INFO: Read attempted on empty FIFO (should be ignored)");
        
        // Test 8: Simultaneous Read and Write
        $display("\n[TEST 8] Simultaneous Read and Write");
        // First, write some data
        for (i = 0; i < 4; i = i + 1) begin
            tb_wr_en = 1;
            tb_data_in = 8'h10 + i;
            @(posedge tb_clk);
        end
        tb_wr_en = 0;
        @(posedge tb_clk);
        
        // Now simultaneous read/write
        for (i = 0; i < 8; i = i + 1) begin
            tb_wr_en = 1;
            tb_rd_en = 1;
            tb_data_in = 8'h20 + i;
            @(posedge tb_clk);
        end
        tb_wr_en = 0;
        tb_rd_en = 0;
        @(posedge tb_clk);
        $display("PASS: Simultaneous read/write operations completed");
        
        // Test 9: Sequential Write and Read Pattern
        $display("\n[TEST 9] Sequential Write/Read Pattern");
        for (i = 0; i < 20; i = i + 1) begin
            // Write 3 elements
            tb_wr_en = 1;
            tb_data_in = 8'h30 + i;
            @(posedge tb_clk);
            tb_data_in = 8'h40 + i;
            @(posedge tb_clk);
            tb_data_in = 8'h50 + i;
            @(posedge tb_clk);
            tb_wr_en = 0;
            
            // Read 3 elements
            tb_rd_en = 1;
            @(posedge tb_clk);
            @(posedge tb_clk);
            @(posedge tb_clk);
            tb_rd_en = 0;
            @(posedge tb_clk);
        end
        $display("PASS: Sequential write/read pattern completed");
        
        // Test 10: Verify empty flag at end
        $display("\n[TEST 10] Final Empty Check");
        // Read any remaining data
        while (!tb_empty) begin
            tb_rd_en = 1;
            @(posedge tb_clk);
        end
        tb_rd_en = 0;
        @(posedge tb_clk);
        
        if (tb_empty !== 1'b1) begin
            $display("ERROR: FIFO should be empty");
            error_count = error_count + 1;
        end else begin
            $display("PASS: FIFO empty at end of test");
        end
        
        // Final results
        $display("\n=================================");
        if (error_count == 0) begin
            $display("*** ALL TESTS PASSED ***");
        end else begin
            $display("*** TESTS FAILED: %0d errors ***", error_count);
        end
        $display("=================================\n");
        
        // End simulation
        #100;
        $finish;
    end
    
    // Monitor for debugging (optional - comment out if too verbose)
    // initial begin
    //     $monitor("Time=%0t | Reset=%b | WrEn=%b | RdEn=%b | DataIn=0x%h | DataOut=0x%h | Full=%b | Empty=%b",
    //              $time, tb_reset, tb_wr_en, tb_rd_en, tb_data_in, tb_data_out, tb_full, tb_empty);
    // end
    
endmodule
