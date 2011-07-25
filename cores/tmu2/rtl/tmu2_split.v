/*
 * Milkymist SoC
 * Copyright (C) 2007, 2008, 2009, 2010, 2011 Sebastien Bourdeauducq
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

module tmu2_split #(
	parameter cache_depth = 13,
	parameter fml_depth = 26
) (
	input sys_clk,
	input sys_rst,

	output busy,

	input pipe_stb_i,
	output pipe_ack_o,
	input [fml_depth-1-1:0] dadr,
	input [fml_depth-1:0] tadra,
	input [fml_depth-1:0] tadrb,
	input [fml_depth-1:0] tadrc,
	input [fml_depth-1:0] tadrd,
	input [5:0] x_frac,
	input [5:0] y_frac,
	input miss_a,
	input miss_b,
	input miss_c,
	input miss_d,
	
	/* to fragment FIFO */
	output reg frag_pipe_stb_o,
	input frag_pipe_ack_i,
	output reg [fml_depth-1-1:0] frag_dadr,
	output [cache_depth-1:0] frag_tadra, /* < texel cache addresses (in bytes) */
	output [cache_depth-1:0] frag_tadrb,
	output [cache_depth-1:0] frag_tadrc,
	output [cache_depth-1:0] frag_tadrd,
	output reg [5:0] frag_x_frac,
	output reg [5:0] frag_y_frac,
	output frag_miss_a,
	output frag_miss_b,
	output frag_miss_c,
	output frag_miss_d,

	/* to texel fetch unit */
	output reg fetch_pipe_stb_o,
	input fetch_pipe_ack_i,
	output [fml_depth-5-1:0] fetch_tadra, /* < texel burst addresses (in 4*64 bit units) */
	output [fml_depth-5-1:0] fetch_tadrb,
	output [fml_depth-5-1:0] fetch_tadrc,
	output [fml_depth-5-1:0] fetch_tadrd,
	output fetch_miss_a,
	output fetch_miss_b,
	output fetch_miss_c,
	output fetch_miss_d
);

/* shared data */
reg [fml_depth-1:0] r_tadra;
reg [fml_depth-1:0] r_tadrb;
reg [fml_depth-1:0] r_tadrc;
reg [fml_depth-1:0] r_tadrd;
reg r_miss_a;
reg r_miss_b;
reg r_miss_c;
reg r_miss_d;

assign frag_tadra = r_tadra[cache_depth-1:0];
assign frag_tadrb = r_tadrb[cache_depth-1:0];
assign frag_tadrc = r_tadrc[cache_depth-1:0];
assign frag_tadrd = r_tadrd[cache_depth-1:0];
assign frag_miss_a = r_miss_a;
assign frag_miss_b = r_miss_b;
assign frag_miss_c = r_miss_c;
assign frag_miss_d = r_miss_d;

assign fetch_tadra = r_tadra[fml_depth-1:5];
assign fetch_tadrb = r_tadrb[fml_depth-1:5];
assign fetch_tadrc = r_tadrc[fml_depth-1:5];
assign fetch_tadrd = r_tadrd[fml_depth-1:5];
assign fetch_miss_a = r_miss_a;
assign fetch_miss_b = r_miss_b;
assign fetch_miss_c = r_miss_c;
assign fetch_miss_d = r_miss_d;

reg data_valid;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		frag_pipe_stb_o <= 1'b0;
		fetch_pipe_stb_o <= 1'b0;
	end else begin
		if(frag_pipe_ack_i)
			frag_pipe_stb_o <= 1'b0;
		if(fetch_pipe_ack_i)
			fetch_pipe_stb_o <= 1'b0;
		if(pipe_ack_o) begin
			frag_pipe_stb_o <= pipe_stb_i;
			fetch_pipe_stb_o <= pipe_stb_i & (miss_a | miss_b | miss_c | miss_d);
			frag_dadr <= dadr;
			r_tadra <= tadra;
			r_tadrb <= tadrb;
			r_tadrc <= tadrc;
			r_tadrd <= tadrd;
			frag_x_frac <= x_frac;
			frag_y_frac <= y_frac;
			r_miss_a <= miss_a;
			r_miss_b <= miss_b;
			r_miss_c <= miss_c;
			r_miss_d <= miss_d;
		end
	end
end

assign busy = frag_pipe_stb_o | fetch_pipe_stb_o;
assign pipe_ack_o = (~frag_pipe_stb_o & ~fetch_pipe_stb_o) | (frag_pipe_ack_i & fetch_pipe_ack_i);

endmodule
