`timescale 1ns/1ps

module tb_cordic_tensor_direction;
    reg clk;
    reg rst_n;
    reg in_valid;
    reg in_active;
    reg [4:0] in_block_x;
    reg [4:0] in_block_y;
    reg signed [31:0] tensor_x;
    reg signed [31:0] tensor_y;

    wire block_valid;
    wire block_active;
    wire [4:0] block_x;
    wire [4:0] block_y;
    wire [3:0] block_dir;

    integer seen_count;
    reg last_active;
    reg [4:0] last_x;
    reg [4:0] last_y;
    reg [3:0] last_dir;
    reg prev_block_valid;

    cordic_tensor_direction dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_active(in_active),
        .in_block_x(in_block_x),
        .in_block_y(in_block_y),
        .tensor_x(tensor_x),
        .tensor_y(tensor_y),
        .block_valid(block_valid),
        .block_active(block_active),
        .block_x(block_x),
        .block_y(block_y),
        .block_dir(block_dir)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always @(posedge clk) begin
        #1;
        if (rst_n && block_valid && !prev_block_valid) begin
            seen_count = seen_count + 1;
            last_active = block_active;
            last_x = block_x;
            last_y = block_y;
            last_dir = block_dir;
        end
        prev_block_valid = rst_n && block_valid;
    end

    task send_tensor;
        input [4:0] bx;
        input [4:0] by;
        input signed [31:0] tx;
        input signed [31:0] ty;
        input active;
        begin
            in_valid = 1'b1;
            in_active = active;
            in_block_x = bx;
            in_block_y = by;
            tensor_x = tx;
            tensor_y = ty;
            @(posedge clk);
            #1;
            in_valid = 1'b0;
            in_active = 1'b0;
        end
    endtask

    task wait_seen;
        input integer expected_count;
        integer guard;
        begin
            guard = 0;
            while (seen_count < expected_count && guard < 40) begin
                @(posedge clk);
                #1;
                guard = guard + 1;
            end
            if (seen_count != expected_count) begin
                $display("CORDIC_TENSOR_TIMEOUT seen=%0d expected=%0d", seen_count, expected_count);
                $finish(1);
            end
        end
    endtask

    initial begin
        rst_n = 1'b0;
        in_valid = 1'b0;
        in_active = 1'b0;
        in_block_x = 5'd0;
        in_block_y = 5'd0;
        tensor_x = 32'sd0;
        tensor_y = 32'sd0;
        seen_count = 0;
        prev_block_valid = 1'b0;
        repeat (4) @(posedge clk);
        rst_n = 1'b1;

        // Vertical Sobel normal means the fingerprint ridge itself is horizontal.
        send_tensor(5'd3, 5'd4, -32'sd10000, 32'sd0, 1'b1);
        wait_seen(1);
        if (last_x !== 5'd3 || last_y !== 5'd4 || last_active !== 1'b1 || last_dir !== 4'd0) begin
            $display("CORDIC_TENSOR_HORIZONTAL_RIDGE_FAIL x=%0d y=%0d active=%0d dir=%0d",
                     last_x, last_y, last_active, last_dir);
            $finish(1);
        end

        // Horizontal Sobel normal means the fingerprint ridge itself is vertical.
        send_tensor(5'd5, 5'd6, 32'sd10000, 32'sd0, 1'b1);
        wait_seen(2);
        if (last_x !== 5'd5 || last_y !== 5'd6 || last_active !== 1'b1 || last_dir !== 4'd8) begin
            $display("CORDIC_TENSOR_VERTICAL_RIDGE_FAIL x=%0d y=%0d active=%0d dir=%0d",
                     last_x, last_y, last_active, last_dir);
            $finish(1);
        end

        // Oblique tensor bins need one extra 90-degree display rotation to
        // align with the visible fingerprint ridge direction in the HDMI view.
        send_tensor(5'd7, 5'd8, 32'sd0, -32'sd10000, 1'b1);
        wait_seen(3);
        if (last_x !== 5'd7 || last_y !== 5'd8 || last_active !== 1'b1 || last_dir !== 4'd12) begin
            $display("CORDIC_TENSOR_OBLIQUE_POSITIVE_FAIL x=%0d y=%0d active=%0d dir=%0d",
                     last_x, last_y, last_active, last_dir);
            $finish(1);
        end

        send_tensor(5'd9, 5'd10, 32'sd0, 32'sd10000, 1'b1);
        wait_seen(4);
        if (last_x !== 5'd9 || last_y !== 5'd10 || last_active !== 1'b1 || last_dir !== 4'd4) begin
            $display("CORDIC_TENSOR_OBLIQUE_NEGATIVE_FAIL x=%0d y=%0d active=%0d dir=%0d",
                     last_x, last_y, last_active, last_dir);
            $finish(1);
        end

        send_tensor(5'd11, 5'd12, 32'sd10000, 32'sd0, 1'b0);
        wait_seen(5);
        if (last_x !== 5'd11 || last_y !== 5'd12 || last_active !== 1'b0) begin
            $display("CORDIC_TENSOR_INACTIVE_FAIL x=%0d y=%0d active=%0d",
                     last_x, last_y, last_active);
            $finish(1);
        end

        $display("CORDIC_TENSOR_DIRECTION_TEST_PASS");
        $finish;
    end
endmodule
