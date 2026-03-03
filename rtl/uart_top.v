`timescale 1ns / 1ps

module uart_top#(parameter DATA_WIDTH     = 8, 
                           STOP_BIT_INDEX = 16,
                           BAUD_BITS   = 10,
                           BAUD_LIMIT  = 651,
                           FIFO_DEPTH     = 2)
    (
    input i_clk,
    input i_reset,
    input i_rd_uart,
    input i_wr_uart,
    input i_rx,
    input [DATA_WIDTH-1:0] i_wr_data,
    output o_rx_full,
    output o_rx_empty,
    output o_tx,
    output [DATA_WIDTH-1:0] o_rd_data
    );
    
    
    wire tick;
    wire rx_done_tick;
    wire tx_done_tick;
    wire tx_empty;
    wire tx_fifo_not_emtpy;
    wire [DATA_WIDTH-1:0] tx_fifo_out;
    wire [DATA_WIDTH-1:0] rx_data_out;

    uart_tx #(
        .DATA_WIDTH(DATA_WIDTH),
        .STOP_BIT_INDEX(STOP_BIT_INDEX)
    )TX(
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_data(tx_fifo_out),
        .i_sample_tick(tick),
        .i_tx_start(tx_fifo_not_emtpy),
        .o_tx(o_tx)
    );

    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_SPACE(FIFO_DEPTH)
    )TX_FIFO(
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_wr_en(i_wr_uart),
        .i_rd_en(tx_done_tick),
        .i_data(i_wr_data),
        .o_data(tx_fifo_out),
        .o_empty(tx_empty),
        .o_full()
    );

    uart_rx #(
        .DATA_WIDTH(DATA_WIDTH),
        .STOP_BIT_INDEX(STOP_BIT_INDEX)
    )RX(
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_rx(i_rx),
        .i_sample_tick(tick),
        .o_data(rx_data_out),
        .o_rx_done(rx_done_tick)
    );
    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_SPACE(FIFO_DEPTH)
    )RX_FIFO(
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_wr_en(rx_done_tick),
        .i_rd_en(i_rd_uart),
        .i_data(rx_data_out),
        .o_data(o_rd_data),
        .o_empty(o_rx_empty),
        .o_full(o_rx_full)
    );

    baud_gen #(
        .COUNTER_BITS(COUNTER_BITS),
        .BAUD_RATE(BAUD_RATE)
    )BAUD_GEN(
        .i_clk(i_clk),
        .i_reset(i_reset),
        .o_sample_tick(tick)
    );
    
endmodule
