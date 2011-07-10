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

module tmu2_clamp(
	input sys_clk,
	input sys_rst,

	output busy,

	input pipe_stb_i,
	output pipe_ack_o,
	input signed [11:0] dx,
	input signed [11:0] dy,
	input signed [17:0] tx,
	input signed [17:0] ty,

	input [10:0] tex_hres,
	input [10:0] tex_vres,
	input [10:0] dst_hres,
	input [10:0] dst_vres,

	output reg pipe_stb_o,
	input pipe_ack_i,
	output reg [10:0] dx_c,
	output reg [10:0] dy_c,
	output reg [16:0] tx_c,
	output reg [16:0] ty_c
);

always @(posedge sys_clk) begin
	if(sys_rst)
		pipe_stb_o <= 1'b0;
	else begin
		if(pipe_ack_i)
			pipe_stb_o <= 1'b0;
		if(pipe_stb_i & pipe_ack_o) begin
			pipe_stb_o <= (~dx[11]) && (dx[10:0] < dst_hres)
				&& (~dy[11]) && (dy[10:0] < dst_vres);
			dx_c <= dx[10:0];
			dy_c <= dy[10:0];
			if(tx[17])
				tx_c <= 17'd0;
			else if(tx[16:0] > {tex_hres - 11'd1, 6'd0})
				tx_c <= {tex_hres - 11'd1, 6'd0};
			else
				tx_c <= tx[16:0];
			if(ty[17])
				ty_c <= 17'd0;
			else if(ty[16:0] > {tex_vres - 11'd1, 6'd0})
				ty_c <= {tex_vres - 11'd1, 6'd0};
			else
				ty_c <= ty[16:0];
		end
	end
end

assign pipe_ack_o = ~pipe_stb_o | pipe_ack_i;

assign busy = pipe_stb_o;

endmodule
