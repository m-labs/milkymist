/*
 * Milkymist SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
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

/*
 * Inspired by the post by Ulf Samuelsson
 * http://www.velocityreviews.com/forums/t25846-p4-how-to-count-zeros-in-registers.html
 *
 * The idea is to use a divide-and-conquer approach to process a 2^N bit number.
 * We split the number in two equal halves of 2^(N-1) bits :
 *   MMMMLLLL
 * then, we check if MMMM is all 0's.
 * If it is,
 *      then the number of leading zeros is 2^(N-1) + CLZ(LLLL)
 * If it is not,
 *      then the number of leading zeros is CLZ(MMMM)
 * Recursion stops with CLZ(0)=1 and CLZ(1)=0.
 *
 * If the input is not all zeros, we never propagate a carry and
 * the additions can be replaced by OR's,
 * giving the result bit per bit.
 *
 * In this implementation, we assume that d[0] = 1, yielding the result 31
 * when the input is actually all 0's.
 */

module pfpu_clz32(
	input [31:0] d,
	output [4:0] clz
);

assign clz[4] = d[31:16] == 16'd0;
wire [15:0] d1 = clz[4] ? d[15:0] : d[31:16];

assign clz[3] = d1[15:8] == 8'd0;
wire [7:0] d2 = clz[3] ? d1[7:0] : d1[15:8];

assign clz[2] = d2[7:4] == 4'd0;
wire [3:0] d3 = clz[2] ? d2[3:0] : d2[7:4];

assign clz[1] = d3[3:2] == 2'd0;
wire [1:0] d4 = clz[1] ? d3[1:0] : d3[3:2];

assign clz[0] = d4[1] == 1'b0;

endmodule
