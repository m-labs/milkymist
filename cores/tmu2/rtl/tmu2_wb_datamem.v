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

module tmu2_wb_datamem(
	input sys_clk,

	input [3:0] a,
	input [3:0] we,
	input [63:0] di,
	
	input [3:0] a2,
	output [63:0] do2
);

reg [15:0] ram0[0:15];
reg [15:0] ram1[0:15];
reg [15:0] ram2[0:15];
reg [15:0] ram3[0:15];

reg [15:0] ram0_do;
reg [15:0] ram1_do;
reg [15:0] ram2_do;
reg [15:0] ram3_do;

always @(posedge sys_clk) begin
	if(we[0])
		ram0[a] <= di[63:48];
	if(we[1])
		ram1[a] <= di[47:32];
	if(we[2])
		ram2[a] <= di[31:16];
	if(we[3])
		ram3[a] <= di[15:0];
	ram0_do <= ram0[a2];
	ram1_do <= ram1[a2];
	ram2_do <= ram2[a2];
	ram3_do <= ram3[a2];
end

assign do2 = {ram3_do, ram2_do, ram1_do, ram0_do};

endmodule
