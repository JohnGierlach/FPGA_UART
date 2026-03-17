`timescale 1ns / 1ps

module uart_top_tb;

    parameter DATA_WIDTH      = 8;
    parameter STOP_BIT_INDEX  = 16;
    parameter BAUD_BITS       = 4;
    parameter BAUD_LIMIT      = 8;
    parameter FIFO_DEPTH      = 2;
    parameter CLK_PERIOD      = 10;

    reg tb_clk;
    reg tb_reset;
    reg tb_rd_uart;
    reg tb_wr_uart;
    reg [DATA_WIDTH-1:0] tb_wr_data;
    wire tb_rx_full;
    wire tb_rx_empty;
    wire tb_o_tx;
    wire [DATA_WIDTH-1:0] tb_rd_data;

    // loop TX back to RX
    wire tb_rx_line;
    assign tb_rx_line = tb_o_tx;

    integer error_count;
    integer timeout;

    uart_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .STOP_BIT_INDEX(STOP_BIT_INDEX),
        .BAUD_BITS(BAUD_BITS),
        .BAUD_LIMIT(BAUD_LIMIT),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) uut (
        .i_clk(tb_clk),
        .i_reset(tb_reset),
        .i_rd_uart(tb_rd_uart),
        .i_wr_uart(tb_wr_uart),
        .i_rx(tb_rx_line),
        .i_wr_data(tb_wr_data),
        .o_rx_full(tb_rx_full),
        .o_rx_empty(tb_rx_empty),
        .o_tx(tb_o_tx),
        .o_rd_data(tb_rd_data)
    );

    initial begin
        tb_clk = 1'b0;
        forever #(CLK_PERIOD/2) tb_clk = ~tb_clk;
    end

    initial begin
        tb_reset   = 1'b1;
        tb_rd_uart = 1'b0;
        tb_wr_uart = 1'b0;
        tb_wr_data = 8'h00;
        error_count = 0;

        $display("=== UART TOP TESTBENCH START ===");

        repeat (5) @(posedge tb_clk);
        tb_reset = 1'b0;
        repeat (3) @(posedge tb_clk);

        // Write one byte into TX path
        tb_wr_data = 8'h3C;
        tb_wr_uart = 1'b1;
        @(posedge tb_clk);
        tb_wr_uart = 1'b0;

        // Wait for looped RX FIFO to become non-empty
        timeout = 0;
        while (tb_rx_empty && timeout < 20000) begin
            @(posedge tb_clk);
            timeout = timeout + 1;
        end

        if (tb_rx_empty) begin
            $display("ERROR: Timed out waiting for RX FIFO data");
            error_count = error_count + 1;
        end else begin
            tb_rd_uart = 1'b1;
            @(posedge tb_clk);
            tb_rd_uart = 1'b0;
            @(posedge tb_clk);

            if (tb_rd_data !== 8'h3C) begin
                $display("ERROR: Loopback data mismatch. Expected 0x3C got 0x%h", tb_rd_data);
                error_count = error_count + 1;
            end else begin
                $display("PASS: Loopback transferred 0x3C correctly");
            end
        end

        if (error_count == 0)
            $display("PASS: uart_top basic loopback test passed");
        else
            $display("FAIL: uart_top had %0d error(s)", error_count);

        $display("=== UART TOP TESTBENCH END ===");
        $finish;
    end

endmodule
