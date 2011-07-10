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

module pfpu_quake(
	input sys_clk,
	input alu_rst,

	input [31:0] a,
	input valid_i,

	output reg [31:0] r,
	output reg valid_o
);

always @(posedge sys_clk) begin
	if(alu_rst)
		valid_o <= 1'b0;
	else
		valid_o <= valid_i;
	r <= 32'h5f3759df - a[30:1]; // ignore sign bit and shift
end

endmodule
