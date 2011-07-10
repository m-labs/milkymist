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

module pfpu_faddsub(
	input sys_clk,
	input alu_rst,
	
	input [31:0] a,
	input [31:0] b,
	input sub,
	input valid_i,
	
	output [31:0] r,
	output reg valid_o
);

/* Stage 1 */

reg s1_valid;
reg a_sign;
reg [7:0] a_expn;
reg [22:0] a_mant;

reg b_sign;
reg [7:0] b_expn;
reg [22:0] b_mant;

always @(posedge sys_clk) begin
	if(alu_rst)
		s1_valid <= 1'b0;
	else begin
		s1_valid <= valid_i;
		a_sign <= a[31];
		a_expn <= a[30:23];
		a_mant <= a[22:0];

		b_sign <= b[31] ^ sub;
		b_expn <= b[30:23];
		b_mant <= b[22:0];
	end
end

/* Stage 2 */

reg s2_iszero;		/* one or both of the operands is zero */
reg s2_sign;		/* sign of the result */
reg s2_issub;		/* shall we do a subtraction or an addition */
reg [7:0] s2_expn_max;	/* exponent of the bigger number (abs value) */
reg [7:0] s2_expn_diff;	/* difference with the exponent of the smaller number (abs value) */
reg [22:0] s2_mant_max;	/* mantissa of the bigger number (abs value) */
reg [22:0] s2_mant_min;	/* mantissa of the smaller number (abs value) */

reg s2_valid;

/* local signals ; explicitly share the comparators */
wire expn_compare = a_expn > b_expn;
wire expn_equal   = a_expn == b_expn;
wire mant_compare = a_mant > b_mant;
always @(posedge sys_clk) begin
	if(alu_rst)
		s2_valid <= 1'b0;
	else
		s2_valid <= s1_valid;
	s2_issub <= a_sign ^ b_sign;
	
	if(expn_compare)
		/* |b| <= |a| */
		s2_sign <= a_sign;
	else begin
		if(expn_equal) begin
			if(mant_compare)
				/* |b| <= |a| */
				s2_sign <= a_sign;
			else
				/* |b| >  |a| */
				s2_sign <= b_sign;
		end else
			/* |b| >  |a| */
			s2_sign <= b_sign;
	end
	
	if(expn_compare) begin
		s2_expn_max <= a_expn;
		s2_expn_diff <= a_expn - b_expn;
	end else begin
		s2_expn_max <= b_expn;
		s2_expn_diff <= b_expn - a_expn;
	end
	
	if(expn_equal) begin
		if(mant_compare) begin
			s2_mant_max <= a_mant;
			s2_mant_min <= b_mant;
		end else begin
			s2_mant_max <= b_mant;
			s2_mant_min <= a_mant;
		end
	end else begin
		if(expn_compare) begin
			s2_mant_max <= a_mant;
			s2_mant_min <= b_mant;
		end else begin
			s2_mant_max <= b_mant;
			s2_mant_min <= a_mant;
		end
	end
	
	s2_iszero <= (a_expn == 8'd0)|(b_expn == 8'd0);

end

/* Stage 3 */

reg s3_sign;
reg [7:0] s3_expn;
reg [25:0] s3_mant;

reg s3_valid;

/* local signals */
wire [24:0] max_expanded = {1'b1, s2_mant_max, 1'b0}; /* 1 guard digit */
wire [24:0] min_expanded = {1'b1, s2_mant_min, 1'b0} >> s2_expn_diff;
always @(posedge sys_clk) begin
	if(alu_rst)
		s3_valid <= 1'b0;
	else
		s3_valid <= s2_valid;
	s3_sign <= s2_sign;
	s3_expn <= s2_expn_max;
	
	if(s2_iszero)
		s3_mant <= {2'b01, s2_mant_max, 1'b0};
	else begin
		if(s2_issub)
			s3_mant <= max_expanded - min_expanded;
		else
			s3_mant <= max_expanded + min_expanded;
	end
end

/* Stage 4 */

reg s4_sign;
reg [7:0] s4_expn;
reg [25:0] s4_mant;

wire [4:0] clz;
pfpu_clz32 clz32(
	.d({s3_mant, 6'bx}),
	.clz(clz)
);

always @(posedge sys_clk) begin
	if(alu_rst)
		valid_o <= 1'b0;
	else
		valid_o <= s3_valid;
	s4_sign <= s3_sign;
	s4_mant <= s3_mant << clz;
	s4_expn <= s3_expn - clz + 8'd1;
end

assign r = {s4_sign, s4_expn, s4_mant[24:2]};

endmodule
