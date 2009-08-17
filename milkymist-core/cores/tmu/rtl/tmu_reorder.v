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

module tmu_reorder(
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
	output reg signed [11:0] A_S_X,
	output reg signed [11:0] A_S_Y,
	output reg signed [11:0] B_S_X,
	output reg signed [11:0] B_S_Y,
	output reg signed [11:0] C_S_X,
	output reg signed [11:0] C_S_Y,
	output reg signed [11:0] A_D_X,
	output reg signed [11:0] A_D_Y,
	output reg signed [11:0] B_D_X,
	output reg signed [11:0] B_D_Y,
	output reg signed [11:0] C_D_X,
	output reg signed [11:0] C_D_Y
);

/*
 * See http://www.geocities.com/wronski12/3d_tutor/tri_fillers.html
 * The purpose of this module is to reorder the destination triangle
 * points so that A_Y <= B_Y <= C_Y
 */

wire en;

/* Stage 1: Compare Y coordinates */
wire s0_valid;
reg s1_valid;
reg s1_A_over_B;
reg s1_A_over_C;
reg s1_B_over_A;
reg s1_B_over_C;
reg s1_C_over_A;
reg s1_C_over_B;
reg signed [11:0] s1_A_S_X;
reg signed [11:0] s1_A_S_Y;
reg signed [11:0] s1_B_S_X;
reg signed [11:0] s1_B_S_Y;
reg signed [11:0] s1_C_S_X;
reg signed [11:0] s1_C_S_Y;
reg signed [11:0] s1_A_D_X;
reg signed [11:0] s1_A_D_Y;
reg signed [11:0] s1_B_D_X;
reg signed [11:0] s1_B_D_Y;
reg signed [11:0] s1_C_D_X;
reg signed [11:0] s1_C_D_Y;

always @(posedge sys_clk) begin
	if(sys_rst)
		s1_valid <= 1'b0;
	else if(en)
		s1_valid <= s0_valid;
end

always @(posedge sys_clk) begin
	if(en) begin
		s1_A_over_B <= (A0_D_Y <= B0_D_Y);
		s1_A_over_C <= (A0_D_Y <= C0_D_Y);
		s1_B_over_A <= (B0_D_Y <= A0_D_Y);
		s1_B_over_C <= (B0_D_Y <= C0_D_Y);
		s1_C_over_A <= (C0_D_Y <= A0_D_Y);
		s1_C_over_B <= (C0_D_Y <= B0_D_Y);
		
		s1_A_S_X <= A0_S_X;
		s1_A_S_Y <= A0_S_Y;
		s1_B_S_X <= B0_S_X;
		s1_B_S_Y <= B0_S_Y;
		s1_C_S_X <= C0_S_X;
		s1_C_S_Y <= C0_S_Y;
		s1_A_D_X <= A0_D_X;
		s1_A_D_Y <= A0_D_Y;
		s1_B_D_X <= B0_D_X;
		s1_B_D_Y <= B0_D_Y;
		s1_C_D_X <= C0_D_X;
		s1_C_D_Y <= C0_D_Y;
	end
end

/* Stage 2: Make the point order choice and mux accordingly. */
reg s2_valid;

always @(posedge sys_clk) begin
	if(sys_rst)
		s2_valid <= 1'b0;
	else if(en)
		s2_valid <= s1_valid;
end

always @(posedge sys_clk) begin
	if(en) begin
		if(s1_A_over_B & s1_A_over_C) begin
			A_S_X <= s1_A_S_X;
			A_S_Y <= s1_A_S_Y;
			A_D_X <= s1_A_D_X;
			A_D_Y <= s1_A_D_Y;
	
			if(s1_B_over_C) begin
				B_S_X <= s1_B_S_X;
				B_S_Y <= s1_B_S_Y;
				B_D_X <= s1_B_D_X;
				B_D_Y <= s1_B_D_Y;
				
				C_S_X <= s1_C_S_X;
				C_S_Y <= s1_C_S_Y;
				C_D_X <= s1_C_D_X;
				C_D_Y <= s1_C_D_Y;
			end else begin
				B_S_X <= s1_C_S_X;
				B_S_Y <= s1_C_S_Y;
				B_D_X <= s1_C_D_X;
				B_D_Y <= s1_C_D_Y;
				
				C_S_X <= s1_B_S_X;
				C_S_Y <= s1_B_S_Y;
				C_D_X <= s1_B_D_X;
				C_D_Y <= s1_B_D_Y;
			end
		end else if(s1_B_over_A & s1_B_over_C) begin
			A_S_X <= s1_B_S_X;
			A_S_Y <= s1_B_S_Y;
			A_D_X <= s1_B_D_X;
			A_D_Y <= s1_B_D_Y;
		
			if(s1_A_over_C) begin
				B_S_X <= s1_A_S_X;
				B_S_Y <= s1_A_S_Y;
				B_D_X <= s1_A_D_X;
				B_D_Y <= s1_A_D_Y;
				
				C_S_X <= s1_C_S_X;
				C_S_Y <= s1_C_S_Y;
				C_D_X <= s1_C_D_X;
				C_D_Y <= s1_C_D_Y;
			end else begin
				B_S_X <= s1_C_S_X;
				B_S_Y <= s1_C_S_Y;
				B_D_X <= s1_C_D_X;
				B_D_Y <= s1_C_D_Y;
				
				C_S_X <= s1_A_S_X;
				C_S_Y <= s1_A_S_Y;
				C_D_X <= s1_A_D_X;
				C_D_Y <= s1_A_D_Y;
			end
		end else begin /* s1_C_over_A & s1_C_over_B */
			A_S_X <= s1_C_S_X;
			A_S_Y <= s1_C_S_Y;
			A_D_X <= s1_C_D_X;
			A_D_Y <= s1_C_D_Y;
			
			if(s1_A_over_B) begin
				B_S_X <= s1_A_S_X;
				B_S_Y <= s1_A_S_Y;
				B_D_X <= s1_A_D_X;
				B_D_Y <= s1_A_D_Y;
				
				C_S_X <= s1_B_S_X;
				C_S_Y <= s1_B_S_Y;
				C_D_X <= s1_B_D_X;
				C_D_Y <= s1_B_D_Y;
			end else begin
				B_S_X <= s1_B_S_X;
				B_S_Y <= s1_B_S_Y;
				B_D_X <= s1_B_D_X;
				B_D_Y <= s1_B_D_Y;
				
				C_S_X <= s1_A_S_X;
				C_S_Y <= s1_A_S_Y;
				C_D_X <= s1_A_D_X;
				C_D_Y <= s1_A_D_Y;
			end
		end
	end
end

/* Pipeline management */

assign busy = s1_valid|s2_valid;

assign s0_valid = pipe_stb_i;
assign pipe_ack_o = pipe_ack_i;

assign en = pipe_ack_i;
assign pipe_stb_o = s2_valid;

endmodule
