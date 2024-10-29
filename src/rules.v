`default_nettype none

module rules (
    input clk,
    input reset,
    input update,
    input erase,
    input [1:0] color,
    input [2:0] read_pos,
    output empty,
    output full,
    output [19:0] valid,
    output [1:0] read_val,
    output read_over
);

reg [2:0] length;
reg [1:0] seq[6:0];
reg [2:0] color_count[3:0];
reg [2:0] num_blocks;
reg [2:0] len1_block_count;
reg [1:0] len2_block_count;
reg [1:0] len3_block_count;
reg [2:0] block_len[6:0];
reg [2:0] green_block_count;
reg [2:0] len1_color_count[3:0];
reg [1:0] len2_color_count[3:0];
reg [1:0] len3_color_count[3:0];

assign empty = length == 3'd0;
assign full = length == 3'd7;

assign read_val = seq[read_pos];
assign read_over = read_pos >= length;

wire [1:0] last_color = seq[length-1];

integer i;

always @(posedge clk) begin
    if (reset) begin
        length <= 3'd0;
        num_blocks <= 3'd0;
        len1_block_count <= 3'd0;
        len2_block_count <= 2'd0;
        len3_block_count <= 2'd0;
        green_block_count <= 3'd0;
        for (i=0; i<7; i=i+1) begin
            seq[i] <= 2'd0;
            block_len[i] <= 3'd0;
        end
        for (i=0; i<4; i=i+1) begin
            color_count[i] <= 3'd0;
            len1_color_count[i] <= 3'd0;
            len2_color_count[i] <= 2'd0;
            len3_color_count[i] <= 2'd0;
        end
    end else if (update && !full) begin
        length <= length + 3'd1;
        seq[length] <= color;
        color_count[color] <= color_count[color] + 3'd1;
        if (empty || color != seq[length-1]) begin
            num_blocks <= num_blocks + 3'd1;
            block_len[num_blocks] <= 3'd1;
            green_block_count <= green_block_count + {2'b00, color == 2'd1};
            len1_block_count <= len1_block_count + 3'd1;
            len1_color_count[color] <= len1_color_count[color] + 3'd1;
        end else if (block_len[num_blocks-1] == 3'd1) begin
            block_len[num_blocks-1] <= 3'd2;
            len1_block_count <= len1_block_count - 3'd1;
            len2_block_count <= len2_block_count + 2'd1;
            len1_color_count[color] <= len1_color_count[color] - 3'd1;
            len2_color_count[color] <= len2_color_count[color] + 2'd1;
        end else if (block_len[num_blocks-1] == 3'd2) begin
            block_len[num_blocks-1] <= 3'd3;
            len2_block_count <= len2_block_count - 2'd1;
            len3_block_count <= len3_block_count + 2'd1;
            len2_color_count[color] <= len2_color_count[color] - 2'd1;
            len3_color_count[color] <= len3_color_count[color] + 2'd1;
        end else if (block_len[num_blocks-1] == 3'd3) begin
            block_len[num_blocks-1] <= 3'd4;
            len3_block_count <= len3_block_count - 2'd1;
            len3_color_count[color] <= len3_color_count[color] - 2'd1;
        end else begin
            block_len[num_blocks-1] <= block_len[num_blocks-1] + 3'd1;
        end
    end else if (erase && !empty) begin
        length <= length - 3'd1;
        seq[length-1] <= 2'b00;
        color_count[last_color] <= color_count[last_color] - 3'd1;
        if (block_len[num_blocks-1] == 3'd1) begin
            num_blocks <= num_blocks - 3'd1;
            block_len[num_blocks-1] <= 3'd0;
            green_block_count <= green_block_count - {2'b00, last_color == 2'd1};
            len1_block_count <= len1_block_count - 3'd1;
            len1_color_count[last_color] <= len1_color_count[last_color] - 3'd1;
        end else if(block_len[num_blocks-1] == 3'd2) begin
            block_len[num_blocks-1] <= 3'd1;
            len1_block_count <= len1_block_count + 3'd1;
            len1_color_count[last_color] <= len1_color_count[last_color] + 3'd1;
            len2_block_count <= len2_block_count - 2'd1;
            len2_color_count[last_color] <= len2_color_count[last_color] - 2'd1;
        end else if(block_len[num_blocks-1] == 3'd3) begin
            block_len[num_blocks-1] <= 3'd2;
            len2_block_count <= len2_block_count + 2'd1;
            len2_color_count[last_color] <= len2_color_count[last_color] + 2'd1;
            len3_block_count <= len3_block_count - 2'd1;
            len3_color_count[last_color] <= len3_color_count[last_color] - 2'd1;
        end else if(block_len[num_blocks-1] == 3'd4) begin
            block_len[num_blocks-1] <= 3'd3;
            len3_block_count <= len3_block_count + 2'd1;
            len3_color_count[last_color] <= len3_color_count[last_color] + 2'd1;
        end else begin
            block_len[num_blocks-1] <= block_len[num_blocks-1] - 3'd1;
        end
    end
end


wire [2:0] min_block_len_01 = (num_blocks <= 3'd1 || block_len[0] <= block_len[1]) ? block_len[0] : block_len[1];
wire [2:0] min_block_len_23 = (num_blocks <= 3'd3 || block_len[2] <= block_len[3]) ? block_len[2] : block_len[3];
wire [2:0] min_block_len_45 = (num_blocks <= 3'd5 || block_len[4] <= block_len[5]) ? block_len[4] : block_len[5];
wire [2:0] min_block_len_0123 = (num_blocks <= 3'd2 || min_block_len_01 <= min_block_len_23) ? min_block_len_01 : min_block_len_23;
wire [2:0] min_block_len_456 = (num_blocks <= 3'd6 || min_block_len_45 <= block_len[6]) ? min_block_len_45 : block_len[6];
wire [2:0] min_block_len = (num_blocks <= 3'd4 || min_block_len_0123 <= min_block_len_456) ? min_block_len_0123 : min_block_len_456;

wire [2:0] max_block_len_01 = (num_blocks <= 3'd1 || block_len[0] >= block_len[1]) ? block_len[0] : block_len[1];
wire [2:0] max_block_len_23 = (num_blocks <= 3'd3 || block_len[2] >= block_len[3]) ? block_len[2] : block_len[3];
wire [2:0] max_block_len_45 = (num_blocks <= 3'd5 || block_len[4] >= block_len[5]) ? block_len[4] : block_len[5];
wire [2:0] max_block_len_0123 = (num_blocks <= 3'd2 || max_block_len_01 >= max_block_len_23) ? max_block_len_01 : max_block_len_23;
wire [2:0] max_block_len_456 = (num_blocks <= 3'd6 || max_block_len_45 >= block_len[6]) ? max_block_len_45 : block_len[6];
wire [2:0] max_block_len = (num_blocks <= 3'd4 || max_block_len_0123 >= max_block_len_456) ? max_block_len_0123 : max_block_len_456;

assign valid[0] = (length <= 3'd1 || seq[0] == seq[length-1]) &&
                  (length <= 3'd3 || seq[1] == seq[length-2]) &&
                  (length <= 3'd5 || seq[2] == seq[length-3]);
assign valid[1] = seq[0] != seq[length-1];
assign valid[2] = color_count[1] != 3'd0;
assign valid[3] = (color_count[0] == 3'd0) || (color_count[3] == 3'd0);
assign valid[4] = ({1'b0, color_count[0] != 3'd0} + {1'b0, color_count[1] != 3'd0} +
                   {1'b0, color_count[2] != 3'd0} + {1'b0, color_count[3] != 3'd0}) == 2'd3;
assign valid[5] = color_count[0] == 3'd3;
assign valid[6] = color_count[3] > color_count[2];
assign valid[7] = (length <= 3'd1 || seq[0] == 2'd1 || seq[0] == 2'd3 || seq[1] == 2'd1 || seq[1] == 2'd3 || seq[0] == seq[1]) &&
                  (length <= 3'd2 || seq[1] == 2'd1 || seq[1] == 2'd3 || seq[2] == 2'd1 || seq[2] == 2'd3 || seq[1] == seq[2]) &&
                  (length <= 3'd3 || seq[2] == 2'd1 || seq[2] == 2'd3 || seq[3] == 2'd1 || seq[3] == 2'd3 || seq[2] == seq[3]) &&
                  (length <= 3'd4 || seq[3] == 2'd1 || seq[3] == 2'd3 || seq[4] == 2'd1 || seq[4] == 2'd3 || seq[3] == seq[4]) &&
                  (length <= 3'd5 || seq[4] == 2'd1 || seq[4] == 2'd3 || seq[5] == 2'd1 || seq[5] == 2'd3 || seq[4] == seq[5]) &&
                  (length <= 3'd6 || seq[5] == 2'd1 || seq[5] == 2'd3 || seq[6] == 2'd1 || seq[6] == 2'd3 || seq[5] == seq[6]);
assign valid[8] = color_count[0] + color_count[3] == 3'd5;
assign valid[9] = len1_block_count == 3'd0 && len2_block_count != 2'd0;
assign valid[10] = num_blocks == 3'd4;
assign valid[11] = green_block_count == 3'd2;
assign valid[12] = len2_block_count == 2'd2;
assign valid[13] = max_block_len == 3'd2;
assign valid[14] = ((num_blocks <= 1 || block_len[0] <= block_len[1]) && (num_blocks <= 2 || block_len[1] <= block_len[2]) &&
                    (num_blocks <= 3 || block_len[2] <= block_len[3]) && (num_blocks <= 4 || block_len[3] <= block_len[4]) &&
                    (num_blocks <= 5 || block_len[4] <= block_len[5])) ||
                   ((num_blocks <= 1 || block_len[0] >= block_len[1]) && (num_blocks <= 2 || block_len[1] >= block_len[2]) &&
                    (num_blocks <= 3 || block_len[2] >= block_len[3]) && (num_blocks <= 4 || block_len[3] >= block_len[4]) &&
                    (num_blocks <= 5 || block_len[4] >= block_len[5]));
assign valid[15] = ((color_count[1] == color_count[0] || color_count[1] == 3'b0 || color_count[0] == 3'b0) &&
                    (color_count[2] == color_count[0] || color_count[2] == 3'b0 || color_count[0] == 3'b0) &&
                    (color_count[3] == color_count[0] || color_count[3] == 3'b0 || color_count[0] == 3'b0) &&
                    (color_count[2] == color_count[1] || color_count[2] == 3'b0 || color_count[1] == 3'b0) &&
                    (color_count[3] == color_count[1] || color_count[3] == 3'b0 || color_count[1] == 3'b0) &&
                    (color_count[3] == color_count[2] || color_count[3] == 3'b0 || color_count[2] == 3'b0));
assign valid[16] = (max_block_len == 3'd1 && len1_block_count == 3'd1) || (max_block_len == 3'd2 && len2_block_count == 2'd1) ||
                   (max_block_len == 3'd3 && len3_block_count == 2'd1) || max_block_len >= 3'd4;
assign valid[17] = ({1'b0, len1_color_count[0] != 3'd0} + {1'b0, len1_color_count[1] != 3'd0} + {1'b0, len1_color_count[2] != 3'd0} + {1'b0, len1_color_count[3] != 3'd0} +
                    {1'b0, len2_color_count[0] != 2'd0} + {1'b0, len2_color_count[1] != 2'd0} + {1'b0, len2_color_count[2] != 2'd0} + {1'b0, len2_color_count[3] != 2'd0} +
                    {1'b0, len3_color_count[0] != 2'd0} + {1'b0, len3_color_count[1] != 2'd0} + {1'b0, len3_color_count[2] != 2'd0} + {1'b0, len3_color_count[3] != 2'd0} +
                    {1'b0, max_block_len >= 3'd4}) == 2'd3;
assign valid[18] = (min_block_len == 3'd1 && len1_block_count == 3'd1) || (min_block_len == 3'd2 && len2_block_count == 2'd1) ||
                   (min_block_len == 3'd3 && len3_block_count == 2'd1) || min_block_len >= 3'd4;
assign valid[19] = (len1_color_count[0] <= 3'd1 && len1_color_count[1] <= 3'd1 && len1_color_count[2] <= 3'd1 && len1_color_count[3] <= 3'd1 &&
                    len2_color_count[0] <= 2'd1 && len2_color_count[1] <= 2'd1 && len2_color_count[2] <= 2'd1 && len2_color_count[3] <= 2'd1 &&
                    len3_color_count[0] <= 2'd1 && len3_color_count[1] <= 2'd1 && len3_color_count[2] <= 2'd1 && len3_color_count[3] <= 2'd1);

endmodule

