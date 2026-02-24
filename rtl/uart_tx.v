module uart_tx #(parameter DATA_WIDTH = 8, STOP_BIT_INDEX = 16)(
    input i_clk,
    input i_reset,
    input [DATA_WIDTH-1:0] i_data,
    input sample_tick,
    input i_tx_start,
    output reg o_tx,
    output reg o_tx_done
    );

    // State Machine States
    localparam IDLE       = 2'b00;
    localparam START_BIT  = 2'b01;  
    localparam DATA_BITS  = 2'b10;
    localparam STOP_BIT   = 2'b11;


endmodule
