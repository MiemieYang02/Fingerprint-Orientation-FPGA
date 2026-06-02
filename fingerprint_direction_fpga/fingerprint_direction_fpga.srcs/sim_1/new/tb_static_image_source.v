`timescale 1ns/1ps

module tb_static_image_source;
    localparam IMAGE_W = 256;
    localparam IMAGE_H = 256;
    localparam TOTAL_PIXELS = IMAGE_W * IMAGE_H;
    localparam MEM_FILE = "fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/image/fingerprint_static_256.mem";

    reg clk;
    reg rst_n;

    wire out_valid;
    wire [7:0] out_gray;
    wire [7:0] out_x;
    wire [7:0] out_y;
    wire out_frame_start;
    wire out_line_start;
    wire frame_done;

    reg [7:0] expected_mem [0:TOTAL_PIXELS-1];
    integer pixel_count;
    integer line_start_count;

    image_static_mem_source #(
        .IMAGE_W(IMAGE_W),
        .IMAGE_H(IMAGE_H),
        .MEM_FILE(MEM_FILE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .out_valid(out_valid),
        .out_gray(out_gray),
        .out_x(out_x),
        .out_y(out_y),
        .out_frame_start(out_frame_start),
        .out_line_start(out_line_start),
        .frame_done(frame_done)
    );

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    initial begin
        $readmemh(MEM_FILE, expected_mem);
        rst_n = 1'b0;
        pixel_count = 0;
        line_start_count = 0;
        repeat (8) @(posedge clk);
        rst_n = 1'b1;
    end

    always @(posedge clk) begin
        #1;
        if (rst_n && out_valid) begin
            if (out_x !== (pixel_count % IMAGE_W)) begin
                $display("STATIC_SOURCE_X_MISMATCH index=%0d x=%0d", pixel_count, out_x);
                $finish(1);
            end
            if (out_y !== (pixel_count / IMAGE_W)) begin
                $display("STATIC_SOURCE_Y_MISMATCH index=%0d y=%0d", pixel_count, out_y);
                $finish(1);
            end
            if (out_gray !== expected_mem[pixel_count]) begin
                $display("STATIC_SOURCE_GRAY_MISMATCH index=%0d gray=%0h expected=%0h",
                         pixel_count, out_gray, expected_mem[pixel_count]);
                $finish(1);
            end
            if (out_frame_start !== (pixel_count == 0)) begin
                $display("STATIC_SOURCE_FRAME_START_MISMATCH index=%0d", pixel_count);
                $finish(1);
            end
            if (out_line_start) begin
                line_start_count = line_start_count + 1;
            end
            if (out_line_start !== ((pixel_count % IMAGE_W) == 0)) begin
                $display("STATIC_SOURCE_LINE_START_MISMATCH index=%0d", pixel_count);
                $finish(1);
            end
            pixel_count = pixel_count + 1;
        end

        if (rst_n && frame_done) begin
            if (pixel_count != TOTAL_PIXELS) begin
                $display("STATIC_SOURCE_PIXEL_COUNT_MISMATCH count=%0d expected=%0d",
                         pixel_count, TOTAL_PIXELS);
                $finish(1);
            end
            if (line_start_count != IMAGE_H) begin
                $display("STATIC_SOURCE_LINE_COUNT_MISMATCH count=%0d expected=%0d",
                         line_start_count, IMAGE_H);
                $finish(1);
            end
            $display("STATIC_SOURCE_TEST_PASS pixels=%0d lines=%0d", pixel_count, line_start_count);
            $finish;
        end
    end

    initial begin
        #2000000;
        $display("STATIC_SOURCE_TEST_TIMEOUT pixels=%0d lines=%0d", pixel_count, line_start_count);
        $finish(1);
    end
endmodule
