`timescale 1ns/1ps

module tb_static_image_source;
    localparam IMAGE_W = 4;
    localparam IMAGE_H = 4;
    localparam TOTAL_PIXELS = IMAGE_W * IMAGE_H;
    localparam MEM_FILE0 = "fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sim_1/new/static_source_sel0.mem";
    localparam MEM_FILE1 = "fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sim_1/new/static_source_sel1.mem";
    localparam MEM_FILE2 = "fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sim_1/new/static_source_sel2.mem";

    reg clk;
    reg rst_n;
    reg [1:0] image_sel;

    wire out_valid;
    wire [7:0] out_gray;
    wire [7:0] out_x;
    wire [7:0] out_y;
    wire out_frame_start;
    wire out_line_start;
    wire frame_done;

    reg [7:0] expected_mem0 [0:TOTAL_PIXELS-1];
    reg [7:0] expected_mem1 [0:TOTAL_PIXELS-1];
    reg [7:0] expected_mem2 [0:TOTAL_PIXELS-1];
    integer pixel_count;
    integer line_start_count;
    integer frame_count;

    image_static_mem_source #(
        .IMAGE_W(IMAGE_W),
        .IMAGE_H(IMAGE_H),
        .MEM_FILE0(MEM_FILE0),
        .MEM_FILE1(MEM_FILE1),
        .MEM_FILE2(MEM_FILE2)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .image_sel(image_sel),
        .out_valid(out_valid),
        .out_gray(out_gray),
        .out_x(out_x),
        .out_y(out_y),
        .out_frame_start(out_frame_start),
        .out_line_start(out_line_start),
        .frame_done(frame_done)
    );

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    function [7:0] expected_gray;
        input [1:0] sel;
        input integer index;
        begin
            case (sel)
                2'd0: expected_gray = expected_mem0[index];
                2'd1: expected_gray = expected_mem1[index];
                2'd2: expected_gray = expected_mem2[index];
                default: expected_gray = expected_mem0[index];
            endcase
        end
    endfunction

    task run_selected_frame;
        input [1:0] sel;
        begin
            image_sel = sel;
            rst_n = 1'b0;
            pixel_count = 0;
            line_start_count = 0;
            repeat (8) @(posedge clk);
            rst_n = 1'b1;

            while (!frame_done) begin
                @(posedge clk);
            end
            @(posedge clk);

            if (pixel_count != TOTAL_PIXELS) begin
                $display("STATIC_SOURCE_PIXEL_COUNT_MISMATCH sel=%0d count=%0d expected=%0d",
                         sel, pixel_count, TOTAL_PIXELS);
                $finish(1);
            end
            if (line_start_count != IMAGE_H) begin
                $display("STATIC_SOURCE_LINE_COUNT_MISMATCH sel=%0d count=%0d expected=%0d",
                         sel, line_start_count, IMAGE_H);
                $finish(1);
            end
            frame_count = frame_count + 1;
        end
    endtask

    initial begin
        $readmemh(MEM_FILE0, expected_mem0);
        $readmemh(MEM_FILE1, expected_mem1);
        $readmemh(MEM_FILE2, expected_mem2);
        image_sel = 2'd0;
        pixel_count = 0;
        line_start_count = 0;
        frame_count = 0;

        run_selected_frame(2'd0);
        run_selected_frame(2'd1);
        run_selected_frame(2'd2);
        run_selected_frame(2'd3);

        if (frame_count != 4) begin
            $display("STATIC_SOURCE_FRAME_COUNT_MISMATCH count=%0d expected=4", frame_count);
            $finish(1);
        end
        $display("STATIC_SOURCE_TEST_PASS frames=%0d pixels_per_frame=%0d lines_per_frame=%0d",
                 frame_count, TOTAL_PIXELS, IMAGE_H);
        $finish;
    end

    always @(posedge clk) begin
        #1;
        if (rst_n && out_valid) begin
            if (out_x !== (pixel_count % IMAGE_W)) begin
                $display("STATIC_SOURCE_X_MISMATCH index=%0d x=%0d", pixel_count, out_x);
                $finish(1);
            end
            if (out_y !== (pixel_count / IMAGE_W)) begin
                $display("STATIC_SOURCE_Y_MISMATCH index=%0d y=%0d", pixel_count, out_y);
                $finish(1);
            end
            if (out_gray !== expected_gray(image_sel, pixel_count)) begin
                $display("STATIC_SOURCE_GRAY_MISMATCH sel=%0d index=%0d gray=%0h expected=%0h",
                         image_sel, pixel_count, out_gray, expected_gray(image_sel, pixel_count));
                $finish(1);
            end
            if (out_frame_start !== (pixel_count == 0)) begin
                $display("STATIC_SOURCE_FRAME_START_MISMATCH index=%0d", pixel_count);
                $finish(1);
            end
            if (out_line_start) begin
                line_start_count = line_start_count + 1;
            end
            if (out_line_start !== ((pixel_count % IMAGE_W) == 0)) begin
                $display("STATIC_SOURCE_LINE_START_MISMATCH index=%0d", pixel_count);
                $finish(1);
            end
            pixel_count = pixel_count + 1;
        end
    end

    initial begin
        #2000000;
        $display("STATIC_SOURCE_TEST_TIMEOUT frames=%0d pixels=%0d lines=%0d",
                 frame_count, pixel_count, line_start_count);
        $finish(1);
    end
endmodule
