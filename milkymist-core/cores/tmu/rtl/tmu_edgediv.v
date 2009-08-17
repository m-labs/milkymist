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

module tmu_edgediv(
	input sys_clk,
	input sys_rst,
	
	output busy,
	
	input pipe_stb_i,
	output reg pipe_ack_o,
	/* Points pass-through */
	input signed [11:0] A0_S_X,
	input signed [11:0] A0_S_Y,
	input signed [11:0] A0_D_X,
	input signed [11:0] A0_D_Y,
	input signed [11:0] B0_D_Y,
	input signed [11:0] C0_D_Y,
	input dx10_positive,
	input [10:0] dx10,
	input dx20_positive,
	input [10:0] dx20,
	input dx30_positive,
	input [10:0] dx30,
	input du10_positive,
	input [10:0] du10,
	input du20_positive,
	input [10:0] du20,
	input du30_positive,
	input [10:0] du30,
	input dv10_positive,
	input [10:0] dv10,
	input dv20_positive,
	input [10:0] dv20,
	input dv30_positive,
	input [10:0] dv30,
	input [10:0] divisor10,
	input [10:0] divisor20,
	input [10:0] divisor30,
	
	output reg pipe_stb_o,
	input pipe_ack_i,
	output reg signed [11:0] A_S_X,
	output reg signed [11:0] A_S_Y,
	output reg signed [11:0] A_D_X,
	output reg signed [11:0] A_D_Y,
	output reg signed [11:0] B_D_Y,
	output reg signed [11:0] C_D_Y,
	
	output reg dx1_positive,
	output [10:0] dx1_q,
	output [10:0] dx1_r,
	output reg dx2_positive,
	output [10:0] dx2_q,
	output [10:0] dx2_r,
	output reg dx3_positive,
	output [10:0] dx3_q,
	output [10:0] dx3_r,
	
	output reg du1_positive,
	output [10:0] du1_q,
	output [10:0] du1_r,
	output reg du2_positive,
	output [10:0] du2_q,
	output [10:0] du2_r,
	output reg du3_positive,
	output [10:0] du3_q,
	output [10:0] du3_r,
	
	output reg dv1_positive,
	output [10:0] dv1_q,
	output [10:0] dv1_r,
	output reg dv2_positive,
	output [10:0] dv2_q,
	output [10:0] dv2_r,
	output reg dv3_positive,
	output [10:0] dv3_q,
	output [10:0] dv3_r,
	
	/* Divisors pass-through (needed for Bresenham algorithm) */
	output reg [10:0] divisor1,
	output reg [10:0] divisor2,
	output reg [10:0] divisor3
);

/* Divider bank */

reg start;
wire ready;

/* X (destination X) */
tmu_divider11 d_dx1(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.start(start),
	.dividend(dx10),
	.divisor(divisor10),
	
	.ready(ready),
	.quotient(dx1_q),
	.remainder(dx1_r)
);
tmu_divider11 d_dx2(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.start(start),
	.dividend(dx20),
	.divisor(divisor20),
	
	.ready(),
	.quotient(dx2_q),
	.remainder(dx2_r)
);
tmu_divider11 d_dx3(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.start(start),
	.dividend(dx30),
	.divisor(divisor30),
	
	.ready(),
	.quotient(dx3_q),
	.remainder(dx3_r)
);

/* U (source X) */
tmu_divider11 d_du1(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.start(start),
	.dividend(du10),
	.divisor(divisor10),
	
	.ready(),
	.quotient(du1_q),
	.remainder(du1_r)
);
tmu_divider11 d_du2(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.start(start),
	.dividend(du20),
	.divisor(divisor20),
	
	.ready(),
	.quotient(du2_q),
	.remainder(du2_r)
);
tmu_divider11 d_du3(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.start(start),
	.dividend(du30),
	.divisor(divisor30),
	
	.ready(),
	.quotient(du3_q),
	.remainder(du3_r)
);

/* V (source Y) */
tmu_divider11 d_dv1(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.start(start),
	.dividend(dv10),
	.divisor(divisor10),
	
	.ready(),
	.quotient(dv1_q),
	.remainder(dv1_r)
);
tmu_divider11 d_dv2(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.start(start),
	.dividend(dv20),
	.divisor(divisor20),
	
	.ready(),
	.quotient(dv2_q),
	.remainder(dv2_r)
);
tmu_divider11 d_dv3(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.start(start),
	.dividend(dv30),
	.divisor(divisor30),
	
	.ready(),
	.quotient(dv3_q),
	.remainder(dv3_r)
);

/* Pipeline pass-through */

always @(posedge sys_clk) begin
	if(start) begin
		A_S_X <= A0_S_X;
		A_S_Y <= A0_S_Y;
		A_D_X <= A0_D_X;
		A_D_Y <= A0_D_Y;
		B_D_Y <= B0_D_Y;
		C_D_Y <= C0_D_Y;
		dx1_positive <= dx10_positive;
		dx2_positive <= dx20_positive;
		dx3_positive <= dx30_positive;
		du1_positive <= du10_positive;
		du2_positive <= du20_positive;
		du3_positive <= du30_positive;
		dv1_positive <= dv10_positive;
		dv2_positive <= dv20_positive;
		dv3_positive <= dv30_positive;
		divisor1 <= divisor10;
		divisor2 <= divisor20;
		divisor3 <= divisor30;
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
