`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
end

reg clk;
reg rst_n;
reg ena;
reg [3:0] buttons;
reg seg_invert;
wire [7:0] uo_out;
wire [7:0] uio_out;
wire [7:0] uio_oe;

wire [7:0] ui_in = {3'b000, seg_invert, buttons};
wire [7:0] uio_in = 8'b00000000;

wire [3:0] leds = uo_out[3:0];
wire sound = uo_out[4];
wire [1:0] digit_sel = uo_out[6:5];
wire [6:0] segments = uio_out[6:0];

tt_um_htfab_caterpillar user_project (
    .ui_in  (ui_in),    // Dedicated inputs
    .uo_out (uo_out),   // Dedicated outputs
    .uio_in (uio_in),   // IOs: Input path
    .uio_out(uio_out),  // IOs: Output path
    .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
    .ena    (ena),      // enable - goes high when design is selected
    .clk    (clk),      // clock
    .rst_n  (rst_n)     // not reset
);

reg [13:0] segments_cur;
reg [13:0] segments_prev;
reg [13:0] segments_pov;

always @(posedge clk) begin
    if (!rst_n) begin
        segments_cur <= 14'b0;
        segments_prev <= 14'b0;
        segments_pov <= 14'b0;
    end else begin
        segments_cur[13:7] <= {7{digit_sel[1]^seg_invert}} & (segments^{7{seg_invert}});
        segments_cur[6:0]  <= {7{digit_sel[0]^seg_invert}} & (segments^{7{seg_invert}});
        segments_prev <= segments_cur;
        segments_pov <= segments_cur | segments_prev;
    end
end

`ifndef GL_TEST
reg fsm_clk;
reg fsm_reset;
reg fsm_update;
reg fsm_erase;
reg [1:0] fsm_color;
reg [2:0] fsm_read_pos;
wire fsm_empty;
wire fsm_full;
wire [19:0] fsm_valid;
wire [1:0] fsm_read_val;
wire fsm_read_over;

rules fsm (
    .clk(fsm_clk),
    .reset(fsm_reset),
    .update(fsm_update),
    .erase(fsm_erase),
    .color(fsm_color),
    .read_pos(fsm_read_pos),
    .empty(fsm_empty),
    .full(fsm_full),
    .valid(fsm_valid),
    .read_val(fsm_read_val),
    .read_over(fsm_read_over)
);
`endif

endmodule
