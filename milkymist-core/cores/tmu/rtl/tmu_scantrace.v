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

module tmu_scantrace(
	input sys_clk,
	input sys_rst,
	
	output busy,
	
	input pipe_stb_i,
	output pipe_ack_o,
	input signed [11:0] Y,
	input signed [11:0] S_X,
	input signed [11:0] S_U,
	input signed [11:0] S_V,
	input signed [11:0] E_X,
	input du_positive,
	input [10:0] du_q,
	input [10:0] du_r,
	input dv_positive,
	input [10:0] dv_q,
	input [10:0] dv_r,
	input [10:0] divisor,
	
	output pipe_stb_o,
	input pipe_ack_i,
	output reg signed [11:0] P_X,
	output reg signed [11:0] P_Y,
	output reg signed [11:0] P_U,
	output reg signed [11:0] P_V
);

reg load;

/* Register some inputs */
reg signed [11:0] E_X_r;
reg du_positive_r;
reg [10:0] du_q_r;
reg [10:0] du_r_r;
reg dv_positive_r;
reg [10:0] dv_q_r;
reg [10:0] dv_r_r;
reg [10:0] divisor_r;

always @(posedge sys_clk) begin
	if(load) begin
		P_Y <= Y;
		E_X_r <= E_X;
		du_positive_r <= du_positive;
		du_q_r <= du_q;
		du_r_r <= du_r;
		dv_positive_r <= dv_positive;
		dv_q_r <= dv_q;
		dv_r_r <= dv_r;
		divisor_r <= divisor;
	end
end

/* Current point datapath */
reg addD;
reg [11:0] errU;
reg correctU;
reg [11:0] errV;
reg correctV;
always @(posedge sys_clk) begin
	if(load) begin
		P_U = S_U;
		errU = 12'd0;
		P_V = S_V;
		errV = 12'd0;
	end else begin
		if(addD) begin
			errU = errU + du_r_r;
			correctU = (errU[10:0] > {1'b0, divisor_r[10:1]}) & ~errU[11];
			if(du_positive_r) begin
				P_U = P_U + {1'b0, du_q_r};
				if(correctU)
					P_U = P_U + 12'd1;
			end else begin
				P_U = P_U - {1'b0, du_q_r};
				if(correctU)
					P_U = P_U - 12'd1;
			end
			if(correctU)
				errU = errU - {1'b0, divisor_r};
			
			errV = errV + dv_r_r;
			correctV = (errV[10:0] > {1'b0, divisor_r[10:1]}) & ~errV[11];
			if(dv_positive_r) begin
				P_V = P_V + {1'b0, dv_q_r};
				if(correctV)
					P_V = P_V + 12'd1;
			end else begin
				P_V = P_V - {1'b0, dv_q_r};
				if(correctV)
					P_V = P_V - 12'd1;
			end
			if(correctV)
				errV = errV - {1'b0, divisor_r};
		end
	end
end

/* X datapath */
reg incX;
always @(posedge sys_clk) begin
	if(load)
		P_X <= S_X;
	else if(incX)
		P_X <= P_X + 12'd1;
end

wire reachedE = (P_X == E_X_r);

/* FSM-based controller */

reg state;
reg next_state;

parameter IDLE	= 1'b0;
parameter BUSY	= 1'b1;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= IDLE;
	else
		state <= next_state;
end

assign busy = state;
assign pipe_ack_o = ~state;
assign pipe_stb_o = state;

always @(*) begin
	next_state = state;
	load = 1'b0;
	addD = 1'b0;
	incX = 1'b0;
	
	case(state)
		IDLE: begin
			if(pipe_stb_i) begin
				load = 1'b1;
				next_state = BUSY;
			end
		end
		BUSY: begin
			if(pipe_ack_i) begin
				if(reachedE)
					next_state = IDLE;
				else begin
					incX = 1'b1;
					addD = 1'b1;
				end
			end
		end
	endcase
end

endmodule
