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

module tmu_addresses #(
	parameter fml_depth = 26
) (
	input sys_clk,
	input sys_rst,
	
	output busy,
	
	input [fml_depth-1-1:0] src_fbuf, /* in 16-bit words */
	input [10:0] src_hres,
	input [fml_depth-1-1:0] dst_fbuf, /* in 16-bit words */
	input [10:0] dst_hres,
	
	input pipe_stb_i,
	output pipe_ack_o,
	input [10:0] P_X,
	input [10:0] P_Y,
	input [10:0] P_U,
	input [10:0] P_V,
	
	output pipe_stb_o,
	input pipe_ack_i,
	output reg [fml_depth-1-1:0] src_addr, /* in 16-bit words */
	output reg [fml_depth-1-1:0] dst_addr  /* in 16-bit words */
);

wire en;
wire s0_valid;
reg s1_valid;
reg s2_valid;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		s1_valid <= 1'b0;
		s2_valid <= 1'b0;
	end else if(en) begin
		s1_valid <= s0_valid;
		s2_valid <= s1_valid;
	end
end

/* Pipeline MAC operation on two stages.
 * The synthesis tool automatically retimes and pushes
 * the registers into the hardwired fast DSP macros.
 */

reg [fml_depth-1-1:0] s1_src_addr;
reg [fml_depth-1-1:0] s1_dst_addr;

/* WA for strange behaviour/bug in Verilator 3.700 :
 * if we directly put the multiplications in the
 * reg assignments, it thinks the results are 11 bits...
 */
wire [21:0] s0_expanded_pv = src_hres*P_V;
wire [21:0] s0_expanded_py = dst_hres*P_Y;

always @(posedge sys_clk) begin
	if(en) begin
		s1_src_addr <= src_fbuf + {{fml_depth-22-1{1'b0}}, s0_expanded_pv} + {{fml_depth-11-1{1'b0}}, P_U};
		s1_dst_addr <= dst_fbuf + {{fml_depth-22-1{1'b0}}, s0_expanded_py} + {{fml_depth-11-1{1'b0}}, P_X};
		src_addr <= s1_src_addr;
		dst_addr <= s1_dst_addr;
	end
end

/* Pipeline management */

assign busy = s1_valid|s2_valid;

assign s0_valid = pipe_stb_i;
assign pipe_ack_o = pipe_ack_i;

assign en = pipe_ack_i;
assign pipe_stb_o = s2_valid;

endmodule
