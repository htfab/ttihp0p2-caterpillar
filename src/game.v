`default_nettype none

module game (
    input wire clk,
    input wire rst_n,
    input wire gate_200hz,
    input wire [4:0] input_event,
    input wire sound_wait,
    output reg [3:0] leds,
    output reg [4:0] display_value,
    output reg display_graphical,
    output reg [2:0] sound_mode
);

reg input_reset;
reg input_update;
reg input_erase;
reg [1:0] input_color;

wire solver_reset;
wire solver_update;
wire solver_erase;
wire [1:0] solver_color;

reg solver_active;

wire fsm_empty;
wire fsm_full;
wire [19:0] fsm_valid_bus;

reg [2:0] fsm_read_pos;
wire [1:0] fsm_read_val;
wire fsm_read_over;

rules fsm (
    .clk(clk),
    .reset(solver_active ? solver_reset : input_reset),
    .update(solver_active ? solver_update : input_update),
    .erase(solver_active ? solver_erase : input_erase),
    .color(solver_active ? solver_color : input_color),
    .read_pos(fsm_read_pos),
    .empty(fsm_empty),
    .full(fsm_full),
    .valid(fsm_valid_bus),
    .read_val(fsm_read_val),
    .read_over(fsm_read_over)
);

reg [4:0] current_level;
reg [1:0] solver_target;
reg solver_trigger_delayed;
reg solver_trigger;
wire solver_ready;
wire fsm_valid = fsm_valid_bus[current_level];

solver slv (
    .clk(clk),
    .rst_n(rst_n),
    .target(solver_target),
    .trigger(solver_trigger),
    .fsm_valid(fsm_valid),
    .fsm_reset(solver_reset),
    .fsm_update(solver_update),
    .fsm_color(solver_color),
    .ready(solver_ready)
);

assign solver_erase = 1'b0;

reg challenge_mode;
reg [3:0] challenge_num;
reg [3:0] state;
reg [3:0] next_state;
reg [7:0] counter;
reg [1:0] tune;
reg sound_on;

always @(posedge clk) begin
    input_reset <= 1'b0;
    input_update <= 1'b0;
    input_erase <= 1'b0;
    solver_trigger <= 1'b0;
    if (!rst_n) begin
        input_reset <= 1'b1;
        input_color <= 2'b0;
        solver_active <= 1'b0;
        fsm_read_pos <= 3'b0;
        current_level <= 5'b0;
        solver_target <= 2'b0;
        solver_trigger_delayed <= 1'b0;
        challenge_mode <= 1'b0;
        challenge_num <= 4'b0;
        state <= 4'd0;
        next_state <= 4'd0;
        counter <= 8'b0;
        leds <= 4'b0100;
        display_value <= 5'd1;
        display_graphical <= 1'b0;
        tune <= 2'd0;
        sound_on <= 1'b1;
        sound_mode <= 3'd0;
    end else begin
        if (state == 4'd0) begin
            // wait for player input
            leds <= {
                fsm_full,
                fsm_empty,
                fsm_valid && !fsm_empty,
                !fsm_valid && !fsm_empty
            };
            display_value <= current_level + 1;
            display_graphical <= 1'b0;
            sound_mode <= sound_on ? 3'd1 : 3'd0;
            case (input_event)
                5'b00000: begin // no button press
                    // do nothing
                end
                5'b00001: begin // red short
                    if (fsm_full) begin
                        sound_mode <= sound_on ? 3'd7 : 3'd0;
                        state <= 4'd7;
                        next_state <= 4'd0;
                    end else begin
                        input_color <= 2'b00;
                        input_update <= 1'b1;
                    end
                end
                5'b0010: begin // green short
                    if (fsm_full) begin
                        sound_mode <= sound_on ? 3'd7 : 3'd0;
                        state <= 4'd7;
                        next_state <= 4'd0;
                    end else begin
                        input_color <= 2'b01;
                        input_update <= 1'b1;
                    end
                end
                5'b00100: begin // blue short
                    if (fsm_full) begin
                        sound_mode <= sound_on ? 3'd7 : 3'd0;
                        state <= 4'd7;
                        next_state <= 4'd0;
                    end else begin
                        input_color <= 2'b10;
                        input_update <= 1'b1;
                    end
                end
                5'b01000: begin // yellow short
                    if (fsm_full) begin
                        sound_mode <= sound_on ? 3'd7 : 3'd0;
                        state <= 4'd7;
                        next_state <= 4'd0;
                    end else begin
                        input_color <= 2'b11;
                        input_update <= 1'b1;
                    end
                end
                5'b10001: begin // red long
                    input_reset <= 1'b1;
                end
                5'b10010: begin // green long
                    challenge_mode <= 1'b1;
                    challenge_num <= 4'b0;
                    display_value <= 5'b0;
                    display_graphical <= 1'b1;
                    solver_target <= 2'b10;
                    solver_trigger_delayed <= 1'b1;
                    state <= 4'd3;
                end
                5'b10100: begin // blue long
                    counter <= 8'b0;
                    state <= 4'd1;
                end
                5'b11000: begin // yellow long
                    if (fsm_empty) begin
                        sound_mode <= sound_on ? 3'd7 : 3'd0;
                        state <= 4'd7;
                        next_state <= 4'd0;
                    end else begin
                        input_erase <= 1'b1;
                    end
                end
                5'b00011: begin // red & green
                    current_level <= (current_level == 5'd0) ? 5'd19 : (current_level - 1);
                    input_reset <= 1'b1;
                end
                5'b00101: begin // red & blue
                    solver_target <= 2'b00;
                    solver_trigger_delayed <= 1'b1;
                    state <= 4'd3;
                end
                5'B00110: begin // green & blue
                    sound_on <= !sound_on;
                end
                5'b01010: begin // green & yellow
                    solver_target <= 2'b01;
                    solver_trigger_delayed <= 1'b1;
                    state <= 4'd3;
                end
                5'b01100: begin // blue & yellow
                    current_level <= (current_level == 5'd19) ? 5'd0 : (current_level + 1);
                    input_reset <= 1'b1;
                end
                default: begin // invalid input
                    sound_mode <= sound_on ? 3'd7 : 3'd0;
                    state <= 4'd7;
                    next_state <= 4'd0;
                end
            endcase
        end else if (state == 4'd1) begin
            // wait before showing sequence
            if (gate_200hz) begin
                leds <= 4'b0000;
                sound_mode <= sound_on ? 3'd2 : 3'd0;
                counter <= counter + 1;
                if (counter >= 8'd100) begin
                    fsm_read_pos <= 3'b0;
                    counter <= 8'd0;
                    state <= 4'd2;
                end
            end
        end else if (state == 4'd2) begin
            // show sequence
            if (gate_200hz) begin
                leds <= 4'b0000;
                if (fsm_read_over) begin
                    counter <= counter + 1;
                    if (counter >= 8'd125) begin
                        if (challenge_mode) begin
                            state <= 4'd4;
                        end else begin
                            state <= 4'd0;
                        end
                    end
                end else begin
                    counter <= counter + 1;
                    if (counter >= 8'd25) begin
                        case (fsm_read_val)
                            2'b00: leds <= 4'b0001;
                            2'b01: leds <= 4'b0010;
                            2'b10: leds <= 4'b0100;
                            2'b11: leds <= 4'b1000;
                        endcase
                    end
                    if (counter >= 8'd100) begin
                        fsm_read_pos <= fsm_read_pos + 1;
                        counter <= 8'd0;
                    end 
                end
            end 
        end else if (state == 4'd3) begin
            // find valid or invalid sequence
            sound_mode <= 3'd0;
            leds <= 4'b0000;
            if (solver_trigger_delayed) begin
                solver_trigger_delayed <= 1'b0;
                solver_trigger <= 1'b1;
                solver_active <= 1'b1;
            end else if (solver_ready) begin
                solver_active <= 1'b0;
                counter <= 8'b0;
                state <= 4'd1;
            end
        end else if (state == 4'd4) begin
            // wait for challenge answer
            display_value <= {1'b0, challenge_num};
            display_graphical <= 1'b1;
            sound_mode <= sound_on ? 3'd1 : 3'd0;
            leds <= 4'b0000;
            case (input_event)
                5'b00000: begin // no button press
                    // do nothing
                end
                5'b00001: begin // red short
                    if (fsm_valid) begin
                        state <= 4'd5;
                    end else begin
                        state <= 4'd6;
                    end
                end
                5'b0010: begin // green short
                    if (fsm_valid) begin
                        state <= 4'd6;
                    end else begin
                        state <= 4'd5;
                    end
                end
                5'b00100: begin // blue short
                    counter <= 8'b0;
                    state <= 4'd1;
                end
                5'b10100: begin // blue long
                    counter <= 8'b0;
                    state <= 4'd1;
                end
                5'b00011: begin // red & green
                    challenge_num <= (challenge_num == 4'd0) ? 4'd14 : (challenge_num - 1);
                end
                5'b00110: begin // green & blue
                    sound_on <= !sound_on;
                end
                5'b01001: begin // red & yellow
                    input_reset <= 1'b1;
                    challenge_mode <= 1'b0;
                    state <= 4'b0;
                end
                5'b01100: begin // blue & yellow
                    challenge_num <= (challenge_num == 4'd14) ? 4'd0 : (challenge_num + 1);
                end
                default: begin // invalid input
                    sound_mode <= 3'd0;
                    tune <= 2'd3;
                    state <= 4'd7;
                    next_state <= 4'd4;
                end
            endcase
        end else if (state == 4'd5) begin
            // fail challenge
            input_reset <= 1'b1;
            challenge_mode <= 1'b0;
            sound_mode <= 3'd0;
            tune <= 2'd0;
            leds <= 4'b0000;
            state <=  4'd7;
            next_state <= 4'd0;
        end else if (state == 4'd6) begin
            // pass challenge
            if (challenge_num == 4'd14) begin
                current_level <= (current_level == 5'd19) ? 5'd0 : (current_level + 1);
                input_reset <= 1'b1;
                challenge_mode <= 1'b0;
                sound_mode <= 3'd0;
                tune <= 2'd2;
                leds <= 4'b0000;
                state <= 4'd7;
                next_state <= 4'd0;
            end else begin
                challenge_num <= challenge_num + 1;
                display_value <= challenge_num + 1;
                solver_target <= 2'b10;
                solver_trigger_delayed <= 1'b1;
                sound_mode <= 3'd0;
                tune <= 2'd1;
                leds <= 4'b0000;
                state <= 4'd7;
                next_state <= 4'd3;
            end
        end else if (state == 4'd7) begin
            // play sound
            sound_mode <= 3'd0;
            leds <= 4'b0000;
            if (!sound_on) begin
                state <= next_state;
                next_state <= 4'd0;
            end else if (sound_wait) begin
                state <= 4'd8;
            end else begin
                sound_mode <= {1'b1, tune};
            end           
        end else if (state == 4'd8) begin
            // wait for sound to finish
            sound_mode <= 3'd0;
            leds <= 4'b0000;
            if (!sound_wait) state <= next_state;
        end
    end
end

endmodule
