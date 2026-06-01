`timescale 1ns/1ps

module fingerprint_hdmi_static_top (
    input  wire       sys_clk,
    input  wire       sys_rst_n,
    input  wire       hpdin,
    output wire       tmds_clk_p,
    output wire       tmds_clk_n,
    output wire [2:0] tmds_data_p,
    output wire [2:0] tmds_data_n
);
    wire pixel_clk;
    wire serial_clk_5x;
    wire clk_locked;
    wire video_hs;
    wire video_vs;
    wire video_de;
    wire [10:0] pixel_x;
    wire [10:0] pixel_y;
    wire [23:0] rgb;
    wire display_rst_n = sys_rst_n & clk_locked;

    hdmi_clock_gen u_hdmi_clock_gen (
        .clk_in(sys_clk),
        .rst(~sys_rst_n),
        .pixel_clk(pixel_clk),
        .serial_clk_5x(serial_clk_5x),
        .locked(clk_locked)
    );

    video_timing_640x480 u_video_timing_640x480 (
        .pixel_clk(pixel_clk),
        .rst_n(display_rst_n),
        .video_hs(video_hs),
        .video_vs(video_vs),
        .video_de(video_de),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y)
    );

    hdmi_static_pattern u_hdmi_static_pattern (
        .sink_connected(hpdin),
        .video_de(video_de),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .rgb(rgb)
    );

    hdmi_tx_640x480 u_hdmi_tx_640x480 (
        .pixel_clk(pixel_clk),
        .serial_clk_5x(serial_clk_5x),
        .rst_n(display_rst_n),
        .rgb(rgb),
        .video_hs(video_hs),
        .video_vs(video_vs),
        .video_de(video_de),
        .tmds_clk_p(tmds_clk_p),
        .tmds_clk_n(tmds_clk_n),
        .tmds_data_p(tmds_data_p),
        .tmds_data_n(tmds_data_n)
    );
endmodule
