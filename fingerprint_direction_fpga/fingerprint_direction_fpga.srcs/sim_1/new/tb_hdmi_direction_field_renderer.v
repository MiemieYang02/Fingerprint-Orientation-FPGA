`timescale 1ns/1ps

module tb_hdmi_direction_field_renderer;
    reg clk;
    reg rst_n;
    reg [7:0] image_gray;
    reg data_req;
    reg [10:0] pixel_xpos;
    reg [10:0] pixel_ypos;
    reg frame_ready;
    reg [2:0] read_block_dir;
    reg read_block_active;
    wire [4:0] read_block_x;
    wire [4:0] read_block_y;
    wire [15:0] image_read_addr;
    wire [15:0] pixel_data;

    integer errors;

    hdmi_direction_field_renderer dut (
        .clk(clk),
        .rst_n(rst_n),
        .image_gray(image_gray),
        .data_req(data_req),
        .pixel_xpos(pixel_xpos),
        .pixel_ypos(pixel_ypos),
        .frame_ready(frame_ready),
        .read_block_dir(read_block_dir),
        .read_block_active(read_block_active),
        .read_block_x(read_block_x),
        .read_block_y(read_block_y),
        .image_read_addr(image_read_addr),
        .pixel_data(pixel_data)
    );

    task expect_pixel;
        input [10:0] x;
        input [10:0] y;
        input [2:0] dir;
        input       active;
        input [4:0] exp_bx;
        input [4:0] exp_by;
        input [15:0] exp_rgb;
        begin
            pixel_xpos = x;
            pixel_ypos = y;
            read_block_dir = dir;
            read_block_active = active;
            image_gray = 8'heb;
            @(posedge clk);
            @(posedge clk);
            #1;
            if (read_block_x !== exp_bx || read_block_y !== exp_by || pixel_data !== exp_rgb) begin
                $display("RENDER_MISMATCH x=%0d y=%0d dir=%0d bx=%0d/%0d by=%0d/%0d rgb=%h/%h",
                         x, y, dir, read_block_x, exp_bx, read_block_y, exp_by, pixel_data, exp_rgb);
                errors = errors + 1;
            end
        end
    endtask

    task expect_not_white;
        input [10:0] x;
        input [10:0] y;
        input [2:0] dir;
        begin
            pixel_xpos = x;
            pixel_ypos = y;
            read_block_dir = dir;
            read_block_active = 1'b1;
            image_gray = 8'heb;
            @(posedge clk);
            @(posedge clk);
            #1;
            if (pixel_data === 16'hFFFF) begin
                $display("RENDER_UNEXPECTED_WHITE x=%0d y=%0d dir=%0d rgb=%h",
                         x, y, dir, pixel_data);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        errors = 0;
        rst_n = 1'b0;
        image_gray = 8'heb;
        data_req = 1'b1;
        frame_ready = 1'b1;
        pixel_xpos = 11'd0;
        pixel_ypos = 11'd0;
        read_block_dir = 3'd0;
        read_block_active = 1'b1;
        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        expect_pixel(11'd256, 11'd128, 3'd0, 1'b1, 5'd0, 5'd0, 16'hEF5D);
        expect_pixel(11'd263, 11'd135, 3'd0, 1'b1, 5'd0, 5'd0, 16'hFFFF);
        expect_pixel(11'd263, 11'd135, 3'd0, 1'b0, 5'd0, 5'd0, 16'hEF5D);
        expect_pixel(11'd271, 11'd135, 3'd0, 1'b1, 5'd0, 5'd0, 16'hEF5D);
        expect_pixel(11'd295, 11'd168, 3'd4, 1'b1, 5'd2, 5'd2, 16'hFFFF);
        expect_pixel(11'd295, 11'd170, 3'd0, 1'b1, 5'd2, 5'd2, 16'hEF5D);
        // Display mirrors oblique bins only: 2 draws as 6, and 6 draws as 2.
        expect_pixel(11'd308, 11'd172, 3'd2, 1'b1, 5'd3, 5'd2, 16'hFFFF);
        expect_not_white(11'd308, 11'd180, 3'd2);
        expect_pixel(11'd308, 11'd180, 3'd6, 1'b1, 5'd3, 5'd3, 16'hFFFF);
        expect_not_white(11'd308, 11'd172, 3'd6);
        expect_not_white(11'd259, 11'd133, 3'd1);

        frame_ready = 1'b0;
        expect_pixel(11'd263, 11'd135, 3'd0, 1'b1, 5'd0, 5'd0, 16'h7BEF);

        data_req = 1'b0;
        expect_pixel(11'd263, 11'd135, 3'd0, 1'b1, 5'd0, 5'd0, 16'h0000);

        if (errors != 0) begin
            $display("HDMI_RENDER_TEST_FAIL errors=%0d", errors);
            $finish(1);
        end
        $display("HDMI_RENDER_TEST_PASS");
        $finish;
    end
endmodule
