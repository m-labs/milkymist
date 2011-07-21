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

module tmu2_datamem#(
	parameter cache_depth = 13,
	parameter fml_depth = 26
) (
	input sys_clk,
	input sys_rst,
	
	output busy,
	
	/* from fragment FIFO */
	input frag_pipe_stb_i,
	output frag_pipe_ack_o,
	input [fml_depth-1-1:0] frag_dadr,
	input [cache_depth-1:0] frag_tadra, /* < texel cache addresses (in bytes) */
	input [cache_depth-1:0] frag_tadrb,
	input [cache_depth-1:0] frag_tadrc,
	input [cache_depth-1:0] frag_tadrd,
	input [5:0] frag_x_frac,
	input [5:0] frag_y_frac,
	input frag_miss_a,
	input frag_miss_b,
	input frag_miss_c,
	input frag_miss_d,
	
	/* from fetch unit */
	input fetch_pipe_stb_i,
	output fetch_pipe_ack_o,
	input [255:0] fetch_dat,
	
	/* to downstream pipeline */
	output reg pipe_stb_o,
	input pipe_ack_i,
	output [fml_depth-1-1:0] dadr_f, /* in 16-bit words */
	output [15:0] tcolora,
	output [15:0] tcolorb,
	output [15:0] tcolorc,
	output [15:0] tcolord,
	output [5:0] x_frac_f,
	output [5:0] y_frac_f
);

endmodule
