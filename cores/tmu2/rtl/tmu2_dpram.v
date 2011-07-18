/*
 * Milkymist SoC
 * Copyright (C) 2007, 2008, 2009, 2010, 2011 Sebastien Bourdeauducq
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

/* Double port RAM (1 read-only + 1 write-only), read-through */

module tmu2_dpram #(
	parameter depth = 11, /* < log2 of the capacity in words */
	parameter width = 32
) (
	input sys_clk,

	input [depth-1:0] ra,
	input re,
	output [width-1:0] rd,

	input [depth-1:0] wa,
	input we,
	input [width-1:0] wd
);

reg [width-1:0] ram[0:(1 << depth)-1];

reg [depth-1:0] rar;

always @(posedge sys_clk) begin
	if(re)
		rar <= ra;
	if(we)
		ram[wa] <= wd;
end

assign rd = ram[rar];


// synthesis translate_off

integer i;
initial begin
	for(i=0;i<(1 << depth);i=i+1)
		ram[i] = 0;
end

// synthesis translate_on

endmodule
