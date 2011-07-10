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

module tmu2_blend #(
	parameter fml_depth = 26
) (
	input sys_clk,
	input sys_rst,

	output busy,

	input pipe_stb_i,
	output pipe_ack_o,
	input [fml_depth-1-1:0] dadr,
	input [15:0] colora,
	input [15:0] colorb,
	input [15:0] colorc,
	input [15:0] colord,
	input [5:0] x_frac,
	input [5:0] y_frac,

	output pipe_stb_o,
	input pipe_ack_i,
	output [fml_depth-1-1:0] dadr_f,
	output [15:0] color
);

/* Arithmetic pipeline. Enable signal is shared to ease usage of hard macros. */

wire pipe_en;

reg valid_1;
reg [15:0] colora_1;
reg [15:0] colorb_1;
reg [15:0] colorc_1;
reg [15:0] colord_1;
reg [fml_depth-1-1:0] dadr_1;
reg [5:0] x_frac_1;
reg [5:0] y_frac_1;
reg [6:0] ix_frac_1;
reg [6:0] iy_frac_1;

reg valid_2;
reg [15:0] colora_2;
reg [15:0] colorb_2;
reg [15:0] colorc_2;
reg [15:0] colord_2;
reg [fml_depth-1-1:0] dadr_2;

reg valid_3;
wire [12:0] pa_3;
wire [12:0] pb_3;
wire [12:0] pc_3;
wire [12:0] pd_3;
reg [15:0] colora_3;
reg [15:0] colorb_3;
reg [15:0] colorc_3;
reg [15:0] colord_3;
reg [fml_depth-1-1:0] dadr_3;
wire [4:0] ra_3 = colora_3[15:11];
wire [5:0] ga_3 = colora_3[10:5];
wire [4:0] ba_3 = colora_3[4:0];
wire [4:0] rb_3 = colorb_3[15:11];
wire [5:0] gb_3 = colorb_3[10:5];
wire [4:0] bb_3 = colorb_3[4:0];
wire [4:0] rc_3 = colorc_3[15:11];
wire [5:0] gc_3 = colorc_3[10:5];
wire [4:0] bc_3 = colorc_3[4:0];
wire [4:0] rd_3 = colord_3[15:11];
wire [5:0] gd_3 = colord_3[10:5];
wire [4:0] bd_3 = colord_3[4:0];

reg valid_4;
reg [fml_depth-1-1:0] dadr_4;

reg valid_5;
wire [16:0] ra_5;
wire [17:0] ga_5;
wire [16:0] ba_5;
wire [16:0] rb_5;
wire [17:0] gb_5;
wire [16:0] bb_5;
wire [16:0] rc_5;
wire [17:0] gc_5;
wire [16:0] bc_5;
wire [16:0] rd_5;
wire [17:0] gd_5;
wire [16:0] bd_5;
reg [fml_depth-1-1:0] dadr_5;

reg valid_6;
reg [16:0] r_6;
reg [17:0] g_6;
reg [16:0] b_6;
reg [fml_depth-1-1:0] dadr_6;

reg valid_7;
reg [4:0] r_7;
reg [5:0] g_7;
reg [4:0] b_7;
reg [fml_depth-1-1:0] dadr_7;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		valid_1 <= 1'b0;
		valid_2 <= 1'b0;
		valid_3 <= 1'b0;
		valid_4 <= 1'b0;
		valid_5 <= 1'b0;
		valid_6 <= 1'b0;
		valid_7 <= 1'b0;
	end else if(pipe_en) begin
		valid_1 <= pipe_stb_i;
		dadr_1 <= dadr;
		colora_1 <= colora;
		colorb_1 <= colorb;
		colorc_1 <= colorc;
		colord_1 <= colord;
		x_frac_1 <= x_frac;
		y_frac_1 <= y_frac;
		ix_frac_1 <= 7'd64 - x_frac;
		iy_frac_1 <= 7'd64 - y_frac;
	
		valid_2 <= valid_1;
		dadr_2 <= dadr_1;
		colora_2 <= colora_1;
		colorb_2 <= colorb_1;
		colorc_2 <= colorc_1;
		colord_2 <= colord_1;

		valid_3 <= valid_2;
		dadr_3 <= dadr_2;
		colora_3 <= colora_2;
		colorb_3 <= colorb_2;
		colorc_3 <= colorc_2;
		colord_3 <= colord_2;

		valid_4 <= valid_3;
		dadr_4 <= dadr_3;

		valid_5 <= valid_4;
		dadr_5 <= dadr_4;

		valid_6 <= valid_5;
		r_6 <= ra_5 + rb_5 + rc_5 + rd_5;
		g_6 <= ga_5 + gb_5 + gc_5 + gd_5;
		b_6 <= ba_5 + bb_5 + bc_5 + bd_5;
		dadr_6 <= dadr_5;

		valid_7 <= valid_6;
		r_7 <= r_6[16:12] + (r_6[11] & (|r_6[10:0] | r_6[12]));
		g_7 <= g_6[17:12] + (g_6[11] & (|g_6[10:0] | g_6[12]));
		b_7 <= b_6[16:12] + (b_6[11] & (|b_6[10:0] | b_6[12]));
		dadr_7 <= dadr_6;
	end
