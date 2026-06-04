`timescale 1ns/1ps

module tb_tensor_field_smoother;
    reg clk;
    reg rst_n;
    reg in_valid;
    reg in_active;
    reg [5:0] in_block_x;
    reg [5:0] in_block_y;
    reg signed [31:0] in_tensor_x;
    reg signed [31:0] in_tensor_y;

    wire out_valid;
    wire out_active;
    wire [5:0] out_block_x;
    wire [5:0] out_block_y;
    wire signed [31:0] out_tensor_x;
    wire signed [31:0] out_tensor_y;

    integer errors;
    integer seen_count;
    integer phase;
    integer x;
    integer y;

    tensor_field_smoother #(
        .MIN_NEIGHBOR_ACTIVE(4),
        .MIN_SMOOTH_STRENGTH(512)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_active(in_active),
        .in_block_x(in_block_x),
        .in_block_y(in_block_y),
        .in_tensor_x(in_tensor_x),
        .in_tensor_y(in_tensor_y),
        .out_valid(out_valid),
        .out_active(out_active),
        .out_block_x(out_block_x),
        .out_block_y(out_block_y),
        .out_tensor_x(out_tensor_x),
        .out_tensor_y(out_tensor_y)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task reset_dut;
        begin
            rst_n = 1'b0;
            in_valid = 1'b0;
            in_active = 1'b0;
            in_block_x = 6'd0;
            in_block_y = 6'd0;
            in_tensor_x = 32'sd0;
            in_tensor_y = 32'sd0;
            seen_count = 0;
            repeat (4) @(posedge clk);
            rst_n = 1'b1;
            @(posedge clk);
            #1;
        end
    endtask

    task send_block;
        input [5:0] bx;
        input [5:0] by;
        input signed [31:0] tx;
        input signed [31:0] ty;
        input active;
        begin
            in_valid = 1'b1;
            in_active = active;
            in_block_x = bx;
            in_block_y = by;
            in_tensor_x = tx;
            in_tensor_y = ty;
            @(posedge clk);
            #1;
            in_valid = 1'b0;
            in_active = 1'b0;
            in_tensor_x = 32'sd0;
            in_tensor_y = 32'sd0;
            @(posedge clk);
            #1;
        end
    endtask

    task expect_output;
        input [5:0] exp_x;
        input [5:0] exp_y;
        input signed [31:0] exp_tx;
        input signed [31:0] exp_ty;
        input exp_active;
        begin
            if (out_block_x !== exp_x || out_block_y !== exp_y ||
                out_tensor_x !== exp_tx || out_tensor_y !== exp_ty ||
                out_active !== exp_active) begin
                $display("SMOOTHER_MISMATCH phase=%0d seen=%0d x=%0d/%0d y=%0d/%0d tx=%0d/%0d ty=%0d/%0d active=%0d/%0d",
                         phase, seen_count, out_block_x, exp_x, out_block_y, exp_y,
                         out_tensor_x, exp_tx, out_tensor_y, exp_ty, out_active, exp_active);
                errors = errors + 1;
            end
        end
    endtask

    always @(posedge clk) begin
        #1;
        if (rst_n && out_valid) begin
            if (phase == 0) begin
                case (seen_count)
                    0: expect_output(6'd1, 6'd1, 32'sd999,  32'sd45, 1'b1);
                    1: expect_output(6'd2, 6'd1, 32'sd1008, 32'sd45, 1'b1);
                    2: expect_output(6'd1, 6'd2, 32'sd1089, 32'sd45, 1'b1);
                    3: expect_output(6'd2, 6'd2, 32'sd1098, 32'sd45, 1'b1);
                    default: begin
                        $display("SMOOTHER_UNEXPECTED_EXTRA_OUTPUT phase=%0d seen=%0d", phase, seen_count);
                        errors = errors + 1;
                    end
                endcase
            end else begin
                case (seen_count)
                    0: expect_output(6'd1, 6'd1, 32'sd3000, 32'sd0, 1'b0);
                    default: begin
                        $display("SMOOTHER_UNEXPECTED_EXTRA_OUTPUT phase=%0d seen=%0d", phase, seen_count);
                        errors = errors + 1;
                    end
                endcase
            end
            seen_count = seen_count + 1;
        end
    end

    initial begin
        errors = 0;
        phase = 0;
        reset_dut();

        for (y = 0; y < 4; y = y + 1) begin
            for (x = 0; x < 4; x = x + 1) begin
                send_block(x[5:0], y[5:0], 32'sd100 + x + (10 * y), 32'sd5, 1'b1);
            end
        end
        repeat (4) @(posedge clk);
        if (seen_count != 4) begin
            $display("SMOOTHER_ALL_ACTIVE_COUNT_FAIL seen=%0d expected=4", seen_count);
            errors = errors + 1;
        end

        phase = 1;
        reset_dut();
        for (y = 0; y < 3; y = y + 1) begin
            for (x = 0; x < 3; x = x + 1) begin
                send_block(x[5:0], y[5:0], 32'sd1000, 32'sd0, (x == 0 && y < 3));
            end
        end
        repeat (4) @(posedge clk);
        if (seen_count != 1) begin
            $display("SMOOTHER_LOW_CONF_COUNT_FAIL seen=%0d expected=1", seen_count);
            errors = errors + 1;
        end

        if (errors != 0) begin
            $display("TENSOR_SMOOTHER_TEST_FAIL errors=%0d", errors);
            $finish(1);
        end
        $display("TENSOR_SMOOTHER_TEST_PASS");
        $finish;
    end
endmodule
