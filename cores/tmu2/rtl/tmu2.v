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

module tmu2 #(
	parameter csr_addr = 4'h0,
	parameter fml_depth = 26,
	parameter texel_cache_depth = 15, /* < 32kB cache */
	parameter fragq_depth = 5,   /* < log2 of the fragment FIFO size */
	parameter fetchq_depth = 4,  /* < log2 of the fetch FIFO size */
	parameter commitq_depth = 4  /* < log2 of the commit FIFO size */
) (
	/* Global clock and reset signals */
	input sys_clk,
	input sys_rst,
	
	/* Control interface */
	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output [31:0] csr_do,
	
	output irq,
	
	/* WB master - Vertex read. */
	output [31:0] wbm_adr_o,
	output [2:0] wbm_cti_o,
	output wbm_cyc_o,
	output wbm_stb_o,
	input wbm_ack_i,
	input [31:0] wbm_dat_i,
	
	/* FML master - Texture pixel read. fml_we=0 is assumed. */
	output [fml_depth-1:0] fmlr_adr,
	output fmlr_stb,
	input fmlr_ack,
	input [63:0] fmlr_di,

	/* FML master - Destination pixel read. fml_we=0 is assumed. */
	output [fml_depth-1:0] fmldr_adr,
	output fmldr_stb,
	input fmldr_ack,
	input [63:0] fmldr_di,
	
	/* FML master - Destination pixel write. fml_we=1 is assumed. */
	output [fml_depth-1:0] fmlw_adr,
	output fmlw_stb,
	input fmlw_ack,
	output [7:0] fmlw_sel,
	output [63:0] fmlw_do
);

