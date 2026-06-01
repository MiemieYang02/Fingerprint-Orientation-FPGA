`timescale 1ns/1ps

module hdmi_tx_640x480 (
    input  wire        pixel_clk,
    input  wire        serial_clk_5x,
    input  wire        rst_n,
    input  wire [23:0] rgb,
    input  wire        video_hs,
    input  wire        video_vs,
    input  wire        video_de,
    output wire        tmds_clk_p,
    output wire        tmds_clk_n,
    output wire [2:0]  tmds_data_p,
    output wire [2:0]  tmds_data_n
);
    wire rst = ~rst_n;
    wire [9:0] tmds_red;
    wire [9:0] tmds_green;
    wire [9:0] tmds_blue;
    wire [2:0] serial_data;
    wire serial_clk_data;

    tmds_encoder u_tmds_encoder_blue (
        .pixel_clk(pixel_clk),
        .rst(rst),
        .data_in(rgb[7:0]),
        .c0(video_hs),
        .c1(video_vs),
        .de(video_de),
        .tmds_out(tmds_blue)
    );

    tmds_encoder u_tmds_encoder_green (
        .pixel_clk(pixel_clk),
        .rst(rst),
        .data_in(rgb[15:8]),
        .c0(1'b0),
        .c1(1'b0),
        .de(video_de),
        .tmds_out(tmds_green)
    );

    tmds_encoder u_tmds_encoder_red (
        .pixel_clk(pixel_clk),
        .rst(rst),
        .data_in(rgb[23:16]),
        .c0(1'b0),
        .c1(1'b0),
        .de(video_de),
        .tmds_out(tmds_red)
    );

    tmds_serializer_10to1 u_serializer_blue (
        .rst(rst),
        .pixel_clk(pixel_clk),
        .serial_clk_5x(serial_clk_5x),
        .parallel_data(tmds_blue),
        .serial_data(serial_data[0])
    );

    tmds_serializer_10to1 u_serializer_green (
        .rst(rst),
        .pixel_clk(pixel_clk),
        .serial_clk_5x(serial_clk_5x),
        .parallel_data(tmds_green),
        .serial_data(serial_data[1])
    );

    tmds_serializer_10to1 u_serializer_red (
        .rst(rst),
        .pixel_clk(pixel_clk),
        .serial_clk_5x(serial_clk_5x),
        .parallel_data(tmds_red),
        .serial_data(serial_data[2])
    );

    tmds_serializer_10to1 u_serializer_clk (
        .rst(rst),
        .pixel_clk(pixel_clk),
        .serial_clk_5x(serial_clk_5x),
        .parallel_data(10'b1111100000),
        .serial_data(serial_clk_data)
    );

    OBUFDS #(.IOSTANDARD("TMDS_33")) u_obufds_clk (
        .I(serial_clk_data),
        .O(tmds_clk_p),
        .OB(tmds_clk_n)
    );

    OBUFDS #(.IOSTANDARD("TMDS_33")) u_obufds_data0 (
        .I(serial_data[0]),
        .O(tmds_data_p[0]),
        .OB(tmds_data_n[0])
    );

    OBUFDS #(.IOSTANDARD("TMDS_33")) u_obufds_data1 (
        .I(serial_data[1]),
        .O(tmds_data_p[1]),
        .OB(tmds_data_n[1])
    );

    OBUFDS #(.IOSTANDARD("TMDS_33")) u_obufds_data2 (
        .I(serial_data[2]),
        .O(tmds_data_p[2]),
        .OB(tmds_data_n[2])
    );
endmodule
