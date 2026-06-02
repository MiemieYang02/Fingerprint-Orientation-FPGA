`timescale 1ns/1ps

// Stream-oriented fingerprint direction pipeline.
// A real image ingress block should convert camera, DDR3, UART, SD, or host data
// into this synchronous grayscale pixel stream before entering Sobel/CORDIC logic.
module fpga_orientation_pipeline (
    input  wire       clk,
    input  wire       rst_n,

    // One grayscale pixel per valid cycle. Coordinates must match pixel_gray.
    input  wire       pixel_valid,
    input  wire [7:0] pixel_gray,
    input  wire [7:0] pixel_x,
    input  wire [7:0] pixel_y,
    input  wire       pixel_frame_start,
    input  wire       pixel_line_start,
    input  wire       pixel_frame_done,

    // One result per 16x16 block after Sobel, angle quantization, and statistics.
    output wire       block_valid,
    output wire [3:0] block_x,
    output wire [3:0] block_y,
    output wire [2:0] block_dir,
    output wire       frame_done
);
    wire win_valid;
    wire [7:0] win_x;
    wire [7:0] win_y;
    wire [7:0] p00;
    wire [7:0] p01;
    wire [7:0] p02;
    wire [7:0] p10;
    wire [7:0] p12;
    wire [7:0] p20;
    wire [7:0] p21;
    wire [7:0] p22;

    wire sobel_valid;
    wire [7:0] sobel_x;
    wire [7:0] sobel_y;
    wire signed [11:0] gx;
    wire signed [11:0] gy;

    wire angle_valid;
    wire [7:0] angle_x;
    wire [7:0] angle_y;
    wire [7:0] angle_code;

    wire dir_valid;
    wire [7:0] dir_x;
    wire [7:0] dir_y;
    wire [2:0] dir_bin;

    reg [63:0] done_pipe;

    wire unused_frame_start = pixel_frame_start;
    wire unused_line_start = pixel_line_start;

    pixel_window_3x3 u_pixel_window_3x3 (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(pixel_valid),
        .in_gray(pixel_gray),
        .in_x(pixel_x),
        .in_y(pixel_y),
        .out_valid(win_valid),
        .out_x(win_x),
        .out_y(win_y),
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22)
    );

    sobel_core u_sobel_core (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(win_valid),
        .in_x(win_x),
        .in_y(win_y),
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),
        .out_valid(sobel_valid),
        .out_x(sobel_x),
        .out_y(sobel_y),
        .gx(gx),
        .gy(gy)
    );

    cordic_angle_ip_wrapper u_cordic_angle_ip_wrapper (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(sobel_valid),
        .in_x(sobel_x),
        .in_y(sobel_y),
        .gx(gx),
        .gy(gy),
        .out_valid(angle_valid),
        .out_x(angle_x),
        .out_y(angle_y),
        .angle_code(angle_code)
    );

    direction_quantizer u_direction_quantizer (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(angle_valid),
        .in_x(angle_x),
        .in_y(angle_y),
        .angle_code(angle_code),
        .out_valid(dir_valid),
        .out_x(dir_x),
        .out_y(dir_y),
        .dir_bin(dir_bin)
    );

    block_direction_stat u_block_direction_stat (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(dir_valid),
        .in_x(dir_x),
        .in_y(dir_y),
        .dir_bin(dir_bin),
        .block_valid(block_valid),
        .block_x(block_x),
        .block_y(block_y),
        .block_dir(block_dir)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done_pipe <= 64'd0;
        end else begin
            done_pipe <= {done_pipe[62:0], pixel_frame_done};
        end
    end

    assign frame_done = done_pipe[32];

endmodule
