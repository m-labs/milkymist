/*
 * Milkymist SoC
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

module tmu2_vdiv(
	input sys_clk,
	input sys_rst,

	output busy,

	input pipe_stb_i,
	output reg pipe_ack_o,
	input signed [17:0] ax,
	input signed [17:0] ay,
	input signed [17:0] bx,
	input signed [17:0] by,
	input diff_cx_positive,
	input [16:0] diff_cx,
	input diff_cy_positive,
	input [16:0] diff_cy,
	input diff_dx_positive,
	input [16:0] diff_dx,
	input diff_dy_positive,
	input [16:0] diff_dy,
	input signed [11:0] drx,
	input signed [11:0] dry,

	input [10:0] dst_squareh,

	output reg pipe_stb_o,
	input pipe_ack_i,
	output reg signed [17:0] ax_f,
	output reg signed [17:0] ay_f,
	output reg signed [17:0] bx_f,
	output reg signed [17:0] by_f,
	output reg diff_cx_positive_f,
	output [16:0] diff_cx_q,
	output [16:0] diff_cx_r,
	output reg diff_cy_positive_f,
	output [16:0] diff_cy_q,
	output [16:0] diff_cy_r,
	output reg diff_dx_positive_f,
	output [16:0] diff_dx_q,
	output [16:0] diff_dx_r,
	output reg diff_dy_positive_f,
	output [16:0] diff_dy_q,
	output [16:0] diff_dy_r,
	output reg signed [11:0] drx_f,
	output reg signed [11:0] dry_f
);

/* Divider bank */
reg start;
wire ready;

tmu2_divider17 d_cx(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.start(start),
	.dividend(diff_cx),
	.divisor({6'd0, dst_squareh}),

	.ready(ready),
	.quotient(diff_cx_q),
	.remainder(diff_cx_r)
);
tmu2_divider17 d_cy(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.start(start),
	.dividend(diff_cy),
	.divisor({6'd0, dst_squareh}),

	.ready(),
	.quotient(diff_cy_q),
	.remainder(diff_cy_r)
);
tmu2_divider17 d_dx(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.start(start),
	.dividend(diff_dx),
	.divisor({6'd0, dst_squareh}),

	.ready(),
	.quotient(diff_dx_q),
	.remainder(diff_dx_r)
);
tmu2_divider17 d_dy(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.start(start),
	.dividend(diff_dy),
	.divisor({6'd0, dst_squareh}),

	.ready(),
	.quotient(diff_dy_q),
	.remainder(diff_dy_r)
);

/* Forward */
always @(posedge sys_clk) begin
	if(start) begin
		ax_f <= ax;
		ay_f <= ay;
		bx_f <= bx;
		by_f <= by;
		diff_cx_positive_f <= diff_cx_positive;
		diff_cy_positive_f <= diff_cy_positive;
		diff_dx_positive_f <= diff_dx_positive;
		diff_dy_positive_f <= diff_dy_positive;
		drx_f <= drx;
		dry_f <= dry;
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
