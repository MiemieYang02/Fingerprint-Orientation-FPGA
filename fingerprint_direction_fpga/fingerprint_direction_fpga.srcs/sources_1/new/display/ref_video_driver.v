`timescale 1ns / 1ps

module ref_video_driver(
    input  wire        pixel_clk,
    input  wire        sys_rst_n,
    output wire        video_hs,
    output wire        video_vs,
    output wire        video_de,
    output wire [15:0] video_rgb,
    input  wire [15:0] pixel_data,
    output wire [10:0] pixel_xpos,
    output wire [10:0] pixel_ypos,
    output wire [10:0] h_disp,
    output wire [10:0] v_disp,
    output wire        data_req
);

localparam [10:0] H_SYNC  = 11'd136;
localparam [10:0] H_BACK  = 11'd160;
localparam [10:0] H_DISP  = 11'd1024;
localparam [10:0] H_FRONT = 11'd24;
localparam [10:0] H_TOTAL = 11'd1344;

localparam [10:0] V_SYNC  = 11'd6;
localparam [10:0] V_BACK  = 11'd29;
localparam [10:0] V_DISP  = 11'd768;
localparam [10:0] V_FRONT = 11'd3;
localparam [10:0] V_TOTAL = 11'd806;

reg [10:0] cnt_h;
reg [10:0] cnt_v;

wire video_en;

assign video_de = video_en;
assign video_hs = (cnt_h < H_SYNC) ? 1'b0 : 1'b1;
assign video_vs = (cnt_v < V_SYNC) ? 1'b0 : 1'b1;

assign video_en = ((cnt_h >= H_SYNC + H_BACK) && (cnt_h < H_SYNC + H_BACK + H_DISP) &&
                   (cnt_v >= V_SYNC + V_BACK) && (cnt_v < V_SYNC + V_BACK + V_DISP));

assign video_rgb = video_en ? pixel_data : 16'd0;

assign data_req = ((cnt_h >= H_SYNC + H_BACK - 1'b1) &&
                   (cnt_h < H_SYNC + H_BACK + H_DISP - 1'b1) &&
                   (cnt_v >= V_SYNC + V_BACK) &&
                   (cnt_v < V_SYNC + V_BACK + V_DISP));

assign pixel_xpos = data_req ? (cnt_h - (H_SYNC + H_BACK - 1'b1)) : 11'd0;
assign pixel_ypos = data_req ? (cnt_v - (V_SYNC + V_BACK - 1'b1)) : 11'd0;

assign h_disp = H_DISP;
assign v_disp = V_DISP;

always @(posedge pixel_clk) begin
    if (!sys_rst_n) begin
        cnt_h <= 11'd0;
    end else if (cnt_h < H_TOTAL - 1'b1) begin
        cnt_h <= cnt_h + 1'b1;
    end else begin
        cnt_h <= 11'd0;
    end
end

always @(posedge pixel_clk) begin
    if (!sys_rst_n) begin
        cnt_v <= 11'd0;
    end else if (cnt_h == H_TOTAL - 1'b1) begin
        if (cnt_v < V_TOTAL - 1'b1) begin
            cnt_v <= cnt_v + 1'b1;
        end else begin
            cnt_v <= 11'd0;
        end
    end
end

endmodule
