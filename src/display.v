`default_nettype none

module display (
    input wire clk,
    input wire rst_n,
    input wire [4:0] value,
    input wire seg_invert,
    input wire graphical,
    output wire [6:0] segments,
    output wire [1:0] digit_sel
);

reg digit;
reg [6:0] segments_raw;
reg [1:0] digit_sel_raw;

assign segments = segments_raw ^ {7{seg_invert}};
assign digit_sel = digit_sel_raw ^ {2{seg_invert}};

always @(posedge clk) begin
    if (!rst_n) begin
        digit <= 1'b0;
        digit_sel_raw <= 2'b00;
        segments_raw <= 7'b0000000;
    end else begin
        if (digit) begin
            digit <= 1'b0;
            digit_sel_raw <= 2'b10;
            if (graphical) begin
                segments_raw <= {
                    value >= 5'd7,
                    value >= 5'd3,
                    value >= 5'd9,
                    value >= 5'd13,
                    value >= 5'd10,
                    value >= 5'd4,
                    value >= 5'd1
                };
            end else begin
                if (value == 5'd20) begin
                    segments_raw <= 7'b1011011;
                end else if (value >= 5'd10 && value < 5'd20) begin
                    segments_raw <= 7'b0000110;
                end else begin
                    segments_raw <= 7'b0000000;
                end
            end
        end else begin
            digit <= 1'b1;
            digit_sel_raw <= 2'b01;
            if (graphical) begin
                segments_raw <= {
                    value >= 5'd8,
                    value >= 5'd5,
                    value >= 5'd11,
                    value >= 5'd14,
                    value >= 5'd12,
                    value >= 5'd6,
                    value >= 5'd2
                };
            end else begin
                case (value)
                    5'd01, 5'd11: segments_raw <= 7'b0000110;
                    5'd02, 5'd12: segments_raw <= 7'b1011011;
                    5'd03, 5'd13: segments_raw <= 7'b1001111;
                    5'd04, 5'd14: segments_raw <= 7'b1100110;
                    5'd05, 5'd15: segments_raw <= 7'b1101101;
                    5'd06, 5'd16: segments_raw <= 7'b1111101;
                    5'd07, 5'd17: segments_raw <= 7'b0000111;
                    5'd08, 5'd18: segments_raw <= 7'b1111111;
                    5'd09, 5'd19: segments_raw <= 7'b1101111;
                    5'd10, 5'd20: segments_raw <= 7'b0111111;
                    default: segments_raw <= 7'b0000000;
                endcase
            end
        end
    end
end

endmodule
