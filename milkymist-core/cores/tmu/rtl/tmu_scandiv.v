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

module tmu_scandiv(
	input sys_clk,
	input sys_rst,
	
	output busy,
	
	input pipe_stb_i,
	output reg pipe_ack_o,
	input signed [11:0] Y0,
	input signed [11:0] S_X0,
	input signed [11:0] S_U0,
	input signed [11:0] S_V0,
	input signed [11:0] E_X0,
	input du0_positive,
	input [10:0] du0,
	input dv0_positive,
	input [10:0] dv0,
	input [10:0] divisor0,
	
	output reg pipe_stb_o,
	input pipe_ack_i,
	output reg signed [11:0] Y,
	output reg signed [11:0] S_X,
	output reg signed [11:0] S_U,
	output reg signed [11:0] S_V,
	output reg signed [11:0] E_X,
	output reg du_positive,
	output [10:0] du_q,
	output [10:0] du_r,
	output reg dv_positive,
	output [10:0] dv_q,
	output [10:0] dv_r,
	output reg [10:0] divisor
);

/* Divider bank */

reg start;
wire ready;

tmu_divider11 d_du(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.start(start),
	.dividend(du0),
	.divisor(divisor0),
	
	.ready(ready),
	.quotient(du_q),
	.remainder(du_r)
);
tmu_divider11 d_dv(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.start(start),
	.dividend(dv0),
	.divisor(divisor0),
	
	.ready(),
	.quotient(dv_q),
	.remainder(dv_r)
);

/* Pipeline pass-through */

always @(posedge sys_clk) begin
	if(start) begin
		Y <= Y0;
		S_X <= S_X0;
		S_U <= S_U0;
		S_V <= S_V0;
		E_X <= E_X0;
		du_positive <= du0_positive;
		dv_positive <= dv0_positive;
		divisor <= divisor0;
	end
end

/* Glue logic */

reg state;
reg next_state;

parameter IDLE = 1'b0;
parameter WAIT = 1'b1;

always @(posedge sys_clk) begin
	if(sys_rst)
		state = IDLE;
	else
		state = next_state;
end

assign busy = state;

always @(*) begin
	next_state = state;

	start = 1'b0;
	pipe_stb_o = 1'b0;
	pipe_ack_o = 1'b0;
	
	case(state)
		IDLE: begin
			pipe_ack_o = 1'b1;
			if(pipe_stb_i) begin
				start = 1'b1;
				next_state = WAIT;
			end
		end
		WAIT: begin
			if(ready) begin
				pipe_stb_o = 1'b1;
				if(pipe_ack_i)
					next_state = IDLE;
			end
		end
	endcase
end

endmodule