end

tmu2_mult2 m_pa(
	.sys_clk(sys_clk),
	.ce(pipe_en),
	.a(ix_frac_1),
	.b(iy_frac_1),
	.p(pa_3)
);
tmu2_mult2 m_pb(
	.sys_clk(sys_clk),
	.ce(pipe_en),
	.a(x_frac_1),
	.b(iy_frac_1),
	.p(pb_3)
);
tmu2_mult2 m_pc(
	.sys_clk(sys_clk),
	.ce(pipe_en),
	.a(ix_frac_1),
	.b(y_frac_1),
	.p(pc_3)
);
tmu2_mult2 m_pd(
	.sys_clk(sys_clk),
	.ce(pipe_en),
	.a(x_frac_1),
	.b(y_frac_1),
	.p(pd_3)
);

tmu2_mult2 m_ra(
	.sys_clk(sys_clk),
	.ce(pipe_en),
	.a(pa_3),
	.b(ra_3),
	.p(ra_5)
);
tmu2_mult2 m_ga(
	.sys_clk(sys_clk),
	.ce(pipe_en),
	.a(pa_3),
	.b(ga_3),
	.p(ga_5)
);
tmu2_mult2 m_ba(
	.sys_clk(sys_clk),
	.ce(pipe_en),
	.a(pa_3),
	.b(ba_3),
	.p(ba_5)
);
tmu2_mult2 m_rb(
	.sys_clk(sys_clk),
	.ce(pipe_en),
	.a(pb_3),
	.b(rb_3),
	.p(rb_5)
);
tmu2_mult2 m_gb(
	.sys_clk(sys_clk),
	.ce(pipe_en),
	.a(pb_3),
	.b(gb_3),
	.p(gb_5)
);
tmu2_mult2 m_bb(
	.sys_clk(sys_clk),
	.ce(pipe_en),
	.a(pb_3),
	.b(bb_3),
	.p(bb_5)
);
tmu2_mult2 m_rc(
	.sys_clk(sys_clk),
	.ce(pipe_en),
	.a(pc_3),
	.b(rc_3),
	.p(rc_5)
);
tmu2_mult2 m_gc(
	.sys_clk(sys_clk),
	.ce(pipe_en),
	.a(pc_3),
	.b(gc_3),
	.p(gc_5)
);
tmu2_mult2 m_bc(
	.sys_clk(sys_clk),
	.ce(pipe_en),
	.a(pc_3),
	.b(bc_3),
	.p(bc_5)
);
tmu2_mult2 m_rd(
	.sys_clk(sys_clk),
	.ce(pipe_en),
	.a(pd_3),
	.b(rd_3),
	.p(rd_5)
);
tmu2_mult2 m_gd(
	.sys_clk(sys_clk),
	.ce(pipe_en),
	.a(pd_3),
	.b(gd_3),
	.p(gd_5)
);
tmu2_mult2 m_bd(
	.sys_clk(sys_clk),
	.ce(pipe_en),
	.a(pd_3),
	.b(bd_3),
	.p(bd_5)
);

/* Glue logic */

assign pipe_stb_o = valid_7;
assign dadr_f = dadr_7;
assign color = {r_7, g_7, b_7};

assign pipe_en = ~valid_7 | pipe_ack_i;
assign pipe_ack_o = ~valid_7 | pipe_ack_i;

assign busy = valid_1 | valid_2 | valid_3 | valid_4 | valid_5 | valid_6 | valid_7;

endmodule
