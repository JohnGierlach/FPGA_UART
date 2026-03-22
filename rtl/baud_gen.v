`timescale 1ns / 1ps

module baud_gen#(parameter BAUD_BITS = 10, parameter BAUD_LIMIT = 651)(
    input i_clk,
    input i_reset,
    output reg o_sample_tick
    );


    reg [BAUD_BITS-1:0] counter;
    wire [BAUD_BITS-1:0] counter_buf;


    // Baud Rate = 9600
    // i_clk = 100MHz
    // Sampling Rate = 16 * Baud Rate = 153600
    // Counter Limit = 100*10^6 / 153600 = 651

    always@(posedge i_clk or posedge i_reset)begin
        if(i_reset)begin
            counter <= 0;
            o_sample_tick <= 0;
        end
        else begin
            counter <= counter_buf;
            o_sample_tick <= (counter == BAUD_LIMIT-1) ? 1 : 0;
        end
    end

    assign counter_buf = (counter == BAUD_LIMIT-1) ? 0 : counter + 1;

endmodule
