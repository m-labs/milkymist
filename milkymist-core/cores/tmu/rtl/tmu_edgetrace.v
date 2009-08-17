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

module tmu_edgetrace(
	input sys_clk,
	input sys_rst,
	
	output reg busy,
	
	input pipe_stb_i,
	output reg pipe_ack_o,
	input signed [11:0] A_S_X,
	input signed [11:0] A_S_Y,
	input signed [11:0] A_D_X,
	input signed [11:0] A_D_Y,
	input signed [11:0] B_D_Y,
	input signed [11:0] C_D_Y,
	
	input dx1_positive,
	input [10:0] dx1_q,
	input [10:0] dx1_r,
	input dx2_positive,
	input [10:0] dx2_q,
	input [10:0] dx2_r,
	input dx3_positive,
	input [10:0] dx3_q,
	input [10:0] dx3_r,
	
	input du1_positive,
	input [10:0] du1_q,
	input [10:0] du1_r,
	input du2_positive,
	input [10:0] du2_q,
	input [10:0] du2_r,
	input du3_positive,
	input [10:0] du3_q,
	input [10:0] du3_r,
	
	input dv1_positive,
	input [10:0] dv1_q,
	input [10:0] dv1_r,
	input dv2_positive,
	input [10:0] dv2_q,
	input [10:0] dv2_r,
	input dv3_positive,
	input [10:0] dv3_q,
	input [10:0] dv3_r,
	
	input [10:0] divisor1,
	input [10:0] divisor2,
	input [10:0] divisor3,
	
	output reg pipe_stb_o,
	input pipe_ack_i,
	output reg signed [11:0] Y,   /* common Y coordinate */
	output reg signed [11:0] S_X, /* start point */
	output reg signed [11:0] S_U,
	output reg signed [11:0] S_V,
	output reg signed [11:0] E_X, /* end point */
	output reg signed [11:0] E_U,
	output reg signed [11:0] E_V
);

reg load;

/* Register some inputs */
reg signed [11:0] B_D_Y_r;
reg signed [11:0] C_D_Y_r;

reg dx1_positive_r;
reg [10:0] dx1_q_r;
reg [10:0] dx1_r_r;
reg dx2_positive_r;
reg [10:0] dx2_q_r;
reg [10:0] dx2_r_r;
reg dx3_positive_r;
reg [10:0] dx3_q_r;
reg [10:0] dx3_r_r;
reg du1_positive_r;
reg [10:0] du1_q_r;
reg [10:0] du1_r_r;
reg du2_positive_r;
reg [10:0] du2_q_r;
reg [10:0] du2_r_r;
reg du3_positive_r;
reg [10:0] du3_q_r;
reg [10:0] du3_r_r;
reg dv1_positive_r;
reg [10:0] dv1_q_r;
reg [10:0] dv1_r_r;
reg dv2_positive_r;
reg [10:0] dv2_q_r;
reg [10:0] dv2_r_r;
reg dv3_positive_r;
reg [10:0] dv3_q_r;
reg [10:0] dv3_r_r;
reg [10:0] divisor1_r;
reg [10:0] divisor2_r;
reg [10:0] divisor3_r;
always @(posedge sys_clk) begin
	if(load) begin
		B_D_Y_r <= B_D_Y;
		C_D_Y_r <= C_D_Y;
		dx1_positive_r <= dx1_positive;
		dx1_q_r <= dx1_q;
		dx1_r_r <= dx1_r;
		dx2_positive_r <= dx2_positive;
		dx2_q_r <= dx2_q;
		dx2_r_r <= dx2_r;
		dx3_positive_r <= dx3_positive;
		dx3_q_r <= dx3_q;
		dx3_r_r <= dx3_r;
		du1_positive_r <= du1_positive;
		du1_q_r <= du1_q;
		du1_r_r <= du1_r;
		du2_positive_r <= du2_positive;
		du2_q_r <= du2_q;
		du2_r_r <= du2_r;
		du3_positive_r <= du3_positive;
		du3_q_r <= du3_q;
		du3_r_r <= du3_r;
		dv1_positive_r <= dv1_positive;
		dv1_q_r <= dv1_q;
		dv1_r_r <= dv1_r;
		dv2_positive_r <= dv2_positive;
		dv2_q_r <= dv2_q;
		dv2_r_r <= dv2_r;
		dv3_positive_r <= dv3_positive;
		dv3_q_r <= dv3_q;
		dv3_r_r <= dv3_r;
		divisor1_r <= divisor1;
		divisor2_r <= divisor2;
		divisor3_r <= divisor3;
	end
