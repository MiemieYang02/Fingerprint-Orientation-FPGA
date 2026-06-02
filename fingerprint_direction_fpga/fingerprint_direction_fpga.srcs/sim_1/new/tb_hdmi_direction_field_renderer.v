`timescale 1ns/1ps

module tb_hdmi_direction_field_renderer;
    reg clk;
    reg rst_n;
    reg data_req;
    reg [10:0] pixel_xpos;
    reg [10:0] pixel_ypos;
    reg frame_ready;
    reg [2:0] read_block_dir;
    wire [3:0] read_block_x;
    wire [3:0] read_block_y;
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
        .read_block_x(read_block_x),
        .read_block_y(read_block_y),
        .pixel_data(pixel_data)
    );

    task expect_pixel;
        input [10:0] x;
        input [10:0] y;
        input [2:0] dir;
        input [3:0] exp_bx;
        input [3:0] exp_by;
        input [15:0] exp_rgb;
        begin
            pixel_xpos = x;
            pixel_ypos = y;
            read_block_dir = dir;
            @(posedge clk);
            #1;
            if (read_block_x !== exp_bx || read_block_y !== exp_by || pixel_data !== exp_rgb) begin
                $display("RENDER_MISMATCH x=%0d y=%0d dir=%0d bx=%0d/%0d by=%0d/%0d rgb=%h/%h",
                         x, y, dir, read_block_x, exp_bx, read_block_y, exp_by, pixel_data, exp_rgb);
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
        read_block_dir = 3'd0;
        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        expect_pixel(11'd256, 11'd128, 3'd0, 4'd0, 4'd0, 16'hEF5D);
        expect_pixel(11'd271, 11'd143, 3'd0, 4'd0, 4'd0, 16'hFFFF);
        expect_pixel(11'd287, 11'd143, 3'd0, 4'd0, 4'd0, 16'hEF5D);
        expect_pixel(11'd335, 11'd208, 3'd4, 4'd2, 4'd2, 16'hFFFF);
        expect_pixel(11'd335, 11'd212, 3'd0, 4'd2, 4'd2, 16'hEF5D);
        expect_pixel(11'd367, 11'd239, 3'd2, 4'd3, 4'd3, 16'hFFFF);
        expect_pixel(11'd367, 11'd208, 3'd6, 4'd3, 4'd2, 16'hFFFF);

        frame_ready = 1'b0;
        expect_pixel(11'd271, 11'd143, 3'd0, 4'd0, 4'd0, 16'h7BEF);

        data_req = 1'b0;
        expect_pixel(11'd271, 11'd143, 3'd0, 4'd0, 4'd0, 16'h0000);

        if (errors != 0) begin
            $display("HDMI_RENDER_TEST_FAIL errors=%0d", errors);
            $finish(1);
        end
        $display("HDMI_RENDER_TEST_PASS");
        $finish;
    end
endmodule
