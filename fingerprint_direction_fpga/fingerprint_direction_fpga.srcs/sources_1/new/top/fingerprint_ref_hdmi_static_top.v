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
wire [15:0] pattern_data;
wire data_req;

assign rst_n = sys_rst_n & locked;

ref_hdmi_clock_gen u_clock_gen (
    .clk_in(sys_clk),
    .reset(~sys_rst_n),
    .pixel_clk(pixel_clk),
    .pixel_clk_5x(pixel_clk_5x),
    .locked(locked)
);

ref_hdmi_static_pattern u_pattern (
    .data_req(data_req),
    .pixel_xpos(pixel_xpos),
    .pixel_ypos(pixel_ypos),
    .pixel_data(pattern_data)
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
    .data_in(pattern_data),
    .data_req(data_req)
);

endmodule
