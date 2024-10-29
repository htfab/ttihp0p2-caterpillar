`default_nettype none

module solver (
    input wire clk,
    input wire rst_n,
    input wire [1:0] target,
    input wire trigger,
    input wire fsm_valid,
    output reg fsm_reset,
    output reg fsm_update,
    output reg [1:0] fsm_color,
    output reg ready
);

reg [20:0] lfsr;

always @(posedge clk) begin
    if (!rst_n) begin
        lfsr <= -1;
    end else begin
        lfsr <= {lfsr[17:0], lfsr[20]^lfsr[18], lfsr[19]^lfsr[17], lfsr[18]^lfsr[16]};
    end
end

reg saved_target;
reg [1:0] state;
reg [2:0] length;
reg [2:0] pos;
reg [2:0] retries;

always @(posedge clk) begin
    fsm_reset <= 1'b0;
    fsm_update <= 1'b0;
    fsm_color <= 2'b0;
    ready <= 1'b0;
    if (!rst_n) begin
        saved_target <= 1'b0;
        state <= 2'b0;
        length <= 3'b0;
        pos <= 3'b0;
        retries <= 3'b0;
        fsm_reset <= 1'b1;
    end else if (trigger) begin
        state <= 2'd1;
        if (target[1]) begin
            saved_target <= lfsr[0];
        end else begin
            saved_target <= target[0];
        end
    end else if (state == 2'd1) begin
        if (lfsr[2:0] >= 3'd1 && lfsr[2:0] <= 3'd6) begin
            state <= 2'd2;
            length <= lfsr[2:0];
            pos <= lfsr[2:0];
            retries <= 3'd7;
            fsm_reset <= 1'b1;
        end
    end else if (state == 2'd2) begin
        if (pos != 3'd0) begin
            fsm_color <= lfsr[1:0];
            fsm_update <= 1'b1;
            pos <= pos - 1;
        end else begin
            state <= 2'd3;
        end
    end else if (state == 2'd3) begin
        if (fsm_valid == saved_target) begin
            state <= 2'd0;
            ready <= 1'b1;
        end else if (retries == 3'd0) begin
            if (length < 3'd6) begin
                length <= length + 1;
                pos <= length + 1;
            end else begin
                pos <= length;
            end
            retries <= 3'd7;
            state <= 2'd2;
            fsm_reset <= 1'b1;
        end else begin
            pos <= length;
            retries <= retries - 1;
            state <= 2'd2;
            fsm_reset <= 1'b1;
        end
    end
end

endmodule
