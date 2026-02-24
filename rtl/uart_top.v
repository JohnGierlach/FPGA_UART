`timescale 1ns / 1ps

module uart_top(
    input i_clk,
    input i_reset
    );
    
    
    uart_tx TX();
    uart_rx RX();
    baud_gen BAUD_GEN();
    fifo RX_FIFO();
    fifo TX_FIFO();
    
    
endmodule
