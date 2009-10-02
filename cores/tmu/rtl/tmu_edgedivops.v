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

module tmu_edgedivops(
	input sys_clk,
	input sys_rst,
	
	output busy,
	
	input pipe_stb_i,
	output pipe_ack_o,
	input signed [11:0] A0_S_X,
	input signed [11:0] A0_S_Y,
	input signed [11:0] B0_S_X,
	input signed [11:0] B0_S_Y,
	input signed [11:0] C0_S_X,
	input signed [11:0] C0_S_Y,
	input signed [11:0] A0_D_X,
	input signed [11:0] A0_D_Y,
	input signed [11:0] B0_D_X,
	input signed [11:0] B0_D_Y,
	input signed [11:0] C0_D_X,
	input signed [11:0] C0_D_Y,
	
	output pipe_stb_o,
	input pipe_ack_i,
	/* Points pass-through */
	output reg signed [11:0] A_S_X,
	output reg signed [11:0] A_S_Y,
	output reg signed [11:0] A_D_X,
	output reg signed [11:0] A_D_Y,
	output reg signed [11:0] B_D_Y,
	output reg signed [11:0] C_D_Y,
	
	/* Dividends */
	output reg dx1_positive,
	output reg [10:0] dx1,
	output reg dx2_positive,
	output reg [10:0] dx2,
	output reg dx3_positive,
	output reg [10:0] dx3,
	
	output reg du1_positive,
	output reg [10:0] du1,
	output reg du2_positive,
	output reg [10:0] du2,
	output reg du3_positive,
	output reg [10:0] du3,
	
	output reg dv1_positive,
	output reg [10:0] dv1,
	output reg dv2_positive,
	output reg [10:0] dv2,
	output reg dv3_positive,
	output reg [10:0] dv3,
	
	/* Common divisors */
	output reg [10:0] divisor1,
	output reg [10:0] divisor2,
	output reg [10:0] divisor3
);

wire en;
wire s0_valid;
reg s1_valid;

always @(posedge sys_clk) begin
	if(sys_rst)
		s1_valid = 1'b0;
	else if(en)
		s1_valid = s0_valid;
end

always @(posedge sys_clk) begin
	if(en) begin
		/* Find signs (whether we will increment or decrement later on) */
		dx1_positive = B0_D_X > A0_D_X;
		dx2_positive = C0_D_X > A0_D_X;
		dx3_positive = C0_D_X > B0_D_X;
		
 		du1_positive = B0_S_X > A0_S_X;
		du2_positive = C0_S_X > A0_S_X;
		du3_positive = C0_S_X > B0_S_X;
		
		dv1_positive = B0_S_Y > A0_S_Y;
		dv2_positive = C0_S_Y > A0_S_Y;
		dv3_positive = C0_S_Y > B0_S_Y;
		
		/* First edge */
		if(dx1_positive)
			dx1 = B0_D_X - A0_D_X;
		else
			dx1 = A0_D_X - B0_D_X;
		if(du1_positive)
			du1 = B0_S_X - A0_S_X;
		else
			du1 = A0_S_X - B0_S_X;
		if(dv1_positive)
			dv1 = B0_S_Y - A0_S_Y;
		else
			dv1 = A0_S_Y - B0_S_Y;
		if(B0_D_Y != A0_D_Y)
			divisor1 = B0_D_Y - A0_D_Y;
		else
			divisor1 = 11'd1;
			
		/* Second edge */
		if(C0_D_Y != A0_D_Y) begin
			if(dx2_positive)
				dx2 = C0_D_X - A0_D_X;
			else
				dx2 = A0_D_X - C0_D_X;
			if(du2_positive)
				du2 = C0_S_X - A0_S_X;
			else
				du2 = A0_S_X - C0_S_X;
			if(dv2_positive)
				dv2 = C0_S_Y - A0_S_Y;
			else
				dv2 = A0_S_Y - C0_S_Y;
			divisor2 = C0_D_Y - A0_D_Y;
		end else begin
			dx2 = 11'd0;
			du2 = 11'd0;
			dv2 = 11'd0;
			divisor2 = 11'd1;
		end
		
		/* Third edge */
		if(C0_D_Y != B0_D_Y) begin
			if(dx3_positive)
				dx3 = C0_D_X - B0_D_X;
			else
				dx3 = B0_D_X - C0_D_X;
			if(du3_positive)
				du3 = C0_S_X - B0_S_X;
			else
				du3 = B0_S_X - C0_S_X;
			if(dv3_positive)
				dv3 = C0_S_Y - B0_S_Y;
			else
				dv3 = B0_S_Y - C0_S_Y;
			divisor3 = C0_D_Y - B0_D_Y;
		end else begin
			dx3 = 11'd0;
			du3 = 11'd0;
			dv3 = 11'd0;
			divisor3 = 11'd1;
		end
	end
end

always @(posedge sys_clk) begin
	if(en) begin
		A_S_X <= A0_S_X;
		A_S_Y <= A0_S_Y;
		A_D_X <= A0_D_X;
		A_D_Y <= A0_D_Y;
		B_D_Y <= B0_D_Y;
		C_D_Y <= C0_D_Y;
	end
end

/* Pipeline management */

assign busy = s1_valid;

assign s0_valid = pipe_stb_i;
assign pipe_ack_o = pipe_ack_i;

assign en = pipe_ack_i;
assign pipe_stb_o = s1_valid;

endmodule
