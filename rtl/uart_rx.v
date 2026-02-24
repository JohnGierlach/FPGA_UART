module uart_rx #(parameter DATA_WIDTH = 8)(
    input i_clk,
    input i_reset,
    input i_rx,
    input i_sample_tick,
    output reg [DATA_WIDTH-1:0] o_data,
    output reg o_rx_done
);

// State Machine States
localparam IDLE       = 2'b00;
localparam START_BIT  = 2'b01;
localparam DATA_BITS  = 2'b10;
localparam STOP_BIT   = 2'b11;

endmodule