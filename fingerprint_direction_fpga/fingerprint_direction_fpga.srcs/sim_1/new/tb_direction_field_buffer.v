`timescale 1ns/1ps

module tb_direction_field_buffer;
    reg clk;
    reg rst_n;
    reg block_valid;
    reg block_active;
    reg [5:0] block_x;
    reg [5:0] block_y;
    reg [3:0] block_dir;
    reg [5:0] read_block_x;
    reg [5:0] read_block_y;
    wire [3:0] read_block_dir;
    wire read_block_active;
    wire frame_ready;

    integer errors;

    direction_field_buffer dut (
        .clk(clk),
        .rst_n(rst_n),
        .block_valid(block_valid),
        .block_active(block_active),
        .block_x(block_x),
        .block_y(block_y),
        .block_dir(block_dir),
        .read_block_x(read_block_x),
        .read_block_y(read_block_y),
        .read_block_dir(read_block_dir),
        .read_block_active(read_block_active),
        .frame_ready(frame_ready)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task write_block;
        input [5:0] x;
        input [5:0] y;
        input [3:0] dir;
        input       active;
        begin
            @(posedge clk);
            block_valid <= 1'b1;
            block_active <= active;
            block_x <= x;
            block_y <= y;
            block_dir <= dir;
            @(posedge clk);
            block_valid <= 1'b0;
        end
    endtask

    initial begin
        errors = 0;
        rst_n = 1'b0;
        block_valid = 1'b0;
        block_active = 1'b0;
        block_x = 6'd0;
        block_y = 6'd0;
        block_dir = 4'd0;
        read_block_x = 6'd0;
        read_block_y = 6'd0;
        repeat (4) @(posedge clk);
        rst_n = 1'b1;

        write_block(6'd3, 6'd4, 4'd13, 1'b1);
        read_block_x = 6'd3;
        read_block_y = 6'd4;
        #1;
        if (read_block_dir !== 4'd13 || read_block_active !== 1'b1 || frame_ready !== 1'b0) begin
            $display("BUFFER_SINGLE_WRITE_FAIL dir=%0d active=%0d ready=%0d",
                     read_block_dir, read_block_active, frame_ready);
            errors = errors + 1;
        end

        write_block(6'd63, 6'd63, 4'd10, 1'b0);
        read_block_x = 6'd63;
        read_block_y = 6'd63;
        #1;
        if (read_block_dir !== 4'd10 || read_block_active !== 1'b0 || frame_ready !== 1'b1) begin
            $display("BUFFER_FRAME_READY_FAIL dir=%0d active=%0d ready=%0d",
                     read_block_dir, read_block_active, frame_ready);
            errors = errors + 1;
        end

        rst_n = 1'b0;
        @(posedge clk);
        #1;
        if (read_block_dir !== 4'd0 || read_block_active !== 1'b0 || frame_ready !== 1'b0) begin
            $display("BUFFER_RESET_FAIL dir=%0d active=%0d ready=%0d",
                     read_block_dir, read_block_active, frame_ready);
            errors = errors + 1;
        end

        if (errors != 0) begin
            $display("DIRECTION_BUFFER_TEST_FAIL errors=%0d", errors);
            $finish(1);
        end
        $display("DIRECTION_BUFFER_TEST_PASS");
        $finish;
    end
endmodule
