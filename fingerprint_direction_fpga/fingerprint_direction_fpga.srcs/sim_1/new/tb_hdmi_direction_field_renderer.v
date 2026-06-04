`timescale 1ns/1ps

module tb_hdmi_direction_field_renderer;
    reg clk;
    reg rst_n;
    reg data_req;
    reg [10:0] pixel_xpos;
    reg [10:0] pixel_ypos;
    reg frame_ready;
    reg [3:0] read_block_dir;
    reg read_block_active;
    wire [5:0] read_block_x;
    wire [5:0] read_block_y;
    wire [15:0] pixel_data;

    integer errors;

    hdmi_direction_field_renderer #(
        .MEM_FILE("fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/image/fingerprint_static_256.mem")
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_req(data_req),
        .pixel_xpos(pixel_xpos),
        .pixel_ypos(pixel_ypos),
        .frame_ready(frame_ready),
        .read_block_dir(read_block_dir),
        .read_block_active(read_block_active),
        .read_block_x(read_block_x),
        .read_block_y(read_block_y),
        .pixel_data(pixel_data)
    );

    task expect_pixel;
        input [10:0] x;
        input [10:0] y;
        input [3:0] dir;
        input       active;
        input [5:0] exp_bx;
        input [5:0] exp_by;
        input [15:0] exp_rgb;
        begin
            pixel_xpos = x;
            pixel_ypos = y;
            read_block_dir = dir;
            read_block_active = active;
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
        input [3:0] dir;
        begin
            pixel_xpos = x;
            pixel_ypos = y;
            read_block_dir = dir;
            read_block_active = 1'b1;
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
        data_req = 1'b1;
        frame_ready = 1'b1;
        pixel_xpos = 11'd0;
        pixel_ypos = 11'd0;
        read_block_dir = 4'd0;
        read_block_active = 1'b1;
        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        expect_pixel(11'd256, 11'd128, 4'd0, 1'b1, 6'd0, 6'd0, 16'hEF5D);
        expect_pixel(11'd260, 11'd132, 4'd0, 1'b1, 6'd0, 6'd0, 16'hFFFF);
        expect_pixel(11'd260, 11'd132, 4'd0, 1'b0, 6'd0, 6'd0, 16'hEF5D);
        expect_pixel(11'd264, 11'd132, 4'd0, 1'b1, 6'd1, 6'd0, 16'hEF5D);
        expect_pixel(11'd260, 11'd134, 4'd8, 1'b1, 6'd0, 6'd0, 16'hFFFF);
        expect_pixel(11'd262, 11'd134, 4'd4, 1'b1, 6'd0, 6'd0, 16'hFFFF);
        expect_pixel(11'd258, 11'd134, 4'd12, 1'b1, 6'd0, 6'd0, 16'hFFFF);
        expect_pixel(11'd257, 11'd131, 4'd2, 1'b1, 6'd0, 6'd0, 16'hFFFF);
        expect_not_white(11'd259, 11'd133, 4'd2);

        frame_ready = 1'b0;
        expect_pixel(11'd260, 11'd132, 4'd0, 1'b1, 6'd0, 6'd0, 16'h7BEF);

        data_req = 1'b0;
        expect_pixel(11'd260, 11'd132, 4'd0, 1'b1, 6'd0, 6'd0, 16'h0000);

        if (errors != 0) begin
            $display("HDMI_RENDER_TEST_FAIL errors=%0d", errors);
            $finish(1);
        end
        $display("HDMI_RENDER_TEST_PASS");
        $finish;
    end
endmodule
