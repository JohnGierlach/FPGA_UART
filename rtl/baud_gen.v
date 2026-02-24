`timescale 1ns / 1ps

module baud_gen()(
    input i_clk,
    input i_reset,
    output reg o_sample_tick
    );


    // Baud Rate = 9600
    // i_clk = 100MHz
    // Sampling Rate = 16 * Baud Rate = 153600
    // Counter Limit = 100*10^6 / 153600 = 651



endmodule