end

/* Current points, with X's unordered */
reg signed [11:0] I_X;
reg signed [11:0] I_U;
reg signed [11:0] I_V;
reg signed [11:0] J_X;
reg signed [11:0] J_U;
reg signed [11:0] J_V;

/* Sort the points according to X's */
always @(posedge sys_clk) begin
	if(I_X < J_X) begin
		S_X <= I_X;
		S_U <= I_U;
		S_V <= I_V;
		E_X <= J_X;
		E_U <= J_U;
		E_V <= J_V;
	end else begin
		S_X <= J_X;
		S_U <= J_U;
		S_V <= J_V;
		E_X <= I_X;
		E_U <= I_U;
		E_V <= I_V;
	end
end

/* See scantrace.v for a simpler version of the interpolation algorithm.
 * Here, we only repeat it.
 */

/* Current point datapath */
/* control signals: */
reg addDX1; /* add DX1 to J */
reg addDX2; /* add DX2 to I */
reg addDX3; /* add DX3 to J */

/* error accumulators: */
reg [11:0] errIX2;
reg [11:0] errIU2;
reg [11:0] errIV2;
reg [11:0] errJX1;
reg [11:0] errJU1;
reg [11:0] errJV1;
reg [11:0] errJX3;
reg [11:0] errJU3;
reg [11:0] errJV3;

/* intermediate variables: */
reg correctJX1;
reg correctJU1;
reg correctJV1;
reg correctJX3;
reg correctJU3;
reg correctJV3;

reg correctIX2;
reg correctIU2;
reg correctIV2;

