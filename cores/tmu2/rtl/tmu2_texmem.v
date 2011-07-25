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

module tmu2_texmem #(
	parameter cache_depth = 13, /* < log2 of the capacity in 8-bit words */
	parameter fragq_depth = 5,   /* < log2 of the fragment FIFO size */
	parameter fetchq_depth = 4,  /* < log2 of the fetch FIFO size */
	parameter commitq_depth = 4,  /* < log2 of the commit FIFO size */
	parameter fml_depth = 26
) (
	input sys_clk,
	input sys_rst,

	output [fml_depth-1:0] fml_adr,
	output fml_stb,
	input fml_ack,
	input [63:0] fml_di,

	input flush,
	output busy,

	input pipe_stb_i,
	output pipe_ack_o,
	input [fml_depth-1-1:0] dadr, /* in 16-bit words */
	input [fml_depth-1-1:0] tadra,
	input [fml_depth-1-1:0] tadrb,
	input [fml_depth-1-1:0] tadrc,
	input [fml_depth-1-1:0] tadrd,
	input [5:0] x_frac,
	input [5:0] y_frac,

	output pipe_stb_o,
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


wire [fml_depth-1:0] tadra8 = {tadra, 1'b0};
wire [fml_depth-1:0] tadrb8 = {tadrb, 1'b0};
wire [fml_depth-1:0] tadrc8 = {tadrc, 1'b0};
wire [fml_depth-1:0] tadrd8 = {tadrd, 1'b0};

/*************************************************/
/** TAG MEMORY                                  **/
/*************************************************/

wire tagmem_busy;
wire tagmem_pipe_stb;
wire tagmem_pipe_ack;
wire [fml_depth-1-1:0] tagmem_dadr;
wire [fml_depth-1:0] tagmem_tadra;
wire [fml_depth-1:0] tagmem_tadrb;
wire [fml_depth-1:0] tagmem_tadrc;
wire [fml_depth-1:0] tagmem_tadrd;
wire [5:0] tagmem_x_frac;
wire [5:0] tagmem_y_frac;
wire tagmem_miss_a;
wire tagmem_miss_b;
wire tagmem_miss_c;
wire tagmem_miss_d;

tmu2_tagmem #(
	.cache_depth(cache_depth),
	.fml_depth(fml_depth)
) tagmem (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.flush(flush),
	.busy(tagmem_busy),

	.pipe_stb_i(pipe_stb_i),
	.pipe_ack_o(pipe_ack_o),
	.dadr(dadr),
	.tadra(tadra8),
	.tadrb(tadrb8),
	.tadrc(tadrc8),
	.tadrd(tadrd8),
	.x_frac(x_frac),
	.y_frac(y_frac),
	
	.pipe_stb_o(tagmem_pipe_stb),
	.pipe_ack_i(tagmem_pipe_ack),
	.dadr_f(tagmem_dadr),
	.tadra_f(tagmem_tadra),
	.tadrb_f(tagmem_tadrb),
	.tadrc_f(tagmem_tadrc),
	.tadrd_f(tagmem_tadrd),
	.x_frac_f(tagmem_x_frac),
	.y_frac_f(tagmem_y_frac),
	.miss_a(tagmem_miss_a),
	.miss_b(tagmem_miss_b),
	.miss_c(tagmem_miss_c),
	.miss_d(tagmem_miss_d)
);

/*************************************************/
/** SPLIT                                       **/
/*************************************************/

wire split_busy;
wire split_frag_pipe_stb;
wire split_frag_pipe_ack;
wire [fml_depth-1-1:0] split_frag_dadr;
wire [cache_depth-1:0] split_frag_tadra;
wire [cache_depth-1:0] split_frag_tadrb;
wire [cache_depth-1:0] split_frag_tadrc;
wire [cache_depth-1:0] split_frag_tadrd;
wire [5:0] split_frag_x_frac;
wire [5:0] split_frag_y_frac;
wire split_frag_miss_a;
wire split_frag_miss_b;
wire split_frag_miss_c;
wire split_frag_miss_d;
wire split_fetch_pipe_stb;
wire split_fetch_pipe_ack;
wire [fml_depth-5-1:0] split_fetch_tadra;
wire [fml_depth-5-1:0] split_fetch_tadrb;
wire [fml_depth-5-1:0] split_fetch_tadrc;
wire [fml_depth-5-1:0] split_fetch_tadrd;
wire split_fetch_miss_a;
wire split_fetch_miss_b;
wire split_fetch_miss_c;
wire split_fetch_miss_d;

tmu2_split #(
	.cache_depth(cache_depth),
	.fml_depth(fml_depth)
) split (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.busy(split_busy),
	
	.pipe_stb_i(tagmem_pipe_stb),
	.pipe_ack_o(tagmem_pipe_ack),
	.dadr(tagmem_dadr),
	.tadra(tagmem_tadra),
	.tadrb(tagmem_tadrb),
	.tadrc(tagmem_tadrc),
	.tadrd(tagmem_tadrd),
	.x_frac(tagmem_x_frac),
	.y_frac(tagmem_y_frac),
	.miss_a(tagmem_miss_a),
	.miss_b(tagmem_miss_b),
	.miss_c(tagmem_miss_c),
	.miss_d(tagmem_miss_d),
	
	/* to fragment FIFO */
	.frag_pipe_stb_o(split_frag_pipe_stb),
	.frag_pipe_ack_i(split_frag_pipe_ack),
	.frag_dadr(split_frag_dadr),
	.frag_tadra(split_frag_tadra),
	.frag_tadrb(split_frag_tadrb),
	.frag_tadrc(split_frag_tadrc),
	.frag_tadrd(split_frag_tadrd),
	.frag_x_frac(split_frag_x_frac),
	.frag_y_frac(split_frag_y_frac),
	.frag_miss_a(split_frag_miss_a),
	.frag_miss_b(split_frag_miss_b),
	.frag_miss_c(split_frag_miss_c),
	.frag_miss_d(split_frag_miss_d),

	/* to texel fetch units */
	.fetch_pipe_stb_o(split_fetch_pipe_stb),
	.fetch_pipe_ack_i(split_fetch_pipe_ack),
	.fetch_tadra(split_fetch_tadra),
	.fetch_tadrb(split_fetch_tadrb),
	.fetch_tadrc(split_fetch_tadrc),
	.fetch_tadrd(split_fetch_tadrd),
	.fetch_miss_a(split_fetch_miss_a),
	.fetch_miss_b(split_fetch_miss_b),
	.fetch_miss_c(split_fetch_miss_c),
	.fetch_miss_d(split_fetch_miss_d)
);

/*************************************************/
/** FRAGMENT FIFO                               **/
/*************************************************/

wire fragf_busy;
wire fragf_pipe_stb;
wire fragf_pipe_ack;
wire [fml_depth-1-1:0] fragf_dadr;
wire [cache_depth-1:0] fragf_tadra;
wire [cache_depth-1:0] fragf_tadrb;
wire [cache_depth-1:0] fragf_tadrc;
wire [cache_depth-1:0] fragf_tadrd;
wire [5:0] fragf_x_frac;
wire [5:0] fragf_y_frac;
wire fragf_miss_a;
wire fragf_miss_b;
wire fragf_miss_c;
wire fragf_miss_d;

tmu2_buffer #(
	.width(fml_depth-1+4*cache_depth+2*6+4),
	.depth(fragq_depth)
) frag_fifo (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.busy(fragf_busy),

	.pipe_stb_i(split_frag_pipe_stb),
	.pipe_ack_o(split_frag_pipe_ack),
	.dat_i({split_frag_dadr,
		split_frag_tadra, split_frag_tadrb, split_frag_tadrc, split_frag_tadrd,
		split_frag_x_frac, split_frag_y_frac,
		split_frag_miss_a, split_frag_miss_b, split_frag_miss_c, split_frag_miss_d}),

	/* to datamem */
	.pipe_stb_o(fragf_pipe_stb),
	.pipe_ack_i(fragf_pipe_ack),
	.dat_o({fragf_dadr,
		fragf_tadra, fragf_tadrb, fragf_tadrc, fragf_tadrd,
		fragf_x_frac, fragf_y_frac,
		fragf_miss_a, fragf_miss_b, fragf_miss_c, fragf_miss_d})
);

/*************************************************/
/** MEMORY REQUEST FIFO                         **/
/*************************************************/

wire fetchf_busy;
wire fetchf_pipe_stb;
wire fetchf_pipe_ack;
wire [fml_depth-5-1:0] fetchf_tadra;
wire [fml_depth-5-1:0] fetchf_tadrb;
wire [fml_depth-5-1:0] fetchf_tadrc;
wire [fml_depth-5-1:0] fetchf_tadrd;
wire fetchf_miss_a;
wire fetchf_miss_b;
wire fetchf_miss_c;
wire fetchf_miss_d;

tmu2_buffer #(
	.width(4*(fml_depth-5)+4),
	.depth(fetchq_depth)
) fetch_fifo (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.busy(fetchf_busy),

	.pipe_stb_i(split_fetch_pipe_stb),
	.pipe_ack_o(split_fetch_pipe_ack),
	.dat_i({split_fetch_tadra, split_fetch_tadrb, split_fetch_tadrc, split_fetch_tadrd,
		split_fetch_miss_a, split_fetch_miss_b, split_fetch_miss_c, split_fetch_miss_d}),

	.pipe_stb_o(fetchf_pipe_stb),
	.pipe_ack_i(fetchf_pipe_ack),
	.dat_o({fetchf_tadra, fetchf_tadrb, fetchf_tadrc, fetchf_tadrd,
		fetchf_miss_a, fetchf_miss_b, fetchf_miss_c, fetchf_miss_d})
);

/*************************************************/
/** MEMORY REQUEST SERIALIZER                   **/
/*************************************************/

wire serialize_busy;
wire serialize_pipe_stb;
wire serialize_pipe_ack;
wire [fml_depth-5-1:0] serialize_adr;
tmu2_serialize #(
	.fml_depth(fml_depth)
) serialize (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.busy(serialize_busy),
	
	.pipe_stb_i(fetchf_pipe_stb),
	.pipe_ack_o(fetchf_pipe_ack),
	.tadra(fetchf_tadra),
	.tadrb(fetchf_tadrb),
	.tadrc(fetchf_tadrc),
	.tadrd(fetchf_tadrd),
	.miss_a(fetchf_miss_a),
	.miss_b(fetchf_miss_b),
	.miss_c(fetchf_miss_c),
	.miss_d(fetchf_miss_d),
	
	.pipe_stb_o(serialize_pipe_stb),
	.pipe_ack_i(serialize_pipe_ack),
	.adr(serialize_adr)
);

