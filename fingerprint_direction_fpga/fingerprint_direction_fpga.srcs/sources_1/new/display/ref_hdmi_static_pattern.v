`timescale 1ns / 1ps

module ref_hdmi_static_pattern(
    input  wire        data_req,
    input  wire [10:0] pixel_xpos,
    input  wire [10:0] pixel_ypos,
    output reg  [15:0] pixel_data
);

localparam [15:0] BLACK   = 16'h0000;
localparam [15:0] WHITE   = 16'hFFFF;
localparam [15:0] RED     = 16'hF800;
localparam [15:0] GREEN   = 16'h07E0;
localparam [15:0] BLUE    = 16'h001F;
localparam [15:0] CYAN    = 16'h07FF;
localparam [15:0] MAGENTA = 16'hF81F;
localparam [15:0] YELLOW  = 16'hFFE0;
localparam [15:0] GRAY    = 16'h8410;

wire in_center = (pixel_xpos >= 11'd256) && (pixel_xpos < 11'd768) &&
                 (pixel_ypos >= 11'd128) && (pixel_ypos < 11'd640);
wire grid_line = in_center && ((pixel_xpos[4:0] == 5'd0) || (pixel_ypos[4:0] == 5'd0));
wire diag_a = in_center && (pixel_xpos[9:0] == (pixel_ypos[9:0] + 10'd128));
wire diag_b = in_center && ((pixel_xpos[9:0] + pixel_ypos[9:0]) == 10'd895);

always @(*) begin
    if (!data_req) begin
        pixel_data = BLACK;
    end else if (grid_line) begin
        pixel_data = WHITE;
    end else if (diag_a || diag_b) begin
        pixel_data = BLACK;
    end else begin
        case (pixel_xpos[10:7])
            4'd0: pixel_data = WHITE;
            4'd1: pixel_data = YELLOW;
            4'd2: pixel_data = CYAN;
            4'd3: pixel_data = GREEN;
            4'd4: pixel_data = MAGENTA;
            4'd5: pixel_data = RED;
            4'd6: pixel_data = BLUE;
            default: pixel_data = GRAY;
        endcase
    end
end

endmodule
