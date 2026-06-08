`timescale 1ns/1ps

// Synthesis-friendly static image source.
// The .mem image is read as a ROM and emitted as the same grayscale pixel stream
// used by the real-input orientation pipeline. Replace MEM_FILE to test another
// fingerprint image without changing Sobel/CORDIC/statistics logic.
module image_static_mem_source #(
    parameter IMAGE_W = 256,
    parameter IMAGE_H = 256,
    parameter MEM_FILE = "fingerprint_static_256.mem",
    parameter MEM_FILE0 = MEM_FILE,
    parameter MEM_FILE1 = MEM_FILE,
    parameter MEM_FILE2 = MEM_FILE
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [1:0] image_sel,
    output reg        out_valid,
    output reg [7:0]  out_gray,
    output reg [7:0]  out_x,
    output reg [7:0]  out_y,
    output reg        out_frame_start,
    output reg        out_line_start,
    output reg        frame_done
);
    localparam TOTAL_PIXELS = IMAGE_W * IMAGE_H;

    (* rom_style = "block" *) reg [7:0] image_mem0 [0:TOTAL_PIXELS-1];
    (* rom_style = "block" *) reg [7:0] image_mem1 [0:TOTAL_PIXELS-1];
    (* rom_style = "block" *) reg [7:0] image_mem2 [0:TOTAL_PIXELS-1];
    reg running;
    reg [15:0] pixel_index;
    reg [1:0] active_image_sel;

    initial begin
        $readmemh(MEM_FILE0, image_mem0);
        $readmemh(MEM_FILE1, image_mem1);
        $readmemh(MEM_FILE2, image_mem2);
    end

    function [7:0] selected_pixel;
        input [1:0] sel;
        input [15:0] addr;
        begin
            case (sel)
                2'd1: selected_pixel = image_mem1[addr];
                2'd2: selected_pixel = image_mem2[addr];
                default: selected_pixel = image_mem0[addr];
            endcase
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            running <= 1'b1;
            pixel_index <= 16'd0;
            active_image_sel <= image_sel;
            out_valid <= 1'b0;
            out_gray <= 8'd0;
            out_x <= 8'd0;
            out_y <= 8'd0;
            out_frame_start <= 1'b0;
            out_line_start <= 1'b0;
            frame_done <= 1'b0;
        end else begin
            frame_done <= 1'b0;
            out_frame_start <= 1'b0;
            out_line_start <= 1'b0;

            if (running) begin
                out_valid <= 1'b1;
                out_gray <= selected_pixel(active_image_sel, pixel_index);
                out_x <= pixel_index % IMAGE_W;
                out_y <= pixel_index / IMAGE_W;
                out_frame_start <= (pixel_index == 16'd0);
                out_line_start <= ((pixel_index % IMAGE_W) == 0);

                if (pixel_index == TOTAL_PIXELS - 1) begin
                    running <= 1'b0;
                    frame_done <= 1'b1;
                end else begin
                    pixel_index <= pixel_index + 16'd1;
                end
            end else begin
                out_valid <= 1'b0;
                if (active_image_sel != image_sel) begin
                    active_image_sel <= image_sel;
                    pixel_index <= 16'd0;
                    running <= 1'b1;
                end
            end
        end
    end
endmodule
