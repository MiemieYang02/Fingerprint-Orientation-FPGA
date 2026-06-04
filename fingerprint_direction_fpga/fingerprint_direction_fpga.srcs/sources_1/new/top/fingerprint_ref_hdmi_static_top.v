`timescale 1ns / 1ps

module fingerprint_ref_hdmi_static_top(
    input  wire       sys_clk,
    input  wire       sys_rst_n,
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
wire [5:0] block_x;
wire [5:0] block_y;
wire [3:0] block_dir;
wire algorithm_frame_done;
wire [5:0] read_block_x;
wire [5:0] read_block_y;
wire [3:0] read_block_dir;
wire read_block_active;
wire direction_frame_ready;

assign rst_n = sys_rst_n & locked;

localparam MEM_FILE = "fingerprint_reality_256.mem";

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
    .MEM_FILE(MEM_FILE)
) u_orientation_static_top (
    .clk(pixel_clk),
    .rst_n(rst_n),
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

hdmi_direction_field_renderer #(
    .MEM_FILE(MEM_FILE)
) u_renderer (
    .clk(pixel_clk),
    .rst_n(rst_n),
    .data_req(data_req),
    .pixel_xpos(pixel_xpos),
    .pixel_ypos(pixel_ypos),
    .frame_ready(direction_frame_ready),
    .read_block_dir(read_block_dir),
    .read_block_active(read_block_active),
    .read_block_x(read_block_x),
    .read_block_y(read_block_y),
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