always @(posedge sys_clk) begin
	if(load) begin
		I_X = A_D_X;
		I_U = A_S_X;
		I_V = A_S_Y;
		J_X = A_D_X;
		J_U = A_S_X;
		J_V = A_S_Y;
		
		errIX2 = 12'd0;
		errIU2 = 12'd0;
		errIV2 = 12'd0;
		errJX1 = 12'd0;
		errJU1 = 12'd0;
		errJV1 = 12'd0;
		errJX3 = 12'd0;
		errJU3 = 12'd0;
		errJV3 = 12'd0;
	end else begin
		/* J */
		if(addDX1) begin
			errJX1 = errJX1 + dx1_r_r;
			correctJX1 = (errJX1[10:0] > {1'b0, divisor1_r[10:1]}) & ~errJX1[11];
			if(dx1_positive_r) begin
				J_X = J_X + {1'b0, dx1_q_r};
				if(correctJX1)
					J_X = J_X + 12'd1;
			end else begin
				J_X = J_X - {1'b0, dx1_q_r};
				if(correctJX1)
					J_X = J_X - 12'd1;
			end
			if(correctJX1)
				errJX1 = errJX1 - {1'b0, divisor1_r};
			
			errJU1 = errJU1 + du1_r_r;
			correctJU1 = (errJU1[10:0] > {1'b0, divisor1_r[10:1]}) & ~errJU1[11];
			if(du1_positive_r) begin
				J_U = J_U + {1'b0, du1_q_r};
				if(correctJU1)
					J_U = J_U + 12'd1;
			end else begin
				J_U = J_U - {1'b0, du1_q_r};
				if(correctJU1)
					J_U = J_U - 12'd1;
			end
			if(correctJU1)
				errJU1 = errJU1 - {1'b0, divisor1_r};
			
			errJV1 = errJV1 + dv1_r_r;
			correctJV1 = (errJV1[10:0] > {1'b0, divisor1_r[10:1]}) & ~errJV1[11];
			if(dv1_positive_r) begin
				J_V = J_V + {1'b0, dv1_q_r};
				if(correctJV1)
					J_V = J_V + 12'd1;
			end else begin
				J_V = J_V - {1'b0, dv1_q_r};
				if(correctJV1)
					J_V = J_V - 12'd1;
			end
			if(correctJV1)
				errJV1 = errJV1 - {1'b0, divisor1_r};
		end else if(addDX3) begin
			errJX3 = errJX3 + dx3_r_r;
			correctJX3 = (errJX3[10:0] > {1'b0, divisor3_r[10:1]}) & ~errJX3[11];
			if(dx3_positive_r) begin
				J_X = J_X + {1'b0, dx3_q_r};
				if(correctJX3)
					J_X = J_X + 12'd1;
			end else begin
				J_X = J_X - {1'b0, dx3_q_r};
				if(correctJX3)
					J_X = J_X - 12'd1;
			end
			if(correctJX3)
				errJX3 = errJX3 - {1'b0, divisor3_r};
			
			errJU3 = errJU3 + du3_r_r;
			correctJU3 = (errJU3[10:0] > {1'b0, divisor3_r[10:1]}) & ~errJU3[11];
			if(du3_positive_r) begin
				J_U = J_U + {1'b0, du3_q_r};
				if(correctJU3)
					J_U = J_U + 12'd1;
			end else begin
				J_U = J_U - {1'b0, du3_q_r};
				if(correctJU3)
					J_U = J_U - 12'd1;
			end
			if(correctJU3)
				errJU3 = errJU3 - {1'b0, divisor3_r};
			
			errJV3 = errJV3 + dv3_r_r;
			correctJV3 = (errJV3[10:0] > {1'b0, divisor3_r[10:1]}) & ~errJV3[11];
			if(dv3_positive_r) begin
				J_V = J_V + {1'b0, dv3_q_r};
				if(correctJV3)
					J_V = J_V + 12'd1;
			end else begin
				J_V = J_V - {1'b0, dv3_q_r};
				if(correctJV3)
					J_V = J_V - 12'd1;
			end
			if(correctJV3)
				errJV3 = errJV3 - {1'b0, divisor3_r};
		end
		/* I */
		if(addDX2) begin
			errIX2 = errIX2 + dx2_r_r;
			correctIX2 = (errIX2[10:0] > {1'b0, divisor2_r[10:1]}) & ~errIX2[11];
			if(dx2_positive_r) begin
				I_X = I_X + {1'b0, dx2_q_r};
				if(correctIX2)
					I_X = I_X + 12'd1;
			end else begin
				I_X = I_X - {1'b0, dx2_q_r};
				if(correctIX2)
					I_X = I_X - 12'd1;
			end
			if(correctIX2)
				errIX2 = errIX2 - {1'b0, divisor2_r};
			
			errIU2 = errIU2 + du2_r_r;
			correctIU2 = (errIU2[10:0] > {1'b0, divisor2_r[10:1]}) & ~errIU2[11];
			if(du2_positive_r) begin
				I_U = I_U + {1'b0, du2_q_r};
				if(correctIU2)
					I_U = I_U + 12'd1;
			end else begin
				I_U = I_U - {1'b0, du2_q_r};
				if(correctIU2)
					I_U = I_U - 12'd1;
			end
			if(correctIU2)
				errIU2 = errIU2 - {1'b0, divisor2_r};
			
			errIV2 = errIV2 + dv2_r_r;
			correctIV2 = (errIV2[10:0] > {1'b0, divisor2_r[10:1]}) & ~errIV2[11];
			if(dv2_positive_r) begin
				I_V = I_V + {1'b0, dv2_q_r};
				if(correctIV2)
					I_V = I_V + 12'd1;
			end else begin
				I_V = I_V - {1'b0, dv2_q_r};
				if(correctIV2)
					I_V = I_V - 12'd1;
			end
			if(correctIV2)
				errIV2 = errIV2 - {1'b0, divisor2_r};
		end
	end
end

/* Y datapath */
reg incY;
always @(posedge sys_clk) begin
	if(load)
		Y <= A_D_Y;
	else if(incY)
		Y <= Y + 12'd1;
end

wire reachedB = (Y == B_D_Y_r);
wire reachedC = (Y == C_D_Y_r);

/* FSM-based controller */

reg [2:0] state;
reg [2:0] next_state;

parameter IDLE			= 3'd0;
parameter A_NEXT		= 3'd1;
parameter A_PIPEOUT_WAIT	= 3'd2;
parameter A_PIPEOUT		= 3'd3;
parameter B_START		= 3'd4;
parameter B_NEXT		= 3'd5;
parameter B_PIPEOUT_WAIT	= 3'd6;
parameter B_PIPEOUT		= 3'd7;

/* Register to handle the "AB horizontal" corner case properly */
reg ABh;
reg next_ABh;

always @(posedge sys_clk)
	ABh <= next_ABh;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= IDLE;
	else
		state <= next_state;
end

always @(*) begin
	next_state = state;
	
	busy = 1'b1;
	
	pipe_ack_o = 1'b0;
	pipe_stb_o = 1'b0;
	
	load = 1'b0;
	
	addDX1 = 1'b0;
	addDX2 = 1'b0;
	addDX3 = 1'b0;

	incY = 1'b0;
	
	next_ABh = ABh;
	
	case(state)
		IDLE: begin
			busy = 1'b0;
			pipe_ack_o = 1'b1;
			next_ABh = 1'b1;
			if(pipe_stb_i) begin
				load = 1'b1;
				next_state = A_PIPEOUT_WAIT;
			end
		end
		/* We start the triangle by using factors 2 and 1 */
		A_NEXT: begin
			addDX1 = 1'b1;
			addDX2 = 1'b1;
			next_ABh = 1'b0;
			next_state = A_PIPEOUT_WAIT;
		end
		/* There is one cycle latency because the point must be sorted by X's
		 * (see the beginning of this file).
		 */
		A_PIPEOUT_WAIT: next_state = A_PIPEOUT;
		A_PIPEOUT: begin
			if(reachedB & ABh) begin
				/* We reach B right from the beginning: AB is horizontal.
				 * In this case, the D1 factors have been set so that J becomes B
				 * in one step (we must enter state B_START with J=B).
				 */
				addDX1 = 1'b1;
				next_state = B_START;
			end else begin
				pipe_stb_o = 1'b1;
				if(pipe_ack_i) begin
					if(reachedB)
						next_state = B_START;
					else begin
						incY = 1'b1;
						next_state = A_NEXT;
					end
				end
			end
		end
		
		/* Once we reach B, we use factors 2 and 3 */
		B_START: begin
			if(reachedC)
				next_state = IDLE;
			else
				next_state = B_PIPEOUT_WAIT;
		end
		B_NEXT: begin
			addDX3 = 1'b1;
			addDX2 = 1'b1;
			next_state = B_PIPEOUT_WAIT;
		end
		B_PIPEOUT_WAIT: next_state = B_PIPEOUT;
		B_PIPEOUT: begin
			pipe_stb_o = 1'b1;
			if(pipe_ack_i) begin
				if(reachedC)
					next_state = IDLE;
				else begin
					incY = 1'b1;
					next_state = B_NEXT;
				end
			end
		end
	endcase
end

endmodule
