/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009, 2010 Sebastien Bourdeauducq
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

module tmu2_qpram #(
	parameter depth = 11, /* < log2 of the capacity in words */
	parameter width = 8
) (
	input sys_clk,
	input ce,

	/* Read port 1 */
	input [depth-1:0] a1,
	output [width-1:0] d1,

	/* Read port 2 */
	input [depth-1:0] a2,
	output [width-1:0] d2,

	/* Read port 3 */
	input [depth-1:0] a3,
	output [width-1:0] d3,

	/* Read port 4 */
	input [depth-1:0] a4,
	output [width-1:0] d4,

	/* Write port - we=1 disables read ports 1 and 3 */
	input we,
	input [depth-1:0] aw,
	input [width-1:0] dw
);

tmu2_dpram_sw #(
	.depth(depth),
	.width(width)
) ram1 (
	.sys_clk(sys_clk),
	.ce(ce),

	.a(we ? aw : a1),
	.we(we),
	.di(dw),
	.do(d1),

	.a2(a2),
	.do2(d2)
);

tmu2_dpram_sw #(
	.depth(depth),
	.width(width)
) ram2 (
	.sys_clk(sys_clk),
	.ce(ce),

	.a(we ? aw : a3),
	.we(we),
	.di(dw),
	.do(d3),

	.a2(a4),
	.do2(d4)
);

endmodule
