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

/*
 * The general idea behind this module is explained in the paper
 * "Prefetching in a Texture Cache Architecture"
 * by Homan Igehy, Matthew Eldridge, and Kekoa Proudfoot, Stanford University
 */

module tmu2_texcache #(
	parameter cache_depth = 13, /* < log2 of the capacity in 8-bit words */
	parameter fml_depth = 26
) (
	input sys_clk,
	input sys_rst,

	output [fml_depth-1:0] fml_adr,
	output reg fml_stb,
	input fml_ack,
	input [63:0] fml_di,

	input flush,
	output reg busy,

	input pipe_stb_i,
	output reg pipe_ack_o,
	input [fml_depth-1-1:0] dadr, /* in 16-bit words */
	input [fml_depth-1-1:0] tadra,
	input [fml_depth-1-1:0] tadrb,
	input [fml_depth-1-1:0] tadrc,
	input [fml_depth-1-1:0] tadrd,
	input [5:0] x_frac,
	input [5:0] y_frac,

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

/*
 * To make bit index calculations easier,
 * we work with 8-bit granularity EVERYWHERE, unless otherwise noted.
 */

/*
 * Line length is the burst length, that is 4*64 bits, or 32 bytes
 * Addresses are split as follows:
 *
 * |             TAG            |         INDEX          |   OFFSET   |
 * |fml_depth-1      cache_depth|cache_depth-1          5|4          0|
 *
 */


wire [fml_depth-1:0] tadra8_0 = {tadra, 1'b0};
wire [fml_depth-1:0] tadrb8_0 = {tadrb, 1'b0};
wire [fml_depth-1:0] tadrc8_0 = {tadrc, 1'b0};
wire [fml_depth-1:0] tadrd8_0 = {tadrd, 1'b0};



endmodule
