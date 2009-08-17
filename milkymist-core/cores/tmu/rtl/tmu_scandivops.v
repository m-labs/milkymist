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

module tmu_scandivops(
	input sys_clk,
	input sys_rst,
	
	output busy,
	
	input pipe_stb_i,
	output pipe_ack_o,
	input signed [11:0] Y0,
	input signed [11:0] S_X0,
	input signed [11:0] S_U0,
	input signed [11:0] S_V0,
	input signed [11:0] E_X0,
	input signed [11:0] E_U0,
	input signed [11:0] E_V0,
	
	output pipe_stb_o,
	input pipe_ack_i,
	/* Points pass-through */
	output reg signed [11:0] Y,
	output reg signed [11:0] S_X,
	output reg signed [11:0] S_U,
	output reg signed [11:0] S_V,
	output reg signed [11:0] E_X,
	/* Dividends */
	output reg du_positive,
	output reg [10:0] du,
	output reg dv_positive,
	output reg [10:0] dv,
	/* Common divisor */
	output reg [10:0] divisor
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
		du_positive = E_U0 > S_U0;
		dv_positive = E_V0 > S_V0;
		
		if(du_positive)
			du = E_U0 - S_U0;
		else
			du = S_U0 - E_U0;
		if(dv_positive)
			dv = E_V0 - S_V0;
		else
			dv = S_V0 - E_V0;
	
		if(E_X0 != S_X0)
			divisor = E_X0 - S_X0;
		else
			divisor = 11'd1;
	end
end

always @(posedge sys_clk) begin
	if(en) begin
		Y <= Y0;
		S_X <= S_X0;
		S_U <= S_U0;
		S_V <= S_V0;
		E_X <= E_X0;
	end
end

/* Pipeline management */

assign busy = s1_valid;

assign s0_valid = pipe_stb_i;
assign pipe_ack_o = pipe_ack_i;

assign en = pipe_ack_i;
assign pipe_stb_o = s1_valid;

endmodule
