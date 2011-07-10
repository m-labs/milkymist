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

module pfpu_above(
	input sys_clk,
	input alu_rst,

	input [31:0] a,
	input [31:0] b,
	input valid_i,

	output [31:0] r,
	output reg valid_o
);

reg r_one;
always @(posedge sys_clk) begin
	if(alu_rst)
		valid_o <= 1'b0;
	else
		valid_o <= valid_i;
	case({a[31], b[31]})
		2'b00: r_one <= a[30:0] > b[30:0];
		2'b01: r_one <= 1'b1;
		2'b10: r_one <= 1'b0;
		2'b11: r_one <= a[30:0] < b[30:0];
	endcase
end

assign r = r_one ? 32'h3f800000: 32'h00000000;

endmodule
