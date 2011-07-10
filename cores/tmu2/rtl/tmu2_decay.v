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

module tmu2_decay #(
	parameter fml_depth = 26
) (
	input sys_clk,
	input sys_rst,
	
	output busy,
	
	input [5:0] brightness,
	input chroma_key_en,
	input [15:0] chroma_key,
	
	input pipe_stb_i,
	output pipe_ack_o,
	input [15:0] color,
	input [fml_depth-1-1:0] dadr,
	
	output pipe_stb_o,
	input pipe_ack_i,
	output [15:0] color_d,
	output reg [fml_depth-1-1:0] dadr_f
);

wire en;
reg valid_1;
reg valid_2;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		valid_1 <= 1'b0;
		valid_2 <= 1'b0;
	end else if(en) begin
		valid_1 <= pipe_stb_i & ((color != chroma_key) | ~chroma_key_en);
		valid_2 <= valid_1;
	end
end

/* Pipeline operation on two stages. */

reg [fml_depth-1-1:0] dadr_1;

wire [4:0] r = color[15:11];
wire [5:0] g = color[10:5];
wire [4:0] b = color[4:0];

reg [10:0] r_1;
reg [11:0] g_1;
reg [10:0] b_1;

reg [10:0] r_2;
reg [11:0] g_2;
reg [10:0] b_2;

always @(posedge sys_clk) begin
	if(en) begin
		dadr_1 <= dadr;
		dadr_f <= dadr_1;

		r_1 <= ({1'b0, brightness} + 7'd1)*r;
		g_1 <= ({1'b0, brightness} + 7'd1)*g;
		b_1 <= ({1'b0, brightness} + 7'd1)*b;
		
		r_2 <= r_1;
		g_2 <= g_1;
		b_2 <= b_1;
	end
end

assign color_d = {r_2[10:6], g_2[11:6], b_2[10:6]};

/* Pipeline management */

assign busy = valid_1 | valid_2;

assign pipe_ack_o = ~valid_2 | pipe_ack_i;
assign en = ~valid_2 | pipe_ack_i;

assign pipe_stb_o = valid_2;

endmodule
