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

module tmu2_vdivops(
	input sys_clk,
	input sys_rst,

	output busy,

	input pipe_stb_i,
	output pipe_ack_o,
	input signed [17:0] ax,
	input signed [17:0] ay,
	input signed [17:0] bx,
	input signed [17:0] by,
	input signed [17:0] cx,
	input signed [17:0] cy,
	input signed [17:0] dx,
	input signed [17:0] dy,
	input signed [11:0] drx,
	input signed [11:0] dry,

	output reg pipe_stb_o,
	input pipe_ack_i,
	output [17:0] ax_f,
	output [17:0] ay_f,
	output [17:0] bx_f,
	output [17:0] by_f,
	output reg diff_cx_positive,
	output reg [16:0] diff_cx,
	output reg diff_cy_positive,
	output reg [16:0] diff_cy,
	output reg diff_dx_positive,
	output reg [16:0] diff_dx,
	output reg diff_dy_positive,
	output reg [16:0] diff_dy,
	output [11:0] drx_f,
	output [11:0] dry_f
);

/* VCOMP doesn't like "output reg signed", work around */
reg signed [17:0] ax_f;
reg signed [17:0] ay_f;
reg signed [17:0] bx_f;
reg signed [17:0] by_f;
reg signed [11:0] drx_f;
reg signed [11:0] dry_f;

always @(posedge sys_clk) begin
	if(sys_rst)
		pipe_stb_o <= 1'b0;
	else begin
		pipe_stb_o <= 1'b0;
		if(pipe_stb_i & pipe_ack_o) begin
			pipe_stb_o <= 1'b1;
			if(cx > ax) begin
				diff_cx_positive <= 1'b1;
				diff_cx <= cx - ax;
			else
				diff_cx_positive <= 1'b0;
				diff_cx <= ax - cx;
			end
			if(cy > ay) begin
				diff_cy_positive <= 1'b1;
				diff_cy <= cy - ay;
			else
				diff_cy_positive <= 1'b0;
				diff_cy <= ay - cy;
			end
			if(dx > ax) begin
				diff_dx_positive <= 1'b1;
				diff_dx <= dx - ax;
			else
				diff_dx_positive <= 1'b0;
				diff_dx <= ax - dx;
			end
			if(dy > ay) begin
				diff_dy_positive <= 1'b1;
				diff_dy <= dy - ay;
			else
				diff_dy_positive <= 1'b0;
				diff_dy <= ay - dy;
			end
			ax_f <= ax;
			ay_f <= ay;
			bx_f <= bx;
			by_f <= by;
			drx_f <= drx;
			dry_f <= dry;
		end
	end
end

assign pipe_ack_o = ~pipe_stb_o | pipe_ack_i;

assign busy = pipe_stb_o;

endmodule
