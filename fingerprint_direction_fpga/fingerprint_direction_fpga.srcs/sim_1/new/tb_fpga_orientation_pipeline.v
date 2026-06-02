`timescale 1ns/1ps

module tb_fpga_orientation_pipeline;
    reg clk;
    reg rst_n;

    wire src_valid;
    wire [7:0] src_gray;
    wire [7:0] src_x;
    wire [7:0] src_y;
    wire src_frame_start;
    wire src_line_start;
    wire src_frame_done;

    wire block_valid;
    wire [3:0] block_x;
    wire [3:0] block_y;
    wire [2:0] block_dir;
    wire frame_done;

    integer block_count;
    integer error_count;

    image_source_sim u_image_source_sim (
        .clk(clk),
        .rst_n(rst_n),
        .out_valid(src_valid),
        .out_gray(src_gray),
        .out_x(src_x),
        .out_y(src_y),
        .out_frame_start(src_frame_start),
        .out_line_start(src_line_start),
        .frame_done(src_frame_done)
    );

    fpga_orientation_pipeline dut (
        .clk(clk),
        .rst_n(rst_n),
        .pixel_valid(src_valid),
        .pixel_gray(src_gray),
        .pixel_x(src_x),
        .pixel_y(src_y),
        .pixel_frame_start(src_frame_start),
        .pixel_line_start(src_line_start),
        .pixel_frame_done(src_frame_done),
        .block_valid(block_valid),
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
        error_count = 0;
        repeat (8) @(posedge clk);
        rst_n = 1'b1;
    end

    always @(posedge clk) begin
        if (rst_n && block_valid) begin
            block_count = block_count + 1;
            if (block_dir !== 3'd4) begin
                $display("PIPELINE_DIRECTION_MISMATCH block_x=%0d block_y=%0d dir=%0d", block_x, block_y, block_dir);
                error_count = error_count + 1;
            end
        end

        if (rst_n && frame_done) begin
            if (block_count != 256) begin
                $display("PIPELINE_BLOCK_COUNT_MISMATCH count=%0d expected=256", block_count);
                $finish(1);
            end
            if (error_count != 0) begin
                $display("PIPELINE_TEST_FAIL errors=%0d", error_count);
                $finish(1);
            end
            $display("PIPELINE_TEST_PASS blocks=%0d", block_count);
            $finish;
        end
    end

    initial begin
        #2000000;
        $display("PIPELINE_TEST_TIMEOUT blocks=%0d errors=%0d", block_count, error_count);
        $finish(1);
    end
endmodule