`define TMU_HAS_ALPHA

/*
 * Fixed Point (FP) coordinate format:
 * 1 sign bit
 * 11 integer bits
 * 6 fractional bits
 * Properties:
 * - 18-bit coordinate
 * - Range: -2048 to +2047.984375
 */

wire start;
reg busy;
wire [6:0] vertex_hlast;		/* < 04 last horizontal vertex index */
wire [6:0] vertex_vlast;		/* < 08 last vertical vertex index */
wire [5:0] brightness;			/* < 0C output brightness 0-63 */
wire chroma_key_en;			/* < 00 enable/disable chroma key filtering */
wire additive_en;			/* < 00 enable/disable additive drawing */
wire [15:0] chroma_key;			/* < 10 chroma key (RGB565 color) */
wire [28:0] vertex_adr;			/* < 14 vertex mesh address (64-bit words) */
wire [fml_depth-1-1:0] tex_fbuf;	/* < 18 texture address (16-bit words) */
wire [10:0] tex_hres;			/* < 1C texture horizontal resolution (positive int) */
wire [10:0] tex_vres;			/* < 20 texture vertical resolution (positive int) */
wire [17:0] tex_hmask;			/* < 24 binary mask to the X texture coordinates (matches fp width) */
wire [17:0] tex_vmask;			/* < 28 binary mask to the Y texture coordinates (matches fp width) */
wire [fml_depth-1-1:0] dst_fbuf;	/* < 2C destination framebuffer address (16-bit words) */
wire [10:0] dst_hres;			/* < 30 destination horizontal resolution (positive int) */
wire [10:0] dst_vres;			/* < 34 destination vertical resolution (positive int) */
wire signed [11:0] dst_hoffset;		/* < 38 X offset added to each pixel (signed int) */
wire signed [11:0] dst_voffset;		/* < 3C Y offset added to each pixel (signed int) */
wire [10:0] dst_squarew;		/* < 40 width of each destination rectangle (positive int)*/
wire [10:0] dst_squareh;		/* < 44 height of each destination rectangle (positive int)*/
wire alpha_en;
wire [5:0] alpha;			/* < 48 opacity of the output 0-63 */

tmu2_ctlif #(
	.csr_addr(csr_addr),
	.fml_depth(fml_depth)
) ctlif (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_di),
	.csr_do(csr_do),
	
	.irq(irq),
	
	.start(start),
	.busy(busy),

	.vertex_hlast(vertex_hlast),
	.vertex_vlast(vertex_vlast),
	.brightness(brightness),
	.chroma_key_en(chroma_key_en),
	.additive_en(additive_en),
	.chroma_key(chroma_key),
	.vertex_adr(vertex_adr),
	.tex_fbuf(tex_fbuf),
	.tex_hres(tex_hres),
	.tex_vres(tex_vres),
	.tex_hmask(tex_hmask),
	.tex_vmask(tex_vmask),
	.dst_fbuf(dst_fbuf),
	.dst_hres(dst_hres),
	.dst_vres(dst_vres),
	.dst_hoffset(dst_hoffset),
	.dst_voffset(dst_voffset),
	.dst_squarew(dst_squarew),
	.dst_squareh(dst_squareh),
	.alpha_en(alpha_en),
	.alpha(alpha)
);

/* Stage - Fetch vertices */
wire fetchvertex_busy;
wire fetchvertex_pipe_stb;
wire fetchvertex_pipe_ack;
wire signed [17:0] ax;
wire signed [17:0] ay;
wire signed [17:0] bx;
wire signed [17:0] by;
wire signed [17:0] cx;
wire signed [17:0] cy;
wire signed [17:0] dx;
wire signed [17:0] dy;
wire signed [11:0] drx;
wire signed [11:0] dry;

tmu2_fetchvertex fetchvertex(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.start(start),
	.busy(fetchvertex_busy),

	.wbm_adr_o(wbm_adr_o),
	.wbm_cti_o(wbm_cti_o),
	.wbm_cyc_o(wbm_cyc_o),
	.wbm_stb_o(wbm_stb_o),
	.wbm_ack_i(wbm_ack_i),
	.wbm_dat_i(wbm_dat_i),

	.vertex_hlast(vertex_hlast),
	.vertex_vlast(vertex_vlast),
	.vertex_adr(vertex_adr),
	.dst_hoffset(dst_hoffset),
	.dst_voffset(dst_voffset),
	.dst_squarew(dst_squarew),
	.dst_squareh(dst_squareh),

	.pipe_stb_o(fetchvertex_pipe_stb),
	.pipe_ack_i(fetchvertex_pipe_ack),
	.ax(ax),
	.ay(ay),
	.bx(bx),
	.by(by),
	.cx(cx),
	.cy(cy),
	.dx(dx),
	.dy(dy),
	.drx(drx),
	.dry(dry)
);

/* Stage - Vertical interpolation division operands */
wire vdivops_busy;
wire vdivops_pipe_stb;
wire vdivops_pipe_ack;
wire signed [17:0] ax_f;
wire signed [17:0] ay_f;
wire signed [17:0] bx_f;
wire signed [17:0] by_f;
wire diff_cx_positive;
wire [16:0] diff_cx;
wire diff_cy_positive;
wire [16:0] diff_cy;
wire diff_dx_positive;
wire [16:0] diff_dx;
wire diff_dy_positive;
wire [16:0] diff_dy;
wire signed [11:0] drx_f;
wire signed [11:0] dry_f;

tmu2_vdivops vdivops(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.busy(vdivops_busy),

	.pipe_stb_i(fetchvertex_pipe_stb),
	.pipe_ack_o(fetchvertex_pipe_ack),
	.ax(ax),
	.ay(ay),
	.bx(bx),
	.by(by),
	.cx(cx),
	.cy(cy),
	.dx(dx),
	.dy(dy),
	.drx(drx),
	.dry(dry),

	.pipe_stb_o(vdivops_pipe_stb),
	.pipe_ack_i(vdivops_pipe_ack),
	.ax_f(ax_f),
	.ay_f(ay_f),
	.bx_f(bx_f),
	.by_f(by_f),
	.diff_cx_positive(diff_cx_positive),
	.diff_cx(diff_cx),
	.diff_cy_positive(diff_cy_positive),
	.diff_cy(diff_cy),
	.diff_dx_positive(diff_dx_positive),
	.diff_dx(diff_dx),
	.diff_dy_positive(diff_dy_positive),
	.diff_dy(diff_dy),
	.drx_f(drx_f),
	.dry_f(dry_f)
);

/* Stage - Vertical division */
wire vdiv_busy;
wire vdiv_pipe_stb;
wire vdiv_pipe_ack;
wire signed [17:0] ax_f2;
wire signed [17:0] ay_f2;
wire signed [17:0] bx_f2;
wire signed [17:0] by_f2;
wire diff_cx_positive_f;
wire [16:0] diff_cx_q;
wire [16:0] diff_cx_r;
wire diff_cy_positive_f;
wire [16:0] diff_cy_q;
wire [16:0] diff_cy_r;
wire diff_dx_positive_f;
wire [16:0] diff_dx_q;
wire [16:0] diff_dx_r;
wire diff_dy_positive_f;
wire [16:0] diff_dy_q;
wire [16:0] diff_dy_r;
wire signed [11:0] drx_f2;
wire signed [11:0] dry_f2;

tmu2_vdiv vdiv(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.busy(vdiv_busy),

	.pipe_stb_i(vdivops_pipe_stb),
	.pipe_ack_o(vdivops_pipe_ack),
	.ax(ax_f),
	.ay(ay_f),
	.bx(bx_f),
	.by(by_f),
	.diff_cx_positive(diff_cx_positive),
	.diff_cx(diff_cx),
	.diff_cy_positive(diff_cy_positive),
	.diff_cy(diff_cy),
	.diff_dx_positive(diff_dx_positive),
	.diff_dx(diff_dx),
	.diff_dy_positive(diff_dy_positive),
	.diff_dy(diff_dy),
	.drx(drx_f),
	.dry(dry_f),

	.dst_squareh(dst_squareh),

	.pipe_stb_o(vdiv_pipe_stb),
	.pipe_ack_i(vdiv_pipe_ack),
	.ax_f(ax_f2),
	.ay_f(ay_f2),
	.bx_f(bx_f2),
	.by_f(by_f2),
	.diff_cx_positive_f(diff_cx_positive_f),
	.diff_cx_q(diff_cx_q),
	.diff_cx_r(diff_cx_r),
	.diff_cy_positive_f(diff_cy_positive_f),
	.diff_cy_q(diff_cy_q),
	.diff_cy_r(diff_cy_r),
	.diff_dx_positive_f(diff_dx_positive_f),
	.diff_dx_q(diff_dx_q),
	.diff_dx_r(diff_dx_r),
	.diff_dy_positive_f(diff_dy_positive_f),
	.diff_dy_q(diff_dy_q),
	.diff_dy_r(diff_dy_r),
	.drx_f(drx_f2),
	.dry_f(dry_f2)
);

/* Stage - Vertical interpolation */
wire vinterp_busy;
wire vinterp_pipe_stb;
wire vinterp_pipe_ack;
wire signed [11:0] vx;
wire signed [11:0] vy;
wire signed [17:0] tsx;
wire signed [17:0] tsy;
wire signed [17:0] tex;
wire signed [17:0] tey;

tmu2_vinterp vinterp(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.busy(vinterp_busy),

	.pipe_stb_i(vdiv_pipe_stb),
	.pipe_ack_o(vdiv_pipe_ack),
	.ax(ax_f2),
	.ay(ay_f2),
	.bx(bx_f2),
	.by(by_f2),
	.diff_cx_positive(diff_cx_positive_f),
	.diff_cx_q(diff_cx_q),
	.diff_cx_r(diff_cx_r),
	.diff_cy_positive(diff_cy_positive_f),
	.diff_cy_q(diff_cy_q),
	.diff_cy_r(diff_cy_r),
	.diff_dx_positive(diff_dx_positive_f),
	.diff_dx_q(diff_dx_q),
	.diff_dx_r(diff_dx_r),
	.diff_dy_positive(diff_dy_positive_f),
	.diff_dy_q(diff_dy_q),
	.diff_dy_r(diff_dy_r),
	.drx(drx_f2),
	.dry(dry_f2),

	.dst_squareh(dst_squareh),

	.pipe_stb_o(vinterp_pipe_stb),
	.pipe_ack_i(vinterp_pipe_ack),
	.x(vx),
	.y(vy),
	.tsx(tsx),
	.tsy(tsy),
	.tex(tex),
	.tey(tey)
);

/* Stage - Horizontal interpolation division operands */
wire hdivops_busy;
wire hdivops_pipe_stb;
wire hdivops_pipe_ack;
wire signed [11:0] vx_f;
wire signed [11:0] vy_f;
wire signed [17:0] tsx_f;
wire signed [17:0] tsy_f;
wire diff_x_positive;
wire [16:0] diff_x;
wire diff_y_positive;
wire [16:0] diff_y;

tmu2_hdivops hdivops(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.busy(hdivops_busy),

	.pipe_stb_i(vinterp_pipe_stb),
	.pipe_ack_o(vinterp_pipe_ack),
	.x(vx),
	.y(vy),
	.tsx(tsx),
	.tsy(tsy),
	.tex(tex),
	.tey(tey),

	.pipe_stb_o(hdivops_pipe_stb),
	.pipe_ack_i(hdivops_pipe_ack),
	.x_f(vx_f),
	.y_f(vy_f),
	.tsx_f(tsx_f),
	.tsy_f(tsy_f),
	.diff_x_positive(diff_x_positive),
	.diff_x(diff_x),
	.diff_y_positive(diff_y_positive),
	.diff_y(diff_y)
);

/* Stage - Horizontal division */
wire hdiv_busy;
wire hdiv_pipe_stb;
wire hdiv_pipe_ack;
wire signed [11:0] vx_f2;
wire signed [11:0] vy_f2;
wire signed [17:0] tsx_f2;
wire signed [17:0] tsy_f2;
wire diff_x_positive_f;
wire [16:0] diff_x_q;
wire [16:0] diff_x_r;
wire diff_y_positive_f;
wire [16:0] diff_y_q;
wire [16:0] diff_y_r;

tmu2_hdiv hdiv(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.busy(hdiv_busy),

	.pipe_stb_i(hdivops_pipe_stb),
	.pipe_ack_o(hdivops_pipe_ack),
	.x(vx_f),
	.y(vy_f),
	.tsx(tsx_f),
	.tsy(tsy_f),
	.diff_x_positive(diff_x_positive),
	.diff_x(diff_x),
	.diff_y_positive(diff_y_positive),
	.diff_y(diff_y),

	.dst_squarew(dst_squarew),

	.pipe_stb_o(hdiv_pipe_stb),
	.pipe_ack_i(hdiv_pipe_ack),
	.x_f(vx_f2),
	.y_f(vy_f2),
	.tsx_f(tsx_f2),
	.tsy_f(tsy_f2),
	.diff_x_positive_f(diff_x_positive_f),
	.diff_x_q(diff_x_q),
	.diff_x_r(diff_x_r),
	.diff_y_positive_f(diff_y_positive_f),
	.diff_y_q(diff_y_q),
	.diff_y_r(diff_y_r)
);

/* Stage - Horizontal interpolation */
wire hinterp_busy;
wire hinterp_pipe_stb;
wire hinterp_pipe_ack;
wire signed [11:0] dstx;
wire signed [11:0] dsty;
wire signed [17:0] tx;
wire signed [17:0] ty;

tmu2_hinterp hinterp(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.busy(hinterp_busy),

	.pipe_stb_i(hdiv_pipe_stb),
	.pipe_ack_o(hdiv_pipe_ack),
	.x(vx_f2),
	.y(vy_f2),
	.tsx(tsx_f2),
	.tsy(tsy_f2),
	.diff_x_positive(diff_x_positive_f),
	.diff_x_q(diff_x_q),
	.diff_x_r(diff_x_r),
	.diff_y_positive(diff_y_positive_f),
	.diff_y_q(diff_y_q),
	.diff_y_r(diff_y_r),

	.dst_squarew(dst_squarew),

	.pipe_stb_o(hinterp_pipe_stb),
	.pipe_ack_i(hinterp_pipe_ack),
	.dx(dstx),
	.dy(dsty),
	.tx(tx),
	.ty(ty)
);

/* Stage - Mask texture coordinates */
wire mask_busy;
wire mask_pipe_stb;
wire mask_pipe_ack;
wire signed [11:0] dstx_f;
wire signed [11:0] dsty_f;
wire signed [17:0] tx_m;
wire signed [17:0] ty_m;

tmu2_mask mask(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.busy(mask_busy),

	.pipe_stb_i(hinterp_pipe_stb),
	.pipe_ack_o(hinterp_pipe_ack),
	.dx(dstx),
	.dy(dsty),
	.tx(tx),
	.ty(ty),

	.tex_hmask(tex_hmask),
	.tex_vmask(tex_vmask),

	.pipe_stb_o(mask_pipe_stb),
	.pipe_ack_i(mask_pipe_ack),
	.dx_f(dstx_f),
	.dy_f(dsty_f),
	.tx_m(tx_m),
	.ty_m(ty_m)
);

/* Stage - Clamp texture coordinates and filter out off-screen points */
wire clamp_busy;
wire clamp_pipe_stb;
wire clamp_pipe_ack;
wire [10:0] dstx_c;
wire [10:0] dsty_c;
wire [16:0] tx_c;
wire [16:0] ty_c;

tmu2_clamp clamp(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.busy(clamp_busy),

	.pipe_stb_i(mask_pipe_stb),
	.pipe_ack_o(mask_pipe_ack),
	.dx(dstx_f),
	.dy(dsty_f),
	.tx(tx_m),
	.ty(ty_m),

	.tex_hres(tex_hres),
	.tex_vres(tex_vres),
	.dst_hres(dst_hres),
	.dst_vres(dst_vres),

	.pipe_stb_o(clamp_pipe_stb),
	.pipe_ack_i(clamp_pipe_ack),
	.dx_c(dstx_c),
	.dy_c(dsty_c),
	.tx_c(tx_c),
	.ty_c(ty_c)
);

/* Stage - Address generator */
wire adrgen_busy;
wire adrgen_pipe_stb;
wire adrgen_pipe_ack;
wire [fml_depth-1-1:0] dadr;
wire [fml_depth-1-1:0] tadra;
wire [fml_depth-1-1:0] tadrb;
wire [fml_depth-1-1:0] tadrc;
wire [fml_depth-1-1:0] tadrd;
wire [5:0] x_frac;
wire [5:0] y_frac;

tmu2_adrgen #(
	.fml_depth(fml_depth)
) adrgen (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.busy(adrgen_busy),

	.pipe_stb_i(clamp_pipe_stb),
	.pipe_ack_o(clamp_pipe_ack),
	.dx_c(dstx_c),
	.dy_c(dsty_c),
	.tx_c(tx_c),
	.ty_c(ty_c),

	.dst_fbuf(dst_fbuf),
	.dst_hres(dst_hres),
	.tex_fbuf(tex_fbuf),
	.tex_hres(tex_hres),

	.pipe_stb_o(adrgen_pipe_stb),
	.pipe_ack_i(adrgen_pipe_ack),
	.dadr(dadr),
	.tadra(tadra),
	.tadrb(tadrb),
	.tadrc(tadrc),
	.tadrd(tadrd),
	.x_frac(x_frac),
	.y_frac(y_frac)
);

/* Stage - Texel memory unit */
wire texmem_busy;
wire texmem_pipe_stb;
wire texmem_pipe_ack;
wire [fml_depth-1-1:0] dadr_f;
wire [15:0] tcolora;
wire [15:0] tcolorb;
wire [15:0] tcolorc;
wire [15:0] tcolord;
wire [5:0] x_frac_f;
wire [5:0] y_frac_f;

tmu2_texmem #(
	.cache_depth(texel_cache_depth),
	.fragq_depth(fragq_depth),
	.fetchq_depth(fetchq_depth),
	.commitq_depth(commitq_depth),
	.fml_depth(fml_depth)
) texmem (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.fml_adr(fmlr_adr),
	.fml_stb(fmlr_stb),
	.fml_ack(fmlr_ack),
	.fml_di(fmlr_di),

	.flush(start),
	.busy(texmem_busy),

	.pipe_stb_i(adrgen_pipe_stb),
	.pipe_ack_o(adrgen_pipe_ack),
	.dadr(dadr),
	.tadra(tadra),
	.tadrb(tadrb),
	.tadrc(tadrc),
	.tadrd(tadrd),
	.x_frac(x_frac),
	.y_frac(y_frac),

	.pipe_stb_o(texmem_pipe_stb),
	.pipe_ack_i(texmem_pipe_ack),
	.dadr_f(dadr_f),
	.tcolora(tcolora),
	.tcolorb(tcolorb),
	.tcolorc(tcolorc),
	.tcolord(tcolord),
	.x_frac_f(x_frac_f),
	.y_frac_f(y_frac_f)
);

/* Stage - Blend neighbouring pixels for bilinear filtering */
wire blend_busy;
wire blend_pipe_stb;
wire blend_pipe_ack;
wire [fml_depth-1-1:0] dadr_f2;
wire [15:0] color;

tmu2_blend #(
	.fml_depth(fml_depth)
) blend (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.busy(blend_busy),
	.pipe_stb_i(texmem_pipe_stb),
	.pipe_ack_o(texmem_pipe_ack),
	.dadr(dadr_f),
	.colora(tcolora),
	.colorb(tcolorb),
	.colorc(tcolorc),
	.colord(tcolord),
	.x_frac(x_frac_f),
	.y_frac(y_frac_f),

	.pipe_stb_o(blend_pipe_stb),
	.pipe_ack_i(blend_pipe_ack),
	.dadr_f(dadr_f2),
	.color(color)
);

/* Stage - Apply decay effect and chroma key filtering. */
wire decay_busy;
wire decay_pipe_stb;
wire decay_pipe_ack;
wire [15:0] color_d;
wire [fml_depth-1-1:0] dadr_f3;

tmu2_decay #(
	.fml_depth(fml_depth)
) decay (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.busy(decay_busy),
	
	.brightness(brightness),
	.chroma_key_en(chroma_key_en),
	.chroma_key(chroma_key),
	
	.pipe_stb_i(blend_pipe_stb),
	.pipe_ack_o(blend_pipe_ack),
	.color(color),
	.dadr(dadr_f2),
	
	.pipe_stb_o(decay_pipe_stb),
	.pipe_ack_i(decay_pipe_ack),
	.color_d(color_d),
	.dadr_f(dadr_f3)
);

`ifdef TMU_HAS_ALPHA
/* Stage - Fetch destination pixel for alpha blending */
wire fdest_busy;
wire fdest_pipe_stb;
wire fdest_pipe_ack;
wire [15:0] color_d_f;
wire [fml_depth-1-1:0] dadr_f4;
wire [15:0] dcolor;

