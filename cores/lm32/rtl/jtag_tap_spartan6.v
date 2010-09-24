
module jtag_tap(
	output sel,
	output tck,
	output tdi,
	input tdo,
	output shift,
	output update,
	output reset
);

BSCAN_SPARTAN6 #(
	.JTAG_CHAIN(1)
) bscan (
	.CAPTURE(),
	.DRCK(tck),
	.RESET(reset),
	.RUNTEST(),
	.SEL(sel),
	.SHIFT(shift),
	.TCK(),
	.TDI(tdi),
	.TMS(),
	.UPDATE(update),
	.TDO(tdo)
);

endmodule
