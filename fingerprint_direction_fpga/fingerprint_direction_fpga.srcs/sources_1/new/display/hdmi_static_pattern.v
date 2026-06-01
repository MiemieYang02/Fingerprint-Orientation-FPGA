`timescale 1ns/1ps

module hdmi_static_pattern (
    input  wire        sink_connected,
    input  wire        video_de,
    input  wire [10:0] pixel_x,
    input  wire [10:0] pixel_y,
    output reg  [23:0] rgb
);
    wire in_grid = video_de &&
                   (pixel_x >= 11'd160) && (pixel_x < 11'd480) &&
                   (pixel_y >= 11'd96)  && (pixel_y < 11'd416);
    wire [4:0] grid_x = pixel_x[9:5] - 5'd5;
    wire [4:0] grid_y = pixel_y[9:5] - 5'd3;
    wire grid_line = in_grid && ((pixel_x[4:0] == 5'd0) || (pixel_y[4:0] == 5'd0));
    wire [2:0] dir_bin = (grid_x[2:0] + grid_y[2:0]);

    function [23:0] dir_color;
        input [2:0] dir;
        begin
            case (dir)
                3'd0: dir_color = 24'hE62323;
                3'd1: dir_color = 24'hEB8223;
                3'd2: dir_color = 24'hE6D223;
                3'd3: dir_color = 24'h50BE46;
                3'd4: dir_color = 24'h23AAD2;
                3'd5: dir_color = 24'h2D5FDC;
                3'd6: dir_color = 24'h9146D2;
                default: dir_color = 24'hD746AA;
            endcase
        end
    endfunction

    always @(*) begin
        if (!video_de) begin
            rgb = 24'h000000;
        end else if (pixel_y < 11'd64) begin
            case (pixel_x[10:7])
                4'd0: rgb = 24'hFFFFFF;
                4'd1: rgb = 24'hFFFF00;
                4'd2: rgb = 24'h00FFFF;
                4'd3: rgb = 24'h00FF00;
                4'd4: rgb = 24'hFF00FF;
                4'd5: rgb = 24'hFF0000;
                4'd6: rgb = 24'h0000FF;
                default: rgb = 24'h202020;
            endcase
        end else if (grid_line) begin
            rgb = 24'hFFFFFF;
        end else if (in_grid) begin
            rgb = dir_color(dir_bin);
        end else if (sink_connected) begin
            rgb = 24'h101820;
        end else begin
            rgb = 24'h301010;
        end
    end
endmodule
