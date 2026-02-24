`timescale 1ns / 1ps

module fifo 
    #(parameter DATA_WIDTH = 8, 
                ADDR_SPACE = 4
    )
    (
    input i_clk,
    input i_reset,
    input i_wr_en,
    input i_rd_en,
    input [DATA_WIDTH-1:0] i_data,
    output [DATA_WIDTH-1:0] o_data,
    output o_full,
    output o_empty
    );


    // FIFO States
    localparam IDLE        = 2'b00,
               READ        = 2'b01,
               WRITE       = 2'b10,
               READ_WRITE  = 2'b11;

    // FIFO Memory
    reg [DATA_WIDTH-1:0] fifo_mem [2**ADDR_SPACE-1:0];

    // Write and Read Pointers
    reg [ADDR_SPACE-1:0] wr_ptr, wr_ptr_buf, next_wr_ptr;
    reg [ADDR_SPACE-1:0] rd_ptr, rd_ptr_buf, next_rd_ptr;

    // Full and Empty Flags
    reg fifo_full, full_buf, fifo_empty, empty_buf;

    // Write enabled flag
    wire wr_en;

    // Memory write logic - uses current pointer value
    always@(posedge i_clk)begin
        if(wr_en) begin
            fifo_mem[wr_ptr] <= i_data;
            $display("Time=%0t: Writing 0x%h to fifo_mem[%0d]", $time, i_data, wr_ptr);
        end
    end

    // Pointer and flag updates
    always@(posedge i_clk or posedge i_reset)begin
        if(i_reset)begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            fifo_full <= 0;
            fifo_empty <= 1;
        end
        else begin
            wr_ptr <= wr_ptr_buf;
            rd_ptr <= rd_ptr_buf;
            fifo_full <= full_buf;
            fifo_empty <= empty_buf;
        end
    end


    // Pointer incrementers
    always@(*)begin
        next_wr_ptr = wr_ptr + 1;
        next_rd_ptr = rd_ptr + 1;
        wr_ptr_buf = wr_ptr;
        rd_ptr_buf = rd_ptr;
        full_buf = fifo_full;
        empty_buf = fifo_empty;
    end

    // FIFO Read and Write state logic
    always@(*)begin
        case({i_wr_en, i_rd_en})
            IDLE: begin
                wr_ptr_buf = wr_ptr;
                rd_ptr_buf = rd_ptr;
                full_buf = fifo_full;
                empty_buf = fifo_empty;
            end

            // If there is a read signal, check to see if the FIFO contains data and update the next rd_ptr
            // If next_rd_ptr == wr_ptr, the FIFO is empty
            READ: begin
                if(!fifo_empty)begin
                    rd_ptr_buf = next_rd_ptr;
                    full_buf = 1'b0;
                    if(next_rd_ptr == wr_ptr)
                        empty_buf = 1'b1;
                end
            end

            // If there is a write signal, check to see if the FIFO has a writable address and update the next wr_ptr
            // If next_wr_ptr == rd_ptr, the FIFO is full 
            WRITE: begin
                if(!fifo_full)begin
                    wr_ptr_buf = next_wr_ptr;
                    empty_buf = 1'b0;
                    if(next_wr_ptr == rd_ptr)
                        full_buf = 1'b1;
                end
            end

            // READ and WRITE at the same time.
            READ_WRITE: begin
                wr_ptr_buf = next_wr_ptr;
                rd_ptr_buf = next_rd_ptr;
            end
        endcase
    end

    assign wr_en = i_wr_en & !fifo_full;
    assign o_data = fifo_mem[rd_ptr];
    assign o_full = fifo_full;
    assign o_empty = fifo_empty;

endmodule
