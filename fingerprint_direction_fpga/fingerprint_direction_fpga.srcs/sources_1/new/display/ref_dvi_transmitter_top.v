`timescale 1ns / 1ps

module ref_dvi_transmitter_top(
    input  wire       pclk,
    input  wire       pclk_x5,
    input  wire       reset_n,
    input  wire [23:0] video_din,
    input  wire       video_hsync,
    input  wire       video_vsync,
    input  wire       video_de,
    output wire       tmds_clk_p,
    output wire       tmds_clk_n,
    output wire [2:0] tmds_data_p,
    output wire [2:0] tmds_data_n,
    output wire       tmds_oen
);

wire reset;
wire [9:0] red_10bit;
wire [9:0] green_10bit;
wire [9:0] blue_10bit;
wire [9:0] clk_10bit = 10'b1111100000;
wire [2:0] tmds_data_serial;
wire       tmds_clk_serial;

assign tmds_oen = 1'b1;

ref_asyn_rst_syn u_reset_syn (
    .reset_n(reset_n),
    .clk(pclk),
    .syn_reset(reset)
);

ref_dvi_encoder u_encoder_b (
    .clkin(pclk),
    .rstin(reset),
    .din(video_din[7:0]),
    .c0(video_hsync),
    .c1(video_vsync),
    .de(video_de),
    .dout(blue_10bit)
);

ref_dvi_encoder u_encoder_g (
    .clkin(pclk),
    .rstin(reset),
    .din(video_din[15:8]),
    .c0(1'b0),
    .c1(1'b0),
    .de(video_de),
    .dout(green_10bit)
);

ref_dvi_encoder u_encoder_r (
    .clkin(pclk),
    .rstin(reset),
    .din(video_din[23:16]),
    .c0(1'b0),
    .c1(1'b0),
    .de(video_de),
    .dout(red_10bit)
);

ref_serializer_10_to_1 u_serializer_b (
    .reset(reset),
    .paralell_clk(pclk),
    .serial_clk_5x(pclk_x5),
    .paralell_data(blue_10bit),
    .serial_data_out(tmds_data_serial[0])
);

ref_serializer_10_to_1 u_serializer_g (
    .reset(reset),
    .paralell_clk(pclk),
    .serial_clk_5x(pclk_x5),
    .paralell_data(green_10bit),
    .serial_data_out(tmds_data_serial[1])
);

ref_serializer_10_to_1 u_serializer_r (
    .reset(reset),
    .paralell_clk(pclk),
    .serial_clk_5x(pclk_x5),
    .paralell_data(red_10bit),
    .serial_data_out(tmds_data_serial[2])
);

ref_serializer_10_to_1 u_serializer_clk (
    .reset(reset),
    .paralell_clk(pclk),
    .serial_clk_5x(pclk_x5),
    .paralell_data(clk_10bit),
    .serial_data_out(tmds_clk_serial)
);

OBUFDS #(.IOSTANDARD("TMDS_33")) u_tmds0 (
    .I(tmds_data_serial[0]),
    .O(tmds_data_p[0]),
    .OB(tmds_data_n[0])
);

OBUFDS #(.IOSTANDARD("TMDS_33")) u_tmds1 (
    .I(tmds_data_serial[1]),
    .O(tmds_data_p[1]),
    .OB(tmds_data_n[1])
);

OBUFDS #(.IOSTANDARD("TMDS_33")) u_tmds2 (
    .I(tmds_data_serial[2]),
    .O(tmds_data_p[2]),
    .OB(tmds_data_n[2])
);

OBUFDS #(.IOSTANDARD("TMDS_33")) u_tmds3 (
    .I(tmds_clk_serial),
    .O(tmds_clk_p),
    .OB(tmds_clk_n)
);

endmodule
