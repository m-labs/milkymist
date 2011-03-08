/*
 * Milkymist SoC
 * Copyright (C) 2010 Michael Walle
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

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
