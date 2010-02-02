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

module tmu2 #(
	parameter csr_addr = 4'h0,
	parameter fml_depth = 26,
	parameter pixin_cache_depth = 12 /* 4kb cache */
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
	
	/* FML master - Pixel read. fml_we=0 is assumed. */
	output [fml_depth-1:0] fmlr_adr,
	output fmlr_stb,
	input fmlr_ack,
	input [63:0] fmlr_di,
	
	/* FML master - Pixel write. fml_we=1 is assumed. */
	output [fml_depth-1:0] fmlw_adr,
	output fmlw_stb,
	input fmlw_ack,
	output [7:0] fmlw_sel,
	output [63:0] fmlw_do
);

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
wire [10:0] dst_squarew;		/* < 40 width of each destination square (positive int)*/
wire [10:0] dst_squareh;		/* < 44 height of each destination square (positive int)*/

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
	.dst_squareh(dst_squareh)
);

/* Stage 1 - Fetch vertices */
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

	.wbm_adr_o(wbm_adr_o),
	.wbm_cti_o(wbm_cti_o),
	.wbm_cyc_o(wbm_cyc_o),
	.wbm_stb_o(wbm_stb_o),
	.wbm_ack_i(wbm_ack_i),
	.wbm_dat_i(wbm_dat_i),

	.start(start),
	.busy(fetchvertex_busy),

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

/* Stage 2 - Vertical interpolation division operands */
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

tmu2_vdivops(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.pipe_stb_i(fetchvertex_pipe_stb),
	.pipe_ack_o(fetchvertex_pipe_ack),
	.ax(ax),
	.ay(ay),
	.bx(bx),
	.by(dy),
	.cx(cx),
	.cy(dy),
	.dx(dx),
	.dy(dy),
	.drx(drx),
	.dry(dry),

	.pipe_stb_o(vdivops_pipe_stb),
	.pipe_ack_i(vdivops_pipe_ack),
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

	.drx_f(drx_f),
	.dry_f(dry_f)
);

/* Stage xx - Apply decay effect. Chroma key filtering is also applied here. */
wire decay_busy;
wire decay_pipe_stb;
wire decay_pipe_ack;
wire [15:0] src_pixel_d;
wire [fml_depth-1-1:0] dst_addr2;

tmu2_decay #(
	.fml_depth(fml_depth)
) decay (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.busy(decay_busy),
	
	.brightness(brightness),
	.chroma_key_en(chroma_key_en),
	.chroma_key(chroma_key),
	
	.pipe_stb_i(pixin_pipe_stb),
	.pipe_ack_o(pixin_pipe_ack),
	.src_pixel(src_pixel),
	.dst_addr(dst_addr1),
	
	.pipe_stb_o(decay_pipe_stb),
	.pipe_ack_i(decay_pipe_ack),
	.src_pixel_d(src_pixel_d),
	.dst_addr1(dst_addr2)
);

/* Stage xx - Burst assembler */
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
	
	.pipe_stb_i(decay_pipe_stb),
	.pipe_ack_o(decay_pipe_ack),
	.src_pixel_d(src_pixel_d),
	.dst_addr(dst_addr2),
	
	.pipe_stb_o(burst_pipe_stb),
	.pipe_ack_i(burst_pipe_ack),
	.burst_addr(burst_addr),
	.burst_sel(burst_sel),
	.burst_do(burst_do)
);

/* Stage xx - Pixel output */
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

wire pipeline_busy = fetchvertex_busy;

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
