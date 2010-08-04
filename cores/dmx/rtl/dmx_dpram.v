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

module dmx_dpram #(
	parameter depth = 9,
	parameter width = 8
) (
	input clk,

	/* RW port */
	input [depth-1:0] a,
	input we,
	input [width-1:0] di,
	output reg [width-1:0] do,

	/* RO port */
	input [depth-1:0] a2,
	output reg [width-1:0] do2
);

reg [width-1:0] ram[0:(1 << depth)-1];

always @(posedge clk) begin
	if(we)
		ram[a] <= di;
	else
		do <= ram[a];
end

always @(posedge clk)
	do2 <= ram[a2];

endmodule
