`timescale 1ns / 1ps

module ref_hdmi_top(
    input  wire        pixel_clk,
    input  wire        pixel_clk_5x,
    input  wire        sys_rst_n,
    input  wire        hpdin,
    output wire        tmds_clk_p,
    output wire        tmds_clk_n,
    output wire [2:0]  tmds_data_p,
    output wire [2:0]  tmds_data_n,
    output wire        tmds_oen,
    output wire        hpdout,
    output wire        video_vs,
    output wire [10:0] h_disp,
    output wire [10:0] v_disp,
    output wire [10:0] pixel_xpos,
    output wire [10:0] pixel_ypos,
    input  wire [15:0] data_in,
    output wire        data_req
);

wire        video_hs;
wire        video_de;
wire [15:0] video_rgb_565;
wire [23:0] video_rgb;

assign hpdout = hpdin;
assign video_rgb = {video_rgb_565[15:11], 3'b000,
                    video_rgb_565[10:5],  2'b00,
                    video_rgb_565[4:0],   3'b000};

ref_video_driver u_video_driver (
    .pixel_clk(pixel_clk),
    .sys_rst_n(sys_rst_n),
    .video_hs(video_hs),
    .video_vs(video_vs),
    .video_de(video_de),
    .video_rgb(video_rgb_565),
    .pixel_data(data_in),
    .pixel_xpos(pixel_xpos),
    .pixel_ypos(pixel_ypos),
    .h_disp(h_disp),
    .v_disp(v_disp),
    .data_req(data_req)
);

ref_dvi_transmitter_top u_rgb2dvi (
    .pclk(pixel_clk),
    .pclk_x5(pixel_clk_5x),
    .reset_n(sys_rst_n),
    .video_din(video_rgb),
    .video_hsync(video_hs),
    .video_vsync(video_vs),
    .video_de(video_de),
    .tmds_clk_p(tmds_clk_p),
    .tmds_clk_n(tmds_clk_n),
    .tmds_data_p(tmds_data_p),
    .tmds_data_n(tmds_data_n),
    .tmds_oen(tmds_oen)
);

endmodule
