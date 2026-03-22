`timescale 1ns / 1ps

module uart_tx_tb;

    parameter DATA_WIDTH      = 8;
    parameter STOP_BIT_INDEX  = 16;
    parameter CLK_PERIOD      = 10;

    reg tb_clk;
    reg tb_reset;
    reg [DATA_WIDTH-1:0] tb_data;
    reg tb_sample_tick;
    reg tb_tx_start;
    wire tb_tx;
    wire tb_tx_done;

    integer i;
    integer error_count;

    uart_tx #(
        .DATA_WIDTH(DATA_WIDTH),
        .STOP_BIT_INDEX(STOP_BIT_INDEX)
    ) uut (
        .i_clk(tb_clk),
        .i_reset(tb_reset),
        .i_data(tb_data),
        .i_sample_tick(tb_sample_tick),
        .i_tx_start(tb_tx_start),
        .o_tx(tb_tx),
        .o_tx_done(tb_tx_done)
    );

    initial begin
        $dumpfile("uart_tx_tb.vcd");
        $dumpvars(0, uart_tx_tb);
    end

    initial begin
        tb_clk = 1'b0;
        forever #(CLK_PERIOD/2) tb_clk = ~tb_clk;
    end

    // drive one-cycle sample tick helper
    task pulse_sample_tick;
    begin
        tb_sample_tick = 1'b1;
        @(posedge tb_clk);
        tb_sample_tick = 1'b0;
        @(posedge tb_clk);
    end
    endtask

    // check that tx stays at expected level for one bit-time (16 sample ticks)
    task expect_line_for_one_bit;
        input expected;
        input [127:0] label;
        integer k;
    begin
        for (k = 0; k < STOP_BIT_INDEX; k = k + 1) begin
            if (tb_tx !== expected) begin
                $display("ERROR: %0s expected %0b, got %0b at sample %0d", label, expected, tb_tx, k);
                error_count = error_count + 1;
            end
            pulse_sample_tick();
        end
    end
    endtask

    initial begin
        tb_reset = 1'b1;
        tb_sample_tick = 1'b0;
        tb_tx_start = 1'b0;
        tb_data = 8'h00;
        error_count = 0;

        $display("=== UART TX TESTBENCH START ===");

        repeat (3) @(posedge tb_clk);
        tb_reset = 1'b0;
        @(posedge tb_clk);

        // idle should be high
        if (tb_tx !== 1'b1) begin
            $display("ERROR: TX idle should be high");
            error_count = error_count + 1;
        end

        // transmit 0xA5 -> LSB first: 1,0,1,0,0,1,0,1
        tb_data = 8'hA5;
        tb_tx_start = 1'b1;
        @(posedge tb_clk);
        tb_tx_start = 1'b0;

        // start bit
        expect_line_for_one_bit(1'b0, "START");

        // data bits
        for (i = 0; i < DATA_WIDTH; i = i + 1)
            expect_line_for_one_bit(tb_data[i], "DATA");

        // stop bit
        expect_line_for_one_bit(1'b1, "STOP");

        // allow done pulse to appear
        repeat (2) @(posedge tb_clk);
        if (tb_tx_done !== 1'b1)
            $display("INFO: o_tx_done was not observed high (check uart_tx done logic)");

        if (error_count == 0)
            $display("PASS: uart_tx serial waveform checks passed");
        else
            $display("FAIL: uart_tx had %0d waveform error(s)", error_count);

        $display("=== UART TX TESTBENCH END ===");
        $finish;
    end

endmodule
