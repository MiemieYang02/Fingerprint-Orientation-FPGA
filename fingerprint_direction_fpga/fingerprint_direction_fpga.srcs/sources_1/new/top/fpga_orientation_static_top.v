`timescale 1ns/1ps

// Static-image validation wrapper.
// This top feeds a ROM-initialized fingerprint image into the same stream
// pipeline that later accepts camera, DDR3, or host-transferred pixels.
module fpga_orientation_static_top #(
    parameter MEM_FILE = "fingerprint_static_256.mem"
) (
    input  wire       clk,
    input  wire       rst_n,
    output wire       block_valid,
    output wire [3:0] block_x,
    output wire [3:0] block_y,
    output wire [2:0] block_dir,
    output wire       frame_done
);
    wire src_valid;
    wire [7:0] src_gray;
    wire [7:0] src_x;
    wire [7:0] src_y;
    wire src_frame_start;
    wire src_line_start;
    wire src_frame_done;

    image_static_mem_source #(
        .MEM_FILE(MEM_FILE)
    ) u_static_source (
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
        .block_x(block_x),
        .block_y(block_y),
        .block_dir(block_dir),
        .frame_done(frame_done)
    );
endmodule