tmu2_fdest #(
	.fml_depth(fml_depth)
) fdest (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.fml_adr(fmldr_adr),
	.fml_stb(fmldr_stb),
	.fml_ack(fmldr_ack),
	.fml_di(fmldr_di),

	.flush(start),
	.busy(fdest_busy),

	.fetch_en(alpha_en|additive_en),

	.pipe_stb_i(decay_pipe_stb),
	.pipe_ack_o(decay_pipe_ack),
	.color(color_d),
	.dadr(dadr_f3),

	.pipe_stb_o(fdest_pipe_stb),
	.pipe_ack_i(fdest_pipe_ack),
	.color_f(color_d_f),
	.dadr_f(dadr_f4),
	.dcolor(dcolor)
);

/* Stage - Alpha blending */
wire alpha_busy;
wire alpha_pipe_stb;
wire alpha_pipe_ack;
wire [fml_depth-1-1:0] dadr_f5;
wire [15:0] acolor;

tmu2_alpha #(
	.fml_depth(fml_depth)
) u_alpha (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.busy(alpha_busy),

	.alpha(alpha),
	.additive(additive_en),

	.pipe_stb_i(fdest_pipe_stb),
	.pipe_ack_o(fdest_pipe_ack),
	.color(color_d_f),
	.dadr(dadr_f4),
	.dcolor(dcolor),

	.pipe_stb_o(alpha_pipe_stb),
	.pipe_ack_i(alpha_pipe_ack),
	.dadr_f(dadr_f5),
	.acolor(acolor)
);
`else
assign fmldr_adr = {fml_depth{1'bx}};
assign fmldr_stb = 1'b0;
`endif

