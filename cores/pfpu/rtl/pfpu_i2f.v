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

module pfpu_i2f(
	input sys_clk,
	input alu_rst,
	
	input [31:0] a,
	input valid_i,
	
	output [31:0] r,
	output valid_o
);

/* Stage 1 */
reg s1_valid;
reg s1_sign;
reg [30:0] s1_abs;
reg s1_zero;

always @(posedge sys_clk) begin
	if(alu_rst)
		s1_valid <= 1'b0;
	else
		s1_valid <= valid_i;
	s1_sign <= a[31];
	if(a[31])
		s1_abs <= 31'd0 - a[30:0];
	else
		s1_abs <= a[30:0];
	s1_zero <= a == 32'd0;
end

/* Stage 2 */
wire [4:0] s1_clz;
pfpu_clz32 clz32(
	.d({s1_abs, 1'bx}),
	.clz(s1_clz)
);

reg s2_valid;
reg s2_sign;
reg [7:0] s2_expn;
reg [30:0] s2_mant;

always @(posedge sys_clk) begin
	if(alu_rst)
		s2_valid <= 1'b0;
	else
		s2_valid <= s1_valid;
	s2_sign <= s1_sign;
	s2_mant <= s1_abs << s1_clz;
	
	if(s1_zero)
		s2_expn <= 8'd0;
	else
		s2_expn <= 8'd157 - {4'd0, s1_clz};
end

assign r = {s2_sign, s2_expn, s2_mant[29:7]};
assign valid_o = s2_valid;

endmodule
