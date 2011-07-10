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

module bt656cap_burstmem(
	input sys_clk,

	input we,
	input [2:0] wa,
	input [31:0] wd,

	input [1:0] ra,
	output [63:0] rd
);

reg [31:0] mem1[0:3];
reg [31:0] mem1_do;
always @(posedge sys_clk) begin
	if(we & ~wa[0])
		mem1[wa[2:1]] <= wd;
	mem1_do <= mem1[ra];
end

reg [31:0] mem2[0:3];
reg [31:0] mem2_do;
always @(posedge sys_clk) begin
	if(we & wa[0])
		mem2[wa[2:1]] <= wd;
	mem2_do <= mem2[ra];
end

assign rd = {mem1_do, mem2_do};

endmodule
