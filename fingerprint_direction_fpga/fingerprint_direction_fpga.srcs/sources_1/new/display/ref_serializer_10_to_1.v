`timescale 1ns / 1ps

module ref_serializer_10_to_1(
    input  wire       reset,
    input  wire       paralell_clk,
    input  wire       serial_clk_5x,
    input  wire [9:0] paralell_data,
    output wire       serial_data_out
);

wire cascade1;
wire cascade2;

OSERDESE2 #(
    .DATA_RATE_OQ("DDR"),
    .DATA_RATE_TQ("SDR"),
    .DATA_WIDTH(10),
    .SERDES_MODE("MASTER"),
    .TBYTE_CTL("FALSE"),
    .TBYTE_SRC("FALSE"),
    .TRISTATE_WIDTH(1)
) u_oserdes_master (
    .CLK(serial_clk_5x),
    .CLKDIV(paralell_clk),
    .RST(reset),
    .OCE(1'b1),
    .OQ(serial_data_out),
    .D1(paralell_data[0]),
    .D2(paralell_data[1]),
    .D3(paralell_data[2]),
    .D4(paralell_data[3]),
    .D5(paralell_data[4]),
    .D6(paralell_data[5]),
    .D7(paralell_data[6]),
    .D8(paralell_data[7]),
    .SHIFTIN1(cascade1),
    .SHIFTIN2(cascade2),
    .SHIFTOUT1(),
    .SHIFTOUT2(),
    .OFB(),
    .T1(1'b0),
    .T2(1'b0),
    .T3(1'b0),
    .T4(1'b0),
    .TBYTEIN(1'b0),
    .TCE(1'b0),
    .TBYTEOUT(),
    .TFB(),
    .TQ()
);

OSERDESE2 #(
    .DATA_RATE_OQ("DDR"),
    .DATA_RATE_TQ("SDR"),
    .DATA_WIDTH(10),
    .SERDES_MODE("SLAVE"),
    .TBYTE_CTL("FALSE"),
    .TBYTE_SRC("FALSE"),
    .TRISTATE_WIDTH(1)
) u_oserdes_slave (
    .CLK(serial_clk_5x),
    .CLKDIV(paralell_clk),
    .RST(reset),
    .OCE(1'b1),
    .OQ(),
    .D1(1'b0),
    .D2(1'b0),
    .D3(paralell_data[8]),
    .D4(paralell_data[9]),
    .D5(1'b0),
    .D6(1'b0),
    .D7(1'b0),
    .D8(1'b0),
    .SHIFTIN1(),
    .SHIFTIN2(),
    .SHIFTOUT1(cascade1),
    .SHIFTOUT2(cascade2),
    .OFB(),
    .T1(1'b0),
    .T2(1'b0),
    .T3(1'b0),
    .T4(1'b0),
    .TBYTEIN(1'b0),
    .TCE(1'b0),
    .TBYTEOUT(),
    .TFB(),
    .TQ()
);

endmodule
