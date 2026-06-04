`timescale 1ns/1ps

module tb_fpga_orientation_static_top;
    localparam MEM_FILE = "fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/image/fingerprint_static_256.mem";

    reg clk;
    reg rst_n;

    wire block_valid;
    wire block_active;
    wire [5:0] block_x;
    wire [5:0] block_y;
    wire [3:0] block_dir;
    wire frame_done;

    integer block_count;
    integer nonzero_count;
    integer active_count;
    reg [4095:0] seen_block;
    integer block_index;

    fpga_orientation_static_top #(
        .MEM_FILE(MEM_FILE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .block_valid(block_valid),
        .block_active(block_active),
        .block_x(block_x),
        .block_y(block_y),
        .block_dir(block_dir),
        .frame_done(frame_done)
    );

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    initial begin
        rst_n = 1'b0;
        block_count = 0;
        nonzero_count = 0;
        active_count = 0;
        seen_block = 4096'd0;
        repeat (8) @(posedge clk);
        rst_n = 1'b1;
    end

    always @(posedge clk) begin
        #1;
        if (rst_n && block_valid) begin
            block_index = {block_y, block_x};
            if (seen_block[block_index]) begin
                $display("STATIC_TOP_DUPLICATE_BLOCK x=%0d y=%0d", block_x, block_y);
                $finish(1);
            end
            seen_block[block_index] = 1'b1;
            block_count = block_count + 1;
            if (block_dir != 4'd0) begin
                nonzero_count = nonzero_count + 1;
            end
            if (block_active) begin
                active_count = active_count + 1;
            end
        end

        if (rst_n && frame_done) begin
            if (block_count != 3844) begin
                $display("STATIC_TOP_BLOCK_COUNT_MISMATCH count=%0d expected=3844", block_count);
                $finish(1);
            end
            if (nonzero_count == 0) begin
                $display("STATIC_TOP_NO_DIRECTION_VARIATION");
                $finish(1);
            end
            if (active_count == 0) begin
                $display("STATIC_TOP_NO_ACTIVE_BLOCKS");
                $finish(1);
            end
            $display("STATIC_TOP_TEST_PASS blocks=%0d nonzero=%0d active=%0d",
                     block_count, nonzero_count, active_count);
            $finish;
        end
    end

    initial begin
        #2000000;
        $display("STATIC_TOP_TEST_TIMEOUT blocks=%0d nonzero=%0d active=%0d",
                 block_count, nonzero_count, active_count);
        $finish(1);
    end
endmodule
