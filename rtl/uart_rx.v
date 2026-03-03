module uart_rx #(parameter DATA_WIDTH = 8, STOP_BIT_INDEX = 16)(
    input i_clk,
    input i_reset,
    input i_rx,
    input i_sample_tick,
    output [DATA_WIDTH-1:0] o_data,
    output reg o_rx_done
);

// State Machine States
localparam IDLE       = 2'b00;
localparam START_BIT  = 2'b01;
localparam DATA_BITS  = 2'b10;
localparam STOP_BIT   = 2'b11;

// State Machine Registers
reg [1:0] state, next_state;
reg [3:0] tick_reg, tick_next;
reg [2:0] bit_index, bit_index_next;
reg [DATA_WIDTH-1:0] data_reg, data_next;

// Register to hold the sampled bit
always@(posedge i_clk or posedge i_reset) begin
    if(i_reset) begin
        state     <= IDLE;
        tick_reg  <= 0;
        bit_index <= 0;
        data_reg  <= 0;
        o_rx_done <= 0;
    end 

    else begin
        state     <= next_state;
        tick_reg  <= tick_next;
        bit_index <= bit_index_next;
        data_reg  <= data_next;
    end
end

// State machine logic
always@(*)begin

        next_state = state;
        o_rx_done  = 1'b0;
        tick_next  = tick_reg;
        bit_index_next = bit_index;
        data_next  = data_reg;

        case(state)
            IDLE: begin
                if(!i_rx)begin
                    next_state = START_BIT;
                    tick_next = 0;
                end
            end

            START_BIT: begin
                if (i_sample_tick) begin
                    if(tick_reg == DATA_WIDTH-1)begin
                        next_state = DATA_BITS;
                        tick_next = 0;
                        bit_index_next = 0;
                    end
                    else
                        tick_next = tick_reg + 1;
                end
            end

            DATA_BITS: begin
                if(i_sample_tick)begin
                    if(tick_reg == STOP_BIT_INDEX-1) begin
                        tick_next = 0;
                        data_next = {i_rx, data_reg[DATA_WIDTH-1:1]};
                        if(bit_index == DATA_WIDTH-1)
                            next_state = STOP_BIT;
                        else
                            bit_index_next = bit_index + 1;
                    end
                    else
                        tick_next = tick_reg + 1;
                end
            end

            STOP_BIT: begin
                if(i_sample_tick) begin
                    if(tick_reg ==STOP_BIT_INDEX-1) begin
                        next_state = IDLE;
                        o_rx_done = 1'b1;
                    end

                    else
                        tick_next = tick_reg + 1;
                end
            end
        endcase
end

assign o_data = data_reg;

endmodule