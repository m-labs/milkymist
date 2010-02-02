/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009, 2010 Sebastien Bourdeauducq
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

module tmu2_vinterp(
	input sys_clk,
	input sys_rst,

	output busy,

	input pipe_stb_i,
	output reg pipe_ack_o,
	input [17:0] ax,
	input [17:0] ay,
	input [17:0] bx,
	input [17:0] by,
	input diff_cx_positive,
	input [16:0] diff_cx_q,
	input [16:0] diff_cx_r,
	input diff_cy_positive,
	input [16:0] diff_cy_q,
	input [16:0] diff_cy_r,
	input diff_dx_positive,
	input [16:0] diff_dx_q,
	input [16:0] diff_dx_r,
	input diff_dy_positive,
	input [16:0] diff_dy_q,
	input [16:0] diff_dy_r,
	input [11:0] drx,
	input [11:0] dry,

	input [10:0] dst_squareh,

	output reg pipe_stb_o,
	input pipe_ack_i,
	output [11:0] x,
	output [11:0] y,
	output [17:0] tsx,
	output [17:0] tsy,
	output [17:0] tex,
	output [17:0] tey
);

/* VCOMP doesn't like "output reg signed", work around */
reg signed [11:0] x;
reg signed [11:0] y;

reg load;
reg next_point;

/* Input registers */
reg diff_cx_positive_r;
reg [16:0] diff_cx_q_r;
reg [16:0] diff_cx_r_r;
reg diff_cy_positive_r;
reg [16:0] diff_cy_q_r;
reg [16:0] diff_cy_r_r;
reg diff_dx_positive_r;
reg [16:0] diff_dx_q_r;
reg [16:0] diff_dx_r_r;
reg diff_dy_positive_r;
reg [16:0] diff_dy_q_r;
reg [16:0] diff_dy_r_r;

always @(posedge sys_clk) begin
	if(load) begin
		x <= drx;
		diff_cx_positive_r <= diff_cx_positive;
		diff_cx_q_r <= diff_cx_q;
		diff_cx_r_r <= diff_cx_r;
		diff_cy_positive_r <= diff_cy_positive;
		diff_cy_q_r <= diff_cy_q;
		diff_cy_r_r <= diff_cy_r;
		diff_dx_positive_r <= diff_dx_positive;
		diff_dx_q_r <= diff_dx_q;
		diff_dx_r_r <= diff_dx_r;
		diff_dy_positive_r <= diff_dy_positive;
		diff_dy_q_r <= diff_dy_q;
		diff_dy_r_r <= diff_dy_r;
	end
end

/* Interpolators */
tmu2_geninterp18(
	.sys_clk(sys_clk),
	.load(load),
	.next_point(next_point),
	.init(ax),
	.positive(diff_cx_positive_r),
	.q(diff_cx_q_r),
	.r(diff_cx_r_r),
	.divisor({dst_squareh, 6'd0}),
	.o(tsx)
);
tmu2_geninterp18(
	.sys_clk(sys_clk),
	.load(load),
	.next_point(next_point),
	.init(ay),
	.positive(diff_cy_positive_r),
	.q(diff_cy_q_r),
	.r(diff_cy_r_r),
	.divisor({dst_squareh, 6'd0}),
	.o(tsy)
);
tmu2_geninterp18(
	.sys_clk(sys_clk),
	.load(load),
	.next_point(next_point),
	.init(bx),
	.positive(diff_dx_positive_r),
	.q(diff_dx_q_r),
	.r(diff_dx_r_r),
	.divisor({dst_squareh, 6'd0}),
	.o(tex)
);
tmu2_geninterp18(
	.sys_clk(sys_clk),
	.load(load),
	.next_point(next_point),
	.init(by),
	.positive(diff_dy_positive_r),
	.q(diff_dy_q_r),
	.r(diff_dy_r_r),
	.divisor({dst_squareh, 6'd0}),
	.o(tey)
);

/* y datapath */
always @(posedge sys_clk) begin
	if(load)
		y <= dry;
	else if(next_point)
		y <= y + 12'd1;
end

/* Controller */
reg [10:0] remaining_points;
always @(posedge sys_clk) begin
	if(load)
		remaining_points <= dst_squareh - 11'd1;
	else if(next_point)
		remaining_points <= remaining_points - 11'd1;
end
wire last_point = remaining_points == 11'd0;

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
	next_point = 1'b0;

	case(state)
		IDLE: begin
			if(pipe_stb_i) begin
				load = 1'b1;
				next_state = BUSY;
			end
		end
		BUSY: begin
			if(pipe_ack_i) begin
				if(last_point)
					next_state = IDLE;
				else
					next_point = 1'b1;
			end
		end
	endcase
end

endmodule
