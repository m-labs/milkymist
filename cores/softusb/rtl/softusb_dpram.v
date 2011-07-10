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

/* Double-port RAM with double write-capable port */

module softusb_dpram #(
	parameter depth = 11, /* < log2 of the capacity in words */
	parameter width = 32,
	parameter initfile = ""
) (
	input clk,
	input clk2,

	input [depth-1:0] a,
	input we,
	input [width-1:0] di,
	output reg [width-1:0] do,

	input ce2,
	input [depth-1:0] a2,
	input we2,
	input [width-1:0] di2,
	output reg [width-1:0] do2
);

reg [width-1:0] ram[0:(1 << depth)-1];

// synthesis translate_off
integer i;
initial begin
	if(initfile != "")
		$readmemh(initfile, ram);
	else
		for(i=0;i<(1 << depth);i=i+1)
			ram[i] = 0;
end
// synthesis translate_on

always @(posedge clk) begin
	if(we)
		ram[a] <= di;
	else
		do <= ram[a];
end

always @(posedge clk2) begin
	if(ce2) begin
		if(we2)
			ram[a2] <= di2;
		else
			do2 <= ram[a2];
	end
end

endmodule
