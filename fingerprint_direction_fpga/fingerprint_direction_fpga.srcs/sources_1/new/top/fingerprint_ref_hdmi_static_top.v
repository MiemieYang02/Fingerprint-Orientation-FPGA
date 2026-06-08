`timescale 1ns / 1ps

module fingerprint_ref_hdmi_static_top(
    input  wire       sys_clk,
    input  wire       sys_rst_n,
    input  wire [1:0] sw,
    input  wire       hpdin,
    output wire       tmds_clk_p,
    output wire       tmds_clk_n,
    output wire [2:0] tmds_data_p,
    output wire [2:0] tmds_data_n
);

wire pixel_clk;
wire pixel_clk_5x;
wire locked;
wire rst_n;
wire video_vs;
wire [10:0] h_disp;
wire [10:0] v_disp;
wire [10:0] pixel_xpos;
wire [10:0] pixel_ypos;
wire [15:0] display_data;
wire data_req;
wire block_valid;
wire block_active;
wire [4:0] block_x;
wire [4:0] block_y;
wire [2:0] block_dir;
wire algorithm_frame_done;
wire [4:0] read_block_x;
wire [4:0] read_block_y;
wire [2:0] read_block_dir;
wire read_block_active;
wire direction_frame_ready;
wire [1:0] image_sel;
wire [15:0] image_read_addr;
wire [7:0] image_read_gray;

assign rst_n = sys_rst_n & locked;
// SW[1:0] selects image 0/1/2. 2'b11 is reserved and falls back to image 0.
assign image_sel = (sw == 2'b11) ? 2'b00 : sw;

localparam MEM_FILE0 = "fingerprint_0_256.mem";
localparam MEM_FILE1 = "fingerprint_1_256.mem";
localparam MEM_FILE2 = "fingerprint_2_256.mem";

ref_hdmi_clock_gen u_clock_gen (
    .clk_in(sys_clk),
    .reset(~sys_rst_n),
    .pixel_clk(pixel_clk),
    .pixel_clk_5x(pixel_clk_5x),
    .locked(locked)
);

// Static fingerprint image path for hardware validation before camera/DDR3 input.
// The downstream Sobel/CORDIC/statistics pipeline is the same real stream core.
fpga_orientation_static_top #(
    .MEM_FILE0(MEM_FILE0),
    .MEM_FILE1(MEM_FILE1),
    .MEM_FILE2(MEM_FILE2)
) u_orientation_static_top (
    .clk(pixel_clk),
    .rst_n(rst_n),
    .image_sel(image_sel),
    .display_read_addr(image_read_addr),
    .display_read_gray(image_read_gray),
    .block_valid(block_valid),
    .block_active(block_active),
    .block_x(block_x),
    .block_y(block_y),
    .block_dir(block_dir),
    .frame_done(algorithm_frame_done)
);

direction_field_buffer u_direction_field_buffer (
    .clk(pixel_clk),
    .rst_n(rst_n),
    .block_valid(block_valid),
    .block_active(block_active),
    .block_x(block_x),
    .block_y(block_y),
    .block_dir(block_dir),
    .read_block_x(read_block_x),
    .read_block_y(read_block_y),
    .read_block_dir(read_block_dir),
    .read_block_active(read_block_active),
    .frame_ready(direction_frame_ready)
);

hdmi_direction_field_renderer u_renderer (
    .clk(pixel_clk),
    .rst_n(rst_n),
    .image_gray(image_read_gray),
    .data_req(data_req),
    .pixel_xpos(pixel_xpos),
    .pixel_ypos(pixel_ypos),
    .frame_ready(direction_frame_ready),
    .read_block_dir(read_block_dir),
    .read_block_active(read_block_active),
    .read_block_x(read_block_x),
    .read_block_y(read_block_y),
    .image_read_addr(image_read_addr),
    .pixel_data(display_data)
);

ref_hdmi_top u_hdmi_top (
    .pixel_clk(pixel_clk),
    .pixel_clk_5x(pixel_clk_5x),
    .sys_rst_n(rst_n),
    .hpdin(hpdin),
    .tmds_clk_p(tmds_clk_p),
    .tmds_clk_n(tmds_clk_n),
    .tmds_data_p(tmds_data_p),
    .tmds_data_n(tmds_data_n),
    .tmds_oen(),
    .hpdout(),
    .video_vs(video_vs),
    .h_disp(h_disp),
    .v_disp(v_disp),
    .pixel_xpos(pixel_xpos),
    .pixel_ypos(pixel_ypos),
    .data_in(display_data),
    .data_req(data_req)
);

endmodule