/* Stage - Burst assembler */
reg burst_flush;
wire burst_busy;
wire burst_pipe_stb;
wire burst_pipe_ack;
wire [fml_depth-5-1:0] burst_addr;
wire [15:0] burst_sel;
wire [255:0] burst_do;

tmu2_burst #(
	.fml_depth(fml_depth)
) burst (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.flush(burst_flush),
	.busy(burst_busy),

`ifdef TMU_HAS_ALPHA
	.pipe_stb_i(alpha_pipe_stb),
	.pipe_ack_o(alpha_pipe_ack),
	.color(acolor),
	.dadr(dadr_f5),
`else
	.pipe_stb_i(decay_pipe_stb),
	.pipe_ack_o(decay_pipe_ack),
	.color(color_d),
	.dadr(dadr_f3),
`endif

	.pipe_stb_o(burst_pipe_stb),
	.pipe_ack_i(burst_pipe_ack),
	.burst_addr(burst_addr),
	.burst_sel(burst_sel),
	.burst_do(burst_do)
);

/* Stage - Pixel output */
wire pixout_busy;

tmu2_pixout #(
	.fml_depth(fml_depth)
) pixout (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.busy(pixout_busy),

	.pipe_stb_i(burst_pipe_stb),
	.pipe_ack_o(burst_pipe_ack),
	.burst_addr(burst_addr),
	.burst_sel(burst_sel),
	.burst_do(burst_do),

	.fml_adr(fmlw_adr),
	.fml_stb(fmlw_stb),
	.fml_ack(fmlw_ack),
	.fml_sel(fmlw_sel),
	.fml_do(fmlw_do)
);

/* FSM to flush the burst assembler at the end */

wire pipeline_busy = fetchvertex_busy
	|vdivops_busy|vdiv_busy|vinterp_busy
	|hdivops_busy|hdiv_busy|hinterp_busy
	|mask_busy|adrgen_busy|clamp_busy
	|texmem_busy
	|blend_busy|decay_busy
`ifdef TMU_HAS_ALPHA
	|fdest_busy|alpha_busy
`endif
	|burst_busy|pixout_busy;

parameter IDLE		= 2'd0;
parameter WAIT_PROCESS	= 2'd1;
parameter FLUSH		= 2'd2;
parameter WAIT_FLUSH	= 2'd3;

reg [1:0] state;
reg [1:0] next_state;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= IDLE;
	else
		state <= next_state;
end

always @(*) begin
	next_state = state;

	busy = 1'b1;
	burst_flush = 1'b0;
	
	case(state)
		IDLE: begin
			busy = 1'b0;
			if(start)
				next_state = WAIT_PROCESS;
		end
		WAIT_PROCESS: begin
			if(~pipeline_busy)
				next_state = FLUSH;
		end
		FLUSH: begin
			burst_flush = 1'b1;
			next_state = WAIT_FLUSH;
		end
		WAIT_FLUSH: begin
			if(~pipeline_busy)
				next_state = IDLE;
		end
	endcase
end

endmodule
