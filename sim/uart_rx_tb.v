`timescale 1ns / 1ps

module uart_rx_tb();

    // Parameters
    parameter DATA_WIDTH = 8;
    parameter STOP_BIT_INDEX = 16;
    parameter CLK_PERIOD = 10; // 100 MHz clock
    parameter BAUD_RATE = 9600;
    parameter SAMPLE_RATE = 16 * BAUD_RATE; // 153600 Hz
    parameter SAMPLE_TICK_PERIOD = 1000000000 / SAMPLE_RATE; // ~6510 ns
    parameter BIT_PERIOD = SAMPLE_TICK_PERIOD * 16; // ~104160 ns
    
    // Testbench signals
    reg tb_clk;
    reg tb_reset;
    reg tb_rx;
    reg tb_sample_tick;
    wire [DATA_WIDTH-1:0] tb_data;
    wire tb_rx_done;
    
    // Test control
    integer i, j;
    reg [DATA_WIDTH-1:0] test_byte;
    integer error_count;
    integer sample_tick_counter;
    
    // Instantiate the UART RX
    uart_rx #(
        .DATA_WIDTH(DATA_WIDTH),
        .STOP_BIT_INDEX(STOP_BIT_INDEX)
    ) uut (
        .i_clk(tb_clk),
        .i_reset(tb_reset),
        .i_rx(tb_rx),
        .i_sample_tick(tb_sample_tick),
        .o_data(tb_data),
        .o_rx_done(tb_rx_done)
    );

    initial begin
        $dumpfile("uart_rx_tb.vcd");
        $dumpvars(0, uart_rx_tb);
    end
    
    // Clock generation
    initial begin
        tb_clk = 0;
        forever #(CLK_PERIOD/2) tb_clk = ~tb_clk;
    end
    
    // Sample tick generation (16x baud rate)
    initial begin
        tb_sample_tick = 0;
        sample_tick_counter = 0;
        forever begin
            #(CLK_PERIOD);
            sample_tick_counter = sample_tick_counter + 1;
            if (sample_tick_counter >= 651) begin // Counter limit from baud_gen
                tb_sample_tick = 1;
                sample_tick_counter = 0;
            end else begin
                tb_sample_tick = 0;
            end
        end
    end
    
    // Task to send a UART byte
    task send_uart_byte;
        input [DATA_WIDTH-1:0] data;
        integer bit_idx;
        begin
            // Start bit (low)
            tb_rx = 0;
            repeat(16) @(posedge tb_sample_tick);
            
            // Data bits (LSB first)
            for (bit_idx = 0; bit_idx < DATA_WIDTH; bit_idx = bit_idx + 1) begin
                tb_rx = data[bit_idx];
                repeat(16) @(posedge tb_sample_tick);
            end
            
            // Stop bit (high)
            tb_rx = 1;
            repeat(16) @(posedge tb_sample_tick);
        end
    endtask
    
    // Test sequence
    initial begin
        // Initialize signals
        tb_reset = 1;
        tb_rx = 1; // UART idle state is high
        error_count = 0;
        
        // Wait for a few clock cycles
        #(CLK_PERIOD * 10);
        
        // Release reset
        tb_reset = 0;
        #(CLK_PERIOD * 10);
        
        $display("========================================");
        $display("UART RX Testbench Started");
        $display("========================================");
        
        // Test 1: Send single byte 0x55 (01010101)
        $display("\nTest 1: Sending byte 0x55");
        test_byte = 8'h55;
        send_uart_byte(test_byte);
        @(posedge tb_rx_done);
        #(CLK_PERIOD * 2);
        if (tb_data == test_byte) begin
            $display("PASS: Received 0x%h", tb_data);
        end else begin
            $display("FAIL: Expected 0x%h, Got 0x%h", test_byte, tb_data);
            error_count = error_count + 1;
        end
        
        // Wait between tests
        #(CLK_PERIOD * 100);
        
        // Test 2: Send byte 0xAA (10101010)
        $display("\nTest 2: Sending byte 0xAA");
        test_byte = 8'hAA;
        send_uart_byte(test_byte);
        @(posedge tb_rx_done);
        #(CLK_PERIOD * 2);
        if (tb_data == test_byte) begin
            $display("PASS: Received 0x%h", tb_data);
        end else begin
            $display("FAIL: Expected 0x%h, Got 0x%h", test_byte, tb_data);
            error_count = error_count + 1;
        end
        
        // Wait between tests
        #(CLK_PERIOD * 100);
        
        // Test 3: Send byte 0x00
        $display("\nTest 3: Sending byte 0x00");
        test_byte = 8'h00;
        send_uart_byte(test_byte);
        @(posedge tb_rx_done);
        #(CLK_PERIOD * 2);
        if (tb_data == test_byte) begin
            $display("PASS: Received 0x%h", tb_data);
        end else begin
            $display("FAIL: Expected 0x%h, Got 0x%h", test_byte, tb_data);
            error_count = error_count + 1;
        end
        
        // Wait between tests
        #(CLK_PERIOD * 100);
        
        // Test 4: Send byte 0xFF
        $display("\nTest 4: Sending byte 0xFF");
        test_byte = 8'hFF;
        send_uart_byte(test_byte);
        @(posedge tb_rx_done);
        #(CLK_PERIOD * 2);
        if (tb_data == test_byte) begin
            $display("PASS: Received 0x%h", tb_data);
        end else begin
            $display("FAIL: Expected 0x%h, Got 0x%h", test_byte, tb_data);
            error_count = error_count + 1;
        end
        
        // Wait between tests
        #(CLK_PERIOD * 100);
        
        // Test 5: Send multiple bytes back-to-back
        $display("\nTest 5: Sending multiple bytes (0x12, 0x34, 0x56)");
        test_byte = 8'h12;
        send_uart_byte(test_byte);
        @(posedge tb_rx_done);
        #(CLK_PERIOD * 2);
        if (tb_data == test_byte) begin
            $display("PASS: Received 0x%h", tb_data);
        end else begin
            $display("FAIL: Expected 0x%h, Got 0x%h", test_byte, tb_data);
            error_count = error_count + 1;
        end
        
        test_byte = 8'h34;
        send_uart_byte(test_byte);
        @(posedge tb_rx_done);
        #(CLK_PERIOD * 2);
        if (tb_data == test_byte) begin
            $display("PASS: Received 0x%h", tb_data);
        end else begin
            $display("FAIL: Expected 0x%h, Got 0x%h", test_byte, tb_data);
            error_count = error_count + 1;
        end
        
        test_byte = 8'h56;
        send_uart_byte(test_byte);
        @(posedge tb_rx_done);
        #(CLK_PERIOD * 2);
        if (tb_data == test_byte) begin
            $display("PASS: Received 0x%h", tb_data);
        end else begin
            $display("FAIL: Expected 0x%h, Got 0x%h", test_byte, tb_data);
            error_count = error_count + 1;
        end
        
        // Final results
        #(CLK_PERIOD * 100);
        $display("\n========================================");
        $display("UART RX Testbench Completed");
        $display("========================================");
        if (error_count == 0) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("TESTS FAILED: %0d errors", error_count);
        end
        $display("========================================\n");
        
        $finish;
    end
    
    // Monitor for debugging
    initial begin
        $monitor("Time=%0t | RX=%b | Sample_Tick=%b | State=%b | Data=%h | RX_Done=%b", 
                 $time, tb_rx, tb_sample_tick, uut.state, tb_data, tb_rx_done);
    end
    
    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * 1000000); // 10ms timeout
        $display("ERROR: Testbench timeout!");
        $finish;
    end

endmodule
