`timescale 1ns/1ps

module tmds_encoder (
    input  wire       pixel_clk,
    input  wire       rst,
    input  wire [7:0] data_in,
    input  wire       c0,
    input  wire       c1,
    input  wire       de,
    output reg  [9:0] tmds_out
);
    parameter [9:0] CTRL_00 = 10'b1101010100;
    parameter [9:0] CTRL_01 = 10'b0010101011;
    parameter [9:0] CTRL_10 = 10'b0101010100;
    parameter [9:0] CTRL_11 = 10'b1010101011;

    reg [3:0] ones_data;
    reg [8:0] q_m;
    reg [3:0] ones_qm;
    reg signed [4:0] balance;
    integer i;

    always @(*) begin
        ones_data = data_in[0] + data_in[1] + data_in[2] + data_in[3] +
                    data_in[4] + data_in[5] + data_in[6] + data_in[7];
        q_m[0] = data_in[0];
        if ((ones_data > 4'd4) || ((ones_data == 4'd4) && (data_in[0] == 1'b0))) begin
            for (i = 1; i < 8; i = i + 1) begin
                q_m[i] = q_m[i - 1] ~^ data_in[i];
            end
            q_m[8] = 1'b0;
        end else begin
            for (i = 1; i < 8; i = i + 1) begin
                q_m[i] = q_m[i - 1] ^ data_in[i];
            end
            q_m[8] = 1'b1;
        end
        ones_qm = q_m[0] + q_m[1] + q_m[2] + q_m[3] +
                  q_m[4] + q_m[5] + q_m[6] + q_m[7];
    end

    always @(posedge pixel_clk or posedge rst) begin
        if (rst) begin
            tmds_out <= 10'd0;
            balance <= 5'sd0;
        end else if (!de) begin
            case ({c1, c0})
                2'b00: tmds_out <= CTRL_00;
                2'b01: tmds_out <= CTRL_01;
                2'b10: tmds_out <= CTRL_10;
                default: tmds_out <= CTRL_11;
            endcase
            balance <= 5'sd0;
        end else if ((balance == 5'sd0) || (ones_qm == 4'd4)) begin
            tmds_out <= {~q_m[8], q_m[8], q_m[8] ? q_m[7:0] : ~q_m[7:0]};
            balance <= q_m[8] ? (balance + $signed({1'b0, ones_qm}) - 5'sd4)
                              : (balance + 5'sd4 - $signed({1'b0, ones_qm}));
        end else if ((balance[4] == 1'b0 && ones_qm > 4'd4) ||
                     (balance[4] == 1'b1 && ones_qm < 4'd4)) begin
            tmds_out <= {1'b1, q_m[8], ~q_m[7:0]};
            balance <= balance + $signed({1'b0, q_m[8], 1'b0}) + 5'sd4 - $signed({1'b0, ones_qm});
        end else begin
            tmds_out <= {1'b0, q_m[8], q_m[7:0]};
            balance <= balance - $signed({1'b0, ~q_m[8], 1'b0}) + $signed({1'b0, ones_qm}) - 5'sd4;
        end
    end
endmodule
