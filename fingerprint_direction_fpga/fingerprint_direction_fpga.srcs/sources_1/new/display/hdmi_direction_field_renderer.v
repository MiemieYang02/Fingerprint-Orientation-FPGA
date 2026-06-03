`timescale 1ns / 1ps

module hdmi_direction_field_renderer #(
    parameter IMAGE_W = 256,
    parameter IMAGE_H = 256,
    parameter MEM_FILE = "fingerprint_static_256.mem"
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        data_req,
    input  wire [10:0] pixel_xpos,
    input  wire [10:0] pixel_ypos,
    input  wire        frame_ready,
    input  wire [2:0]  read_block_dir,
    input  wire        read_block_active,
    output wire [4:0]  read_block_x,
    output wire [4:0]  read_block_y,
    output reg  [15:0] pixel_data
);

localparam [10:0] FIELD_X0 = 11'd256;
localparam [10:0] FIELD_Y0 = 11'd128;
localparam [10:0] FIELD_SIZE = 11'd512;

localparam [15:0] BLACK   = 16'h0000;
localparam [15:0] WHITE   = 16'hFFFF;
localparam [15:0] DARK    = 16'h0124;
localparam [15:0] WAIT_BG = 16'h7BEF;
localparam [15:0] RED     = 16'hF800;
localparam [15:0] GREEN   = 16'h07E0;
localparam [15:0] BLUE    = 16'h001F;
localparam [15:0] CYAN    = 16'h07FF;
localparam [15:0] MAGENTA = 16'hF81F;
localparam [15:0] YELLOW  = 16'hFFE0;
localparam [15:0] ORANGE  = 16'hFC00;

wire in_field_x = (pixel_xpos >= FIELD_X0) && (pixel_xpos < FIELD_X0 + FIELD_SIZE);
wire in_field_y = (pixel_ypos >= FIELD_Y0) && (pixel_ypos < FIELD_Y0 + FIELD_SIZE);
wire in_field = in_field_x && in_field_y;

wire [8:0] field_x = pixel_xpos - FIELD_X0;
wire [8:0] field_y = pixel_ypos - FIELD_Y0;
wire [3:0] cell_x = field_x[3:0];
wire [3:0] cell_y = field_y[3:0];
wire [7:0] image_x = field_x[8:1];
wire [7:0] image_y = field_y[8:1];
wire [15:0] image_addr = image_y * IMAGE_W + image_x;

wire signed [6:0] cell_sx = $signed({1'b0, cell_x}) - 7'sd8;
wire signed [6:0] cell_sy = $signed({1'b0, cell_y}) - 7'sd8;
wire signed [8:0] sx = {{2{cell_sx[6]}}, cell_sx};
wire signed [8:0] sy = {{2{cell_sy[6]}}, cell_sy};

wire in_segment_x = (cell_x >= 4'd3) && (cell_x <= 4'd12);
wire in_segment_y = (cell_y >= 4'd3) && (cell_y <= 4'd12);
wire in_segment = in_segment_x && in_segment_y;

function near_center;
    input signed [8:0] delta;
    begin
        near_center = (delta >= -9'sd1) && (delta <= 9'sd1);
    end
endfunction

// Direction bins are ridge tangent angles over 0..180 degrees:
// 0=0deg, 1=22.5deg, 2=45deg, 3=67.5deg, 4=90deg,
// 5=112.5deg, 6=135deg, 7=157.5deg.
wire line_0   = in_segment_x && near_center(sy);
wire line_22  = in_segment && near_center((sy <<< 1) - sx);
wire line_45  = in_segment && near_center(sy - sx);
wire line_67  = in_segment && near_center(sy - (sx <<< 1));
wire line_90  = in_segment_y && near_center(sx);
wire line_112 = in_segment && near_center(sy + (sx <<< 1));
wire line_135 = in_segment && near_center(sy + sx);
wire line_157 = in_segment && near_center((sy <<< 1) + sx);

wire direction_line = read_block_active && (
    ((read_block_dir == 3'd0) && line_0)   ||
    ((read_block_dir == 3'd1) && line_22)  ||
    ((read_block_dir == 3'd2) && line_45)  ||
    ((read_block_dir == 3'd3) && line_67)  ||
    ((read_block_dir == 3'd4) && line_90)  ||
    ((read_block_dir == 3'd5) && line_112) ||
    ((read_block_dir == 3'd6) && line_135) ||
    ((read_block_dir == 3'd7) && line_157));

assign read_block_x = in_field ? field_x[8:4] : 5'd0;
assign read_block_y = in_field ? field_y[8:4] : 5'd0;

(* rom_style = "block" *) reg [7:0] image_mem [0:IMAGE_W*IMAGE_H-1];

initial begin
    $readmemh(MEM_FILE, image_mem);
end

function [15:0] gray_to_rgb565;
    input [7:0] gray;
    begin
        gray_to_rgb565 = {gray[7:3], gray[7:2], gray[7:3]};
    end
endfunction

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pixel_data <= BLACK;
    end else if (!data_req) begin
        pixel_data <= BLACK;
    end else if (in_field) begin
        if (!frame_ready) begin
            pixel_data <= WAIT_BG;
        end else if (direction_line) begin
            pixel_data <= WHITE;
        end else begin
            pixel_data <= gray_to_rgb565(image_mem[image_addr]);
        end
    end else if (pixel_ypos < 11'd64) begin
        case (pixel_xpos[10:7])
            4'd0: pixel_data <= WHITE;
            4'd1: pixel_data <= YELLOW;
            4'd2: pixel_data <= CYAN;
            4'd3: pixel_data <= GREEN;
            4'd4: pixel_data <= MAGENTA;
            4'd5: pixel_data <= RED;
            4'd6: pixel_data <= ORANGE;
            default: pixel_data <= BLUE;
        endcase
    end else begin
        pixel_data <= DARK;
    end
end

endmodule
