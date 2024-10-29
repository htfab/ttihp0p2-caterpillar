`default_nettype none

module sound (
    input wire clk,
    input wire rst_n,
    input wire gate_200hz,
    input wire [2:0] sound_mode,
    input wire [3:0] buttons,
    input wire [3:0] leds,
    output reg sound,
    output wire sound_wait
);

// calculated for 50kHz clock
wire [8:0] NOTE_TIMING[11:0];
assign NOTE_TIMING[0] = 9'd382; // C3
assign NOTE_TIMING[1] = 9'd361; // C#3
assign NOTE_TIMING[2] = 9'd341; // D3
assign NOTE_TIMING[3] = 9'd321; // D#3
assign NOTE_TIMING[4] = 9'd303; // E3
assign NOTE_TIMING[5] = 9'd286; // F3
assign NOTE_TIMING[6] = 9'd270; // F#3
assign NOTE_TIMING[7] = 9'd255; // G3
assign NOTE_TIMING[8] = 9'd241; // G#3
assign NOTE_TIMING[9] = 9'd227; // A3
assign NOTE_TIMING[10] = 9'd215; // A#3
assign NOTE_TIMING[11] = 9'd202; // B3

(* mem2reg *) reg [5:0] chord [3:0];
reg [1:0] note_sel;
reg [1:0] next_note_sel;
reg [8:0] note_timing;
reg [8:0] next_note_timing;
reg [8:0] counter;

always @(posedge clk) begin
    if (!rst_n) begin
        note_sel <= 2'd0;
        note_timing <= 9'd0;
        counter <= 9'd0;
        sound <= 1'b0;
    end else begin
        counter <= counter + 1;
        if (counter >= note_timing) begin
            sound <= 1'b0;
            counter <= 9'd1;
            note_sel <= next_note_sel;
            note_timing <= next_note_timing;
        end else if (counter >= note_timing >> 1) begin
            sound <= 1'b1;
        end
    end
end

reg [1:0] pre_next_note_sel;
always_comb begin
    case (note_sel)
        2'd0: pre_next_note_sel = chord[1] != 0 ? 2'd1 :
                                  chord[2] != 0 ? 2'd2 :
                                  chord[3] != 0 ? 2'd3 : 2'd0;
        2'd1: pre_next_note_sel = chord[2] != 0 ? 2'd2 :
                                  chord[3] != 0 ? 2'd3 :
                                  chord[0] != 0 ? 2'd0 :
                                  chord[1] != 0 ? 2'd1 : 2'd0;
        2'd2: pre_next_note_sel = chord[3] != 0 ? 2'd3 :
                                  chord[0] != 0 ? 2'd0 :
                                  chord[1] != 0 ? 2'd1 :
                                  chord[2] != 0 ? 2'd2 : 2'd0;
        2'd3: pre_next_note_sel = chord[0] != 0 ? 2'd0 :
                                  chord[1] != 0 ? 2'd1 :
                                  chord[2] != 0 ? 2'd2 :
                                  chord[3] != 0 ? 2'd3 : 2'd0;
    endcase
end

wire [1:0] pre_next_note_octave; // 0 = silence, 1-3 = C3 to B5
wire [3:0] pre_next_note_class;
assign {pre_next_note_octave, pre_next_note_class} = chord[pre_next_note_sel];
wire [8:0] pre_next_note_class_timing = NOTE_TIMING[pre_next_note_class];

always @(posedge clk) begin
    if (!rst_n) begin
        next_note_sel <= 2'd0;
        next_note_timing <= 9'd0;
    end else begin
        if (gate_200hz) begin
            next_note_sel <= pre_next_note_sel;
            case (pre_next_note_octave)
                2'd1: next_note_timing <= pre_next_note_class_timing;
                2'd2: next_note_timing <= pre_next_note_class_timing >> 1;
                2'd3: next_note_timing <= pre_next_note_class_timing >> 2;
                default: next_note_timing <= 9'd0;
            endcase
        end
    end
end

reg [1:0] sequencer_state;
reg [1:0] active_tune;
reg [2:0] tune_pos;
reg [6:0] tune_counter;

always @(posedge clk) begin
    if (!rst_n) begin
        chord[0] <= 6'd0;
        chord[1] <= 6'd0;
        chord[2] <= 6'd0;
        chord[3] <= 6'd0;
        sequencer_state <= 2'd0;
        active_tune <= 2'd0;
        tune_pos <= 3'd0;
        tune_counter <= 7'd0;
    end else if (sequencer_state == 2'd0) begin
        if (sound_mode == 3'd0) begin
            // no  sound
            chord[0] <= 6'd0;
            chord[1] <= 6'd0;
            chord[2] <= 6'd0;
            chord[3] <= 6'd0;
        end else if (sound_mode == 3'd1) begin
            // keyboard feedback
            chord[0] <= buttons[0] ? {2'd1, 4'd7} : 6'd0;
            chord[1] <= buttons[1] ? {2'd2, 4'd0} : 6'd0;
            chord[2] <= buttons[2] ? {2'd2, 4'd4} : 6'd0;
            chord[3] <= buttons[3] ? {2'd2, 4'd7} : 6'd0;
        end else if (sound_mode == 3'd2) begin
            // led feedback
            chord[0] <= leds[0] ? {2'd1, 4'd7} : 6'd0;
            chord[1] <= leds[1] ? {2'd2, 4'd0} : 6'd0;
            chord[2] <= leds[2] ? {2'd2, 4'd4} : 6'd0;
            chord[3] <= leds[3] ? {2'd2, 4'd7} : 6'd0;
        end else if (sound_mode == 3'd3) begin
            // combined feedback
            chord[0] <= (buttons[0] || leds[0]) ? {2'd1, 4'd7} : 6'd0;
            chord[1] <= (buttons[1] || leds[1]) ? {2'd2, 4'd0} : 6'd0;
            chord[2] <= (buttons[2] || leds[2]) ? {2'd2, 4'd4} : 6'd0;
            chord[3] <= (buttons[3] || leds[3]) ? {2'd2, 4'd7} : 6'd0;
        end else begin
            chord[0] <= 6'd0;
            chord[1] <= 6'd0;
            chord[2] <= 6'd0;
            chord[3] <= 6'd0;
            active_tune <= sound_mode[1:0];
            tune_pos <= 3'd0;
            tune_counter <= 7'd0;
            sequencer_state <= 2'd1;
        end
    end else if (sequencer_state == 2'd1) begin
        if (gate_200hz) begin
            tune_counter <= tune_counter + 1;
            if (tune_counter == 7'd50) begin
                tune_counter <= 7'd0;
                sequencer_state <= 2'd2;
            end
        end
    end else if (sequencer_state == 2'd2) begin
        if (gate_200hz) begin
            tune_counter <= tune_counter + 1;
            if (tune_counter == 7'd100) begin
                tune_counter <= 7'd0;
                tune_pos <= tune_pos + 1;
                chord[0] <= 6'd0;
                chord[1] <= 6'd0;
                chord[2] <= 6'd0;
                chord[3] <= 6'd0;
            end else if (tune_counter == 7'd0) begin
                case (active_tune)
                    2'd0: begin
                        // challenge failed
                        case (tune_pos)
                            3'd0: chord[0] <= {2'd2, 4'd7}; // G4
                            3'd1: chord[0] <= {2'd1, 4'd2}; // D3
                            default: sequencer_state <= 2'd3;
                        endcase
                    end
                    2'd1: begin
                        // challenge passed
                        case (tune_pos)
                            3'd0: chord[0] <= {2'd2, 4'd2}; // D4
                            3'd1: chord[0] <= {2'd2, 4'd7}; // G4
                            default: sequencer_state <= 2'd3;
                        endcase
                    end
                    2'd2: begin
                        // level up
                        case (tune_pos)
                            3'd0: chord[0] <= {2'd2, 4'd0}; // C4
                            3'd1: chord[0] <= {2'd2, 4'd4}; // E4
                            3'd2: chord[0] <= {2'd2, 4'd9}; // A4
                            3'd3: chord[0] <= {2'd2, 4'd2}; // D4
                            3'd4: chord[0] <= {2'd2, 4'd7}; // G4
                            3'd5: chord[0] <= {2'd3, 4'd0}; // C5
                            default: sequencer_state <= 2'd3;
                        endcase
                    end
                    2'd3: begin
                        // invalid input
                        case (tune_pos)
                            3'd0: begin
                                chord[0] <= {2'd2, 4'd0}; // C4
                                chord[1] <= {2'd2, 4'd5}; // F4
                            end
                            default: sequencer_state <= 2'd3;
                        endcase
                    end
                endcase
            end
        end
    end else if (sequencer_state == 2'd3) begin
        chord[0] <= 6'd0;
        chord[1] <= 6'd0;
        chord[2] <= 6'd0;
        chord[3] <= 6'd0;
        active_tune <= 2'd0;
        tune_pos <= 3'd0;
        tune_counter <= 7'd0;
        sequencer_state <= 2'd0;
    end
end

assign sound_wait = sequencer_state != 0;

endmodule
