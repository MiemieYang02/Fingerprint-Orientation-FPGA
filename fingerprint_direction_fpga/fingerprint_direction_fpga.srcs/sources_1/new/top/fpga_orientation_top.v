`timescale 1ns/1ps

module fpga_orientation_top (
    input  wire       clk,
    input  wire       rst_n,
    output wire       block_valid,
    output wire       block_active,
    output wire [5:0] block_x,
    output wire [5:0] block_y,
    output wire [3:0] block_dir,
    output wire       frame_done
);
    wire src_valid;
    wire [7:0] src_gray;
    wire [7:0] src_x;
    wire [7:0] src_y;
    wire src_frame_start;
    wire src_line_start;
    wire src_frame_done;

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

    // Demo wrapper: internal test image source feeds the real stream pipeline.
    fpga_orientation_pipeline u_fpga_orientation_pipeline (
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
        .block_active(block_active),
        .block_x(block_x),
        .block_y(block_y),
        .block_dir(block_dir),
        .frame_done(frame_done)
    );
endmodule
