`timescale 1ns/1ps

// Stream-oriented fingerprint direction pipeline.
// A real image ingress block should convert camera, DDR3, UART, SD, or host data
// into this synchronous grayscale pixel stream before entering Sobel/CORDIC logic.
module fpga_orientation_pipeline #(
    parameter GRADIENT_THRESHOLD = 8
) (
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

    // One result per 4x4 block after Sobel, tensor accumulation, and CORDIC.
    output wire       block_valid,
    output wire       block_active,
    output wire [5:0] block_x,
    output wire [5:0] block_y,
    output wire [3:0] block_dir,
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

    wire tensor_valid;
    wire tensor_active;
    wire [5:0] tensor_block_x;
    wire [5:0] tensor_block_y;
    wire signed [31:0] tensor_x;
    wire signed [31:0] tensor_y;

    reg [63:0] done_pipe;

    wire [11:0] abs_gx = gx[11] ? (~gx + 12'd1) : gx;
    wire [11:0] abs_gy = gy[11] ? (~gy + 12'd1) : gy;
    wire [12:0] gradient_strength = {1'b0, abs_gx} + {1'b0, abs_gy};
    wire strong_gradient = sobel_valid && (gradient_strength >= GRADIENT_THRESHOLD);

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

    block_tensor_stat u_block_tensor_stat (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(sobel_valid),
        .vote_valid(strong_gradient),
        .in_x(sobel_x),
        .in_y(sobel_y),
        .gx(gx),
        .gy(gy),
        .block_valid(tensor_valid),
        .block_active(tensor_active),
        .block_x(tensor_block_x),
        .block_y(tensor_block_y),
        .tensor_x(tensor_x),
        .tensor_y(tensor_y)
    );

    cordic_tensor_direction u_cordic_tensor_direction (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(tensor_valid),
        .in_active(tensor_active),
        .in_block_x(tensor_block_x),
        .in_block_y(tensor_block_y),
        .tensor_x(tensor_x),
        .tensor_y(tensor_y),
        .block_valid(block_valid),
        .block_active(block_active),
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
