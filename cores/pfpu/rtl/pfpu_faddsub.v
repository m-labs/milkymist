/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 *
 * This program is free and excepted software; you can use it, redistribute it
 * and/or modify it under the terms of the Exception General Public License as
 * published by the Exception License Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the Exception General Public License for more
 * details.
 *
 * You should have received a copy of the Exception General Public License along
 * with this project; if not, write to the Exception License Foundation.
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

wire		a_sign = a[31];
wire [7:0]	a_expn = a[30:23];
wire [22:0]	a_mant = a[22:0];

wire		b_sign = b[31] ^ sub;
wire [7:0]	b_expn = b[30:23];
wire [22:0]	b_mant = b[22:0];

/* Stage 1 */

reg s1_iszero;		/* one or both of the operands is zero */
reg s1_sign;		/* sign of the result */
reg s1_issub;		/* shall we do a subtraction or an addition */
reg [7:0] s1_expn_max;	/* exponent of the bigger number (abs value) */
reg [7:0] s1_expn_diff;	/* difference with the exponent of the smaller number (abs value) */
reg [22:0] s1_mant_max;	/* mantissa of the bigger number (abs value) */
reg [22:0] s1_mant_min;	/* mantissa of the smaller number (abs value) */

reg s1_valid;

/* local signals ; explicitly share the comparators */
wire expn_compare = a_expn > b_expn;
wire expn_equal   = a_expn == b_expn;
wire mant_compare = a_mant > b_mant;
always @(posedge sys_clk) begin
	if(alu_rst)
		s1_valid <= 1'b0;
	else
		s1_valid <= valid_i;
	s1_issub <= a_sign ^ b_sign;
	
	if(expn_compare)
		/* |b| <= |a| */
		s1_sign <= a_sign;
	else begin
		if(expn_equal) begin
			if(mant_compare)
				/* |b| <= |a| */
				s1_sign <= a_sign;
			else
				/* |b| >  |a| */
				s1_sign <= b_sign;
		end else
			/* |b| >  |a| */
			s1_sign <= b_sign;
	end
	
	if(expn_compare) begin
		s1_expn_max <= a_expn;
		s1_expn_diff <= a_expn - b_expn;
	end else begin
		s1_expn_max <= b_expn;
		s1_expn_diff <= b_expn - a_expn;
	end
	
	if(expn_equal) begin
		if(mant_compare) begin
			s1_mant_max <= a_mant;
			s1_mant_min <= b_mant;
		end else begin
			s1_mant_max <= b_mant;
			s1_mant_min <= a_mant;
		end
	end else begin
		if(expn_compare) begin
			s1_mant_max <= a_mant;
			s1_mant_min <= b_mant;
		end else begin
			s1_mant_max <= b_mant;
			s1_mant_min <= a_mant;
		end
	end
	
	s1_iszero <= (a_expn == 8'd0)|(b_expn == 8'd0);

end

/* Stage 2 */

reg s2_sign;
reg [7:0] s2_expn;
reg [25:0] s2_mant;

reg s2_valid;

/* local signals */
wire [24:0] max_expanded = {1'b1, s1_mant_max, 1'b0}; /* 1 guard digit */
wire [24:0] min_expanded = {1'b1, s1_mant_min, 1'b0} >> s1_expn_diff;
always @(posedge sys_clk) begin
	if(alu_rst)
		s2_valid <= 1'b0;
	else
		s2_valid <= s1_valid;
	s2_sign <= s1_sign;
	s2_expn <= s1_expn_max;
	
	if(s1_iszero)
		s2_mant <= {2'b01, s1_mant_max, 1'b0};
	else begin
		if(s1_issub)
			s2_mant <= max_expanded - min_expanded;
		else
			s2_mant <= max_expanded + min_expanded;
	end
end

/* Stage 3 */

reg s3_sign;
reg [7:0] s3_expn;
reg [25:0] s3_mant;

wire [4:0] clz;
pfpu_clz32 clz32(
	.d({s2_mant, 6'bx}),
	.clz(clz)
);

always @(posedge sys_clk) begin
	if(alu_rst)
		valid_o <= 1'b0;
	else
		valid_o <= s2_valid;
	s3_sign <= s2_sign;
	s3_mant <= s2_mant << clz;
	s3_expn <= s2_expn - clz + 8'd1;
end

assign r = {s3_sign, s3_expn, s3_mant[24:2]};

endmodule
