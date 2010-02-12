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

module tmu2_dpram #(
	parameter depth = 11 /* < log2 of the capacity in 32-bit words */
) (
	input sys_clk,

	input [depth-1:0] a,
	input we,
	input [31:0] di,
	output [31:0] do,

	input [depth-1:0] a2,
	input we2,
	input [31:0] di2,
	output [31:0] do2
);

reg [31:0] ram[0:(1 << depth)-1];

reg [depth-1:0] a_r;
reg [depth-1:0] a2_r;

always @(posedge sys_clk) begin
	a_r <= a;
	a2_r <= a2;
end

always @(posedge sys_clk) begin
	if(we)
		ram[a] <= di;
	if(we2)
		ram[a2] <= di2;
end
assign do = ram[a_r];
assign do2 = ram[a2_r];

endmodule
