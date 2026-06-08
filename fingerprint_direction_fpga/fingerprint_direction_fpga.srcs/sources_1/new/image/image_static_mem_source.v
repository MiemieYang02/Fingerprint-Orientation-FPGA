`timescale 1ns/1ps

// Synthesis-friendly static image source.
// The .mem image is read as a ROM and emitted as the same grayscale pixel stream
// used by the real-input orientation pipeline. Replace MEM_FILE to test another
// fingerprint image without changing Sobel/CORDIC/statistics logic.
(* keep_hierarchy = "yes" *)
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
    input  wire [15:0] display_read_addr,
    output reg [7:0]  display_read_gray,
    output reg        out_valid,
    output reg [7:0]  out_gray,
    output reg [7:0]  out_x,
    output reg [7:0]  out_y,
    output reg        out_frame_start,
    output reg        out_line_start,
    output reg        frame_done
);
    localparam TOTAL_PIXELS = IMAGE_W * IMAGE_H;
    localparam [17:0] IMAGE0_BASE = 18'd0;
    localparam [17:0] IMAGE1_BASE = TOTAL_PIXELS;
    localparam [17:0] IMAGE2_BASE = TOTAL_PIXELS * 2;
    localparam ROM_PIXELS = TOTAL_PIXELS * 3;

    (* rom_style = "block", ram_style = "block" *) reg [7:0] image_mem [0:ROM_PIXELS-1];
    reg running;
    reg [15:0] pixel_index;
    reg [1:0] active_image_sel;
    wire [7:0] pixel_x_fast = (IMAGE_W == 256) ? pixel_index[7:0] : (pixel_index % IMAGE_W);
    wire [7:0] pixel_y_fast = (IMAGE_W == 256) ? pixel_index[15:8] : (pixel_index / IMAGE_W);
    wire line_start_fast = (IMAGE_W == 256) ? (pixel_index[7:0] == 8'd0) : ((pixel_index % IMAGE_W) == 0);
    wire [17:0] display_rom_addr = image_base(active_image_sel) + display_read_addr;
    wire [17:0] stream_rom_addr = image_base(active_image_sel) + pixel_index;

    initial begin
        $readmemh(MEM_FILE0, image_mem, IMAGE0_BASE, IMAGE1_BASE - 1);
        $readmemh(MEM_FILE1, image_mem, IMAGE1_BASE, IMAGE2_BASE - 1);
        $readmemh(MEM_FILE2, image_mem, IMAGE2_BASE, ROM_PIXELS - 1);
    end

    function [17:0] image_base;
        input [1:0] sel;
        begin
            case (sel)
                2'd1: image_base = IMAGE1_BASE;
                2'd2: image_base = IMAGE2_BASE;
                default: image_base = IMAGE0_BASE;
            endcase
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            running <= 1'b1;
            pixel_index <= 16'd0;
            active_image_sel <= image_sel;
            display_read_gray <= 8'd0;
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

            display_read_gray <= image_mem[display_rom_addr];

            if (running) begin
                out_valid <= 1'b1;
                out_gray <= image_mem[stream_rom_addr];
                out_x <= pixel_x_fast;
                out_y <= pixel_y_fast;
                out_frame_start <= (pixel_index == 16'd0);
                out_line_start <= line_start_fast;

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
