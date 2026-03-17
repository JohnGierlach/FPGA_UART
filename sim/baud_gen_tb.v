`timescale 1ns / 1ps

module baud_gen_tb;

    parameter BAUD_BITS  = 4;
    parameter BAUD_LIMIT = 8;
    parameter CLK_PERIOD = 10;

    reg tb_clk;
    reg tb_reset;
    wire tb_sample_tick;

    integer cycle_count;
    integer tick_count;
    integer error_count;

    baud_gen #(
        .BAUD_BITS(BAUD_BITS),
        .BAUD_LIMIT(BAUD_LIMIT)
    ) uut (
        .i_clk(tb_clk),
        .i_reset(tb_reset),
        .o_sample_tick(tb_sample_tick)
    );

    initial begin
        tb_clk = 1'b0;
        forever #(CLK_PERIOD/2) tb_clk = ~tb_clk;
    end

    initial begin
        tb_reset = 1'b1;
        cycle_count = 0;
        tick_count = 0;
        error_count = 0;

        $display("=== BAUD GEN TESTBENCH START ===");

        repeat (3) @(posedge tb_clk);
        tb_reset = 1'b0;

        // Count 5 tick events and make sure spacing is BAUD_LIMIT cycles.
        while (tick_count < 5) begin
            @(posedge tb_clk);
            cycle_count = cycle_count + 1;

            if (tb_sample_tick) begin
                tick_count = tick_count + 1;
                if ((cycle_count % BAUD_LIMIT) != 0) begin
                    $display("ERROR: Tick asserted at unexpected cycle %0d", cycle_count);
                    error_count = error_count + 1;
                end
            end
        end

        // Tick must be single-cycle pulse.
        @(posedge tb_clk);
        if (tb_sample_tick !== 1'b0) begin
            $display("ERROR: Tick pulse wider than one cycle");
            error_count = error_count + 1;
        end

        if (error_count == 0)
            $display("PASS: baud_gen produced correct periodic single-cycle ticks");
        else
            $display("FAIL: baud_gen had %0d error(s)", error_count);

        $display("=== BAUD GEN TESTBENCH END ===");
        $finish;
    end

endmodule
