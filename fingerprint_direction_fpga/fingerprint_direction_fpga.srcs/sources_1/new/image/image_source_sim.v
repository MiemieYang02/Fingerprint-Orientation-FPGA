`timescale 1ns/1ps

module image_source_sim #(
    parameter IMAGE_W = 256,
    parameter IMAGE_H = 256
) (
    input  wire       clk,
    input  wire       rst_n,
    output reg        out_valid,
    output reg [7:0]  out_gray,
    output reg [7:0]  out_x,
    output reg [7:0]  out_y,
    output reg        out_frame_start,
    output reg        out_line_start,
    output reg        frame_done
);
    reg running;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            running <= 1'b1;
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
                out_gray <= out_x;
                out_frame_start <= (out_x == 8'd0) && (out_y == 8'd0);
                out_line_start <= (out_x == 8'd0);

                if ((out_x == IMAGE_W - 1) && (out_y == IMAGE_H - 1)) begin
                    running <= 1'b0;
                    frame_done <= 1'b1;
                end

                if (out_x == IMAGE_W - 1) begin
                    out_x <= 8'd0;
                    out_y <= out_y + 8'd1;
                end else begin
                    out_x <= out_x + 8'd1;
                end
            end else begin
                out_valid <= 1'b0;
            end
        end
    end
endmodule
