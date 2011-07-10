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

module dmx_dpram #(
	parameter depth = 9,
	parameter width = 8
) (
	input clk,

	input [depth-1:0] a,
	input we,
	input [width-1:0] di,
	output reg [width-1:0] do,

	input [depth-1:0] a2,
	input we2,
	input [width-1:0] di2,
	output reg [width-1:0] do2
);

reg [width-1:0] ram[0:(1 << depth)-1];

always @(posedge clk) begin
	if(we)
		ram[a] <= di;
	do <= ram[a];
	if(we2)
		ram[a2] <= di2;
	do2 <= ram[a2];
end

// synthesis translate_off
integer i;
initial begin
	for(i=0;i<(1 << depth);i=i+1)
		ram[i] = {width{1'b0}};
	ram[0] = 8'h55;
	ram[1] = 8'haa;
	ram[511] = 8'hff;
end
// synthesis translate_on

endmodule
