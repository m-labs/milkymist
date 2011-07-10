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
 * Triple-port synchronous 128x32 RAM
 * Port 1, read-only
 * Port 2, read-only
 * Port 3, write-only
 */

module pfpu_tpram(
	input sys_clk,
	
	input [6:0] p1_a,
	output reg [31:0] p1_d,
	
	input [6:0] p2_a,
	output reg [31:0] p2_d,
	
	input p3_en,
	input [6:0] p3_a,
	input [31:0] p3_d
);

/*
 * Duplicate the contents over two dual-port BRAMs
 *       Port A(WO)   Port B(RO)
 * Mem1     P3           P1
 * Mem2     P3           P2
 */

reg [31:0] mem1[0:127];
always @(posedge sys_clk) begin
	if(p3_en)
		mem1[p3_a] <= p3_d;
	p1_d <= mem1[p1_a];
end

reg [31:0] mem2[0:127];
always @(posedge sys_clk) begin
	if(p3_en)
		mem2[p3_a] <= p3_d;
	p2_d <= mem2[p2_a];
end

endmodule

