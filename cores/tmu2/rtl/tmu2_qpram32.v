/*
 * Milkymist SoC
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

module tmu2_qpram32 #(
	parameter depth = 11 /* < log2 of the capacity in 32-bit words */
) (
	input sys_clk,
	input ce,

	/* 32-bit read port 1 */
	input [depth-1:0] a1,
	output [31:0] d1,

	/* 32-bit read port 2 */
	input [depth-1:0] a2,
	output [31:0] d2,
	
	/* 32-bit read port 3 */
	input [depth-1:0] a3,
	output [31:0] d3,
	
	/* 32-bit read port 4 */
	input [depth-1:0] a4,
	output [31:0] d4,

	/* 64-bit write port - we=1 disables read ports */
	input we,
	input [depth-1-1:0] aw,
	input [63:0] dw
);

tmu2_dpram #(
	.depth(depth),
	.width(32)
) ram1 (
	.sys_clk(sys_clk),
	.ce(ce),

	.a(we ? {aw, 1'b0} : a1),
	.we(we),
	.di(dw[63:32]),
	.do(d1),

	.a2(we ? {aw, 1'b1} : a2),
	.we2(we),
	.di2(dw[31:0]),
	.do2(d2)
);

tmu2_dpram #(
	.depth(depth),
	.width(32)
) ram2 (
	.sys_clk(sys_clk),
	.ce(ce),

	.a(we ? {aw, 1'b0} : a3),
	.we(we),
	.di(dw[63:32]),
	.do(d3),

	.a2(we ? {aw, 1'b1} : a4),
	.we2(we),
	.di2(dw[31:0]),
	.do2(d4)
);

endmodule
