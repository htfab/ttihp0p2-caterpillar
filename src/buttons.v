`default_nettype none

module buttons (
    input wire clk,
    input wire rst_n,
    input wire gate_200hz,
    input wire [3:0] raw_buttons,
    output reg [3:0] button_state,
    output reg [4:0] input_event
);

wire [3:0] sample_0ms = button_state ^ raw_buttons;
reg [3:0] sample_5ms;
reg [3:0] sample_10ms;
reg [3:0] sample_15ms;

wire [3:0] changes = sample_0ms & sample_5ms & sample_10ms & sample_15ms;
wire [3:0] new_button_state = button_state ^ changes;

reg [6:0] change_timer;
reg [3:0] current_event;
reg long_press;

always @(posedge clk) begin
    input_event <= 5'b0;
    if (!rst_n) begin
        sample_5ms <= 4'b0;
        sample_10ms <= 4'b0;
        sample_15ms <= 4'b0;
        button_state <= 4'b0;
        change_timer <= 7'b0;
        current_event <= 4'b0;
        long_press <= 1'b0;
    end else if (gate_200hz) begin
        sample_5ms <= sample_0ms;
        sample_10ms <= sample_5ms;
        sample_15ms <= sample_10ms;
        button_state <= new_button_state;
        if (changes != 4'b0000) begin
            change_timer <= 7'b0;
            if (new_button_state == 4'b0) begin
                input_event <= {long_press, current_event};
                current_event <= 4'b0;
                long_press <= 1'b0;
            end else begin
                current_event <= current_event | new_button_state;
            end
        end else begin
            if (button_state != 4'b0) begin
                if (change_timer == 7'd60) begin
                    long_press <= 1'b1;
                    if (long_press) begin
                        current_event <= 4'b1111;  // invalid input
                    end
                    change_timer <= ~7'b0;
                end
                if (change_timer != ~7'b0) begin
                    change_timer <= change_timer + 1;
                end
            end
        end
    end
end

endmodule
