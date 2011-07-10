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

module tmu2_hinterp(
	input sys_clk,
	input sys_rst,

	output busy,

	input pipe_stb_i,
	output pipe_ack_o,
	input signed [11:0] x,
	input signed [11:0] y,
	input signed [17:0] tsx,
	input signed [17:0] tsy,
	input diff_x_positive,
	input [16:0] diff_x_q,
	input [16:0] diff_x_r,
	input diff_y_positive,
	input [16:0] diff_y_q,
	input [16:0] diff_y_r,

	input [10:0] dst_squarew,

	output pipe_stb_o,
	input pipe_ack_i,
	output reg signed [11:0] dx,
	output reg signed [11:0] dy,
	output signed [17:0] tx,
	output signed [17:0] ty
);

reg load;
reg next_point;

/* Interpolators */
tmu2_geninterp18 i_tx(
	.sys_clk(sys_clk),
	.load(load),
	.next_point(next_point),
	.init(tsx),
	.positive(diff_x_positive),
	.q(diff_x_q),
	.r(diff_x_r),
	.divisor({6'd0, dst_squarew}),
	.o(tx)
);
tmu2_geninterp18 i_ty(
	.sys_clk(sys_clk),
	.load(load),
	.next_point(next_point),
	.init(tsy),
	.positive(diff_y_positive),
	.q(diff_y_q),
	.r(diff_y_r),
	.divisor({6'd0, dst_squarew}),
	.o(ty)
);

always @(posedge sys_clk) begin
	if(load) begin
		dx <= x;
		dy <= y;
	end else if(next_point)
		dx <= dx + 12'd1;
end

/* Controller */
reg [10:0] remaining_points;
always @(posedge sys_clk) begin
	if(load)
		remaining_points <= dst_squarew - 11'd1;
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
