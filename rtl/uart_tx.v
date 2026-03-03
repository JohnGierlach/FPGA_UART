module uart_tx #(parameter DATA_WIDTH = 8, STOP_BIT_INDEX = 16)(
    input i_clk,
    input i_reset,
    input [DATA_WIDTH-1:0] i_data,
    input i_sample_tick,
    input i_tx_start,
    output reg o_tx,
    output reg o_tx_done
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
    reg tx_reg, tx_next;


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


    always@(*)begin
        next_state = state;
        o_tx_done  = 1'b0;
        tick_next  = tick_reg;
        nbits_next = nbits_reg;
        data_next  = i_data; 

        case(state)
            IDLE: begin
                tx_next = 1'b1;
                if(i_tx_start) begin
                    next_state = START_BIT;
                    tick_next = 0;
                    data_next = data_in;
                end
            end

            START_BIT: begin
                if(sample_tick) begin
                    if(tick_reg == STOP_BIT_INDEX-1)begin
                        next_state = DATA_BITS;
                        tick_next = 0;
                        nbits_next = 0;
                    end

                    else
                        tick_next = tick_reg + 1;
                end
            end

            DATA_BITS: begin
                tx_next = data_reg[0];
                if(sample_tick)begin
                    if(tick_reg == STOP_BIT_INDEX-1)begin
                        tick_next = 0;
                        data_next = data_reg >> 1;
                        if(nbits_reg == (DATA_BITS-1))
                            next_state = STOP_BIT;
                        else
                            tick_next = tick_reg + 1;
                    end
                end
            end

            STOP_BIT: begin
                tx_next = 1'b1;
                if(sample_tick)begin
                    if(tick_reg == (SB_TICK-1))begin
                        next_state = IDLE;
                        o_tx_done = 1'b1;
                    end

                    else
                        tick_next = tick_reg + 1;
                end
            end
        endcase
    end

    assign o_tx = tx_reg;

endmodule
