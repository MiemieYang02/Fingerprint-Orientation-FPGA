`timescale 1ns/1ps

module tb_direction_quantizer;
    reg clk;
    reg rst_n;
    reg in_valid;
    reg [7:0] in_x;
    reg [7:0] in_y;
    reg [7:0] angle_code;

    wire out_valid;
    wire [7:0] out_x;
    wire [7:0] out_y;
    wire [2:0] dir_bin;

    integer errors;

    direction_quantizer dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_x(in_x),
        .in_y(in_y),
        .angle_code(angle_code),
        .out_valid(out_valid),
        .out_x(out_x),
        .out_y(out_y),
        .dir_bin(dir_bin)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task expect_dir;
        input [7:0] gradient_angle;
        input [2:0] expected_dir;
        begin
            in_valid = 1'b1;
            angle_code = gradient_angle;
            @(posedge clk);
            #1;
            in_valid = 1'b0;
            if (!out_valid || dir_bin !== expected_dir) begin
                $display("QUANTIZER_MISMATCH gradient_angle=%0d dir=%0d expected=%0d out_valid=%0d",
                         gradient_angle, dir_bin, expected_dir, out_valid);
                errors = errors + 1;
            end
            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        errors = 0;
        rst_n = 1'b0;
        in_valid = 1'b0;
        in_x = 8'd7;
        in_y = 8'd9;
        angle_code = 8'd0;
        repeat (4) @(posedge clk);
        rst_n = 1'b1;

        // Fingerprint orientation is ridge tangent, not Sobel gradient normal.
        // angle_code uses 256 units per 180 degrees, so +128 is a 90-degree turn.
        expect_dir(8'd0,   3'd4); // horizontal gradient -> vertical ridge
        expect_dir(8'd64,  3'd6); // 45-degree gradient -> 135-degree ridge
        expect_dir(8'd128, 3'd0); // vertical gradient -> horizontal ridge
        expect_dir(8'd192, 3'd2); // 135-degree gradient -> 45-degree ridge

        if (errors != 0) begin
            $display("DIRECTION_QUANTIZER_TEST_FAIL errors=%0d", errors);
            $finish(1);
        end
        $display("DIRECTION_QUANTIZER_TEST_PASS");
        $finish;
    end
endmodule
