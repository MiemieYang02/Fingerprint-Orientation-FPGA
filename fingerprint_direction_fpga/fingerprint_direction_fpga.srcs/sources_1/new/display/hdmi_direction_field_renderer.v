`timescale 1ns / 1ps

module hdmi_direction_field_renderer(
    input  wire        data_req,
    input  wire [10:0] pixel_xpos,
    input  wire [10:0] pixel_ypos,
    input  wire        frame_ready,
    input  wire [2:0]  read_block_dir,
    output wire [3:0]  read_block_x,
    output wire [3:0]  read_block_y,
    output reg  [15:0] pixel_data
);

localparam [10:0] FIELD_X0 = 11'd256;
localparam [10:0] FIELD_Y0 = 11'd128;
localparam [10:0] FIELD_SIZE = 11'd512;

localparam [15:0] BLACK   = 16'h0000;
localparam [15:0] WHITE   = 16'hFFFF;
localparam [15:0] DARK    = 16'h0124;
localparam [15:0] FIELD_BG = 16'h39E7;
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
wire [4:0] cell_x = field_x[4:0];
wire [4:0] cell_y = field_y[4:0];
wire [5:0] diag_sum = {1'b0, cell_x} + {1'b0, cell_y};

wire in_segment_x = (cell_x >= 5'd8) && (cell_x <= 5'd23);
wire in_segment_y = (cell_y >= 5'd8) && (cell_y <= 5'd23);
wire horizontal_line = in_segment_x && (cell_y >= 5'd14) && (cell_y <= 5'd17);
wire vertical_line = in_segment_y && (cell_x >= 5'd14) && (cell_x <= 5'd17);
wire diag_down = in_segment_x && in_segment_y &&
                 ((cell_x == cell_y) ||
                  (cell_x + 5'd1 == cell_y) ||
                  (cell_y + 5'd1 == cell_x));
wire diag_up = in_segment_x && in_segment_y &&
               ((diag_sum == 6'd31) ||
                (diag_sum == 6'd30) ||
                (diag_sum == 6'd32));

wire direction_line =
    ((read_block_dir == 3'd0 || read_block_dir == 3'd4) && horizontal_line) ||
    ((read_block_dir == 3'd1 || read_block_dir == 3'd5) && diag_down) ||
    ((read_block_dir == 3'd2 || read_block_dir == 3'd6) && vertical_line) ||
    ((read_block_dir == 3'd3 || read_block_dir == 3'd7) && diag_up);

assign read_block_x = in_field ? field_x[8:5] : 4'd0;
assign read_block_y = in_field ? field_y[8:5] : 4'd0;

always @(*) begin
    if (!data_req) begin
        pixel_data = BLACK;
    end else if (in_field) begin
        if (!frame_ready) begin
            pixel_data = WAIT_BG;
        end else if (direction_line) begin
            pixel_data = WHITE;
        end else begin
            pixel_data = FIELD_BG;
        end
    end else if (pixel_ypos < 11'd64) begin
        case (pixel_xpos[10:7])
            4'd0: pixel_data = WHITE;
            4'd1: pixel_data = YELLOW;
            4'd2: pixel_data = CYAN;
            4'd3: pixel_data = GREEN;
            4'd4: pixel_data = MAGENTA;
            4'd5: pixel_data = RED;
            4'd6: pixel_data = ORANGE;
            default: pixel_data = BLUE;
        endcase
    end else begin
        pixel_data = DARK;
    end
end

endmodule
