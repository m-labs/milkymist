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

module pfpu_f2i(
	input sys_clk,
	input alu_rst,
	
	input [31:0] a,
	input valid_i,
	
	output reg [31:0] r,
	output reg valid_o
);

wire		a_sign = a[31];
wire [7:0]	a_expn = a[30:23];
wire [23:0]	a_mant = {1'b1, a[22:0]};

reg [30:0] shifted;
always @(*) begin
	if(a_expn >= 8'd150)
		shifted = a_mant << (a_expn - 8'd150);
	else
		shifted = a_mant >> (8'd150 - a_expn);
end

always @(posedge sys_clk) begin
	if(alu_rst)
		valid_o <= 1'b0;
	else
		valid_o <= valid_i;
	if(a_sign)
		r <= 32'd0 - {1'b0, shifted};
	else
		r <= {1'b0, shifted};
end

endmodule