/*************************************************/
/** MEMORY REQUEST INITIATOR                    **/
/*************************************************/

wire fetchtexel_busy;
wire fetchtexel_pipe_stb;
wire fetchtexel_pipe_ack;
wire [255:0] fetchtexel_dat;
tmu2_fetchtexel #(
	.depth(commitq_depth),
	.fml_depth(fml_depth)
) fetchtexel (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.busy(fetchtexel_busy),
	
	.pipe_stb_i(serialize_pipe_stb),
	.pipe_ack_o(serialize_pipe_ack),
	.fetch_adr(serialize_adr),
	
	.pipe_stb_o(fetchtexel_pipe_stb),
	.pipe_ack_i(fetchtexel_pipe_ack),
	.fetch_dat(fetchtexel_dat),
	
	.fml_adr(fml_adr),
	.fml_stb(fml_stb),
	.fml_ack(fml_ack),
	.fml_di(fml_di)
);

/*************************************************/
/** DATA MEMORY                                 **/
/*************************************************/

wire datamem_busy;
wire datamem_pipe_stb;
wire datamem_pipe_ack;
tmu2_datamem #(
	.cache_depth(cache_depth),
	.fml_depth(fml_depth)
) datamem (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.busy(datamem_busy),
	
	.frag_pipe_stb_i(fragf_pipe_stb),
	.frag_pipe_ack_o(fragf_pipe_ack),
	.frag_dadr(fragf_dadr),
	.frag_tadra(fragf_tadra),
	.frag_tadrb(fragf_tadrb),
	.frag_tadrc(fragf_tadrc),
	.frag_tadrd(fragf_tadrd),
	.frag_x_frac(fragf_x_frac),
	.frag_y_frac(fragf_y_frac),
	.frag_miss_a(fragf_miss_a),
	.frag_miss_b(fragf_miss_b),
	.frag_miss_c(fragf_miss_c),
	.frag_miss_d(fragf_miss_d),
	
	.fetch_pipe_stb_i(fetchtexel_pipe_stb),
	.fetch_pipe_ack_o(fetchtexel_pipe_ack),
	.fetch_dat(fetchtexel_dat),
	
	.pipe_stb_o(pipe_stb_o),
	.pipe_ack_i(pipe_ack_i),
	.dadr_f(dadr_f),
	.tcolora(tcolora),
	.tcolorb(tcolorb),
	.tcolorc(tcolorc),
	.tcolord(tcolord),
	.x_frac_f(x_frac_f),
	.y_frac_f(y_frac_f)
);


assign busy = tagmem_busy|split_busy
	|fragf_busy
	|fetchf_busy|serialize_busy|fetchtexel_busy
	|datamem_busy;

endmodule
