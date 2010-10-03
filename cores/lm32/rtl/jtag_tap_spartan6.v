
module jtag_tap(
	output tck,
	output tdi,
	input tdo,
	output shift,
	output update,
	output reset
);

wire g_shift;
wire g_update;

assign shift = g_shift & sel;
assign update = g_update & sel;

BSCAN_SPARTAN6 #(
	.JTAG_CHAIN(1)
) bscan (
	.CAPTURE(),
	.DRCK(tck),
	.RESET(reset),
	.RUNTEST(),
	.SEL(sel),
	.SHIFT(g_shift),
	.TCK(),
	.TDI(tdi),
	.TMS(),
	.UPDATE(g_update),
	.TDO(tdo)
);

endmodule
