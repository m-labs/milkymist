/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
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

module tmu_clamp(
	input sys_clk,
	input sys_rst,
	
	output busy,
	
	input [10:0] src_hres,
	input [10:0] src_vres,
	input [10:0] dst_hres,
	input [10:0] dst_vres,
	
	input pipe_stb_i,
	output pipe_ack_o,
	input signed [11:0] P_X,
	input signed [11:0] P_Y,
	input signed [11:0] P_U,
	input signed [11:0] P_V,
	
	output pipe_stb_o,
	input pipe_ack_i,
	output reg [10:0] P_Xc,
	output reg [10:0] P_Yc,
	output reg [10:0] P_Uc,
	output reg [10:0] P_Vc
);

wire en;
wire s0_valid;
reg s1_valid;

always @(posedge sys_clk) begin
	if(sys_rst)
		s1_valid <= 1'b0;
	else if(en) begin
		s1_valid <= s0_valid & ~P_X[11] & (P_X < {1'b0, dst_hres}) & ~P_Y[11] & (P_Y < {1'b0, dst_vres});

		P_Xc <= P_X[10:0];
		P_Yc <= P_Y[10:0];
		
		if(P_U[11])
			P_Uc <= 11'd0;
		else begin
			if(P_U < {1'b0, src_hres})
				P_Uc <= P_U[10:0];
			else
				P_Uc <= src_hres - 11'd1;
		end

		if(P_V[11])
			P_Vc <= 11'd0;
		else begin
			if(P_V < {1'b0, src_vres})
				P_Vc <= P_V[10:0];
			else
				P_Vc <= src_vres - 11'd1;
		end
	end
end

/* Pipeline management */

assign busy = s1_valid;

assign s0_valid = pipe_stb_i;
assign pipe_ack_o = pipe_ack_i;

assign en = pipe_ack_i;
assign pipe_stb_o = s1_valid;

endmodule
