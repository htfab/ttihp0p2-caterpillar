`default_nettype none

module tt_um_htfab_caterpillar (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

wire [3:0] raw_buttons = ui_in[3:0];
wire seg_invert = ui_in[4];
wire _unused = &{ena, ui_in[7:5], uio_in, 1'b0};

wire [3:0] leds;
wire sound;
wire [1:0] digit_sel;
wire [6:0] segments;
assign uo_out = {1'b0, digit_sel, sound, leds};
assign uio_out = {1'b0, segments};
assign uio_oe = 8'b11111111;

reg [7:0] clk_div_counter;
reg gate_200hz;

always @(posedge clk) begin
    gate_200hz <= 1'b0;
    if (!rst_n) begin
        clk_div_counter <= 8'b0;
    end else begin
        clk_div_counter <= clk_div_counter + 1;
        if (clk_div_counter == 8'd249) begin
            clk_div_counter <= 8'b0;
            gate_200hz <= 1'b1;
        end
    end
end

wire [3:0] button_state;
wire [4:0] input_event;

buttons btn (
    .clk(clk),
    .rst_n(rst_n),
    .gate_200hz(gate_200hz),
    .raw_buttons(raw_buttons),
    .button_state(button_state),
    .input_event(input_event)
);

wire [4:0] display_value;
wire display_graphical;

display dsp (
    .clk(clk),
    .rst_n(rst_n),
    .value(display_value),
    .seg_invert(seg_invert),
    .graphical(display_graphical),
    .segments(segments),
    .digit_sel(digit_sel)
);

wire [2:0] sound_mode;
wire sound_wait;

sound snd (
    .clk(clk),
    .rst_n(rst_n),
    .gate_200hz(gate_200hz),
    .sound_mode(sound_mode),
    .buttons(button_state),
    .leds(leds),
    .sound(sound),
    .sound_wait(sound_wait)
);

game game (
    .clk(clk),
    .rst_n(rst_n),
    .gate_200hz(gate_200hz),
    .input_event(input_event),
    .sound_wait(sound_wait),
    .leds(leds),
    .display_value(display_value),
    .display_graphical(display_graphical),
    .sound_mode(sound_mode)
);

endmodule
