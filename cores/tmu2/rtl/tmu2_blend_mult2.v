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

reg valid_2;
wire [12:0] pa_2;
wire [12:0] pb_2;
wire [12:0] pc_2;
wire [12:0] pd_2;
reg [15:0] colora_2;
reg [15:0] colorb_2;
reg [15:0] colorc_2;
reg [15:0] colord_2;
reg [fml_depth-1-1:0] dadr_2;
wire [4:0] ra_2 = colora_2[15:11];
wire [5:0] ga_2 = colora_2[10:5];
wire [4:0] ba_2 = colora_2[4:0];
wire [4:0] rb_2 = colorb_2[15:11];
wire [5:0] gb_2 = colorb_2[10:5];
wire [4:0] bb_2 = colorb_2[4:0];
wire [4:0] rc_2 = colorc_2[15:11];
wire [5:0] gc_2 = colorc_2[10:5];
wire [4:0] bc_2 = colorc_2[4:0];
wire [4:0] rd_2 = colord_2[15:11];
wire [5:0] gd_2 = colord_2[10:5];
wire [4:0] bd_2 = colord_2[4:0];

reg valid_3;
reg [fml_depth-1-1:0] dadr_3;

reg valid_4;
wire [16:0] ra_4;
wire [17:0] ga_4;
wire [16:0] ba_4;
wire [16:0] rb_4;
wire [17:0] gb_4;
wire [16:0] bb_4;
wire [16:0] rc_4;
wire [17:0] gc_4;
wire [16:0] bc_4;
wire [16:0] rd_4;
wire [17:0] gd_4;
wire [16:0] bd_4;
reg [fml_depth-1-1:0] dadr_4;

reg valid_5;
reg [16:0] r_5;
reg [17:0] g_5;
reg [16:0] b_5;
reg [fml_depth-1-1:0] dadr_5;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		valid_1 <= 1'b0;
		valid_2 <= 1'b0;
		valid_3 <= 1'b0;
		valid_4 <= 1'b0;
		valid_5 <= 1'b0;
	end else if(pipe_en) begin
		valid_1 <= pipe_stb_i;
		dadr_1 <= dadr;
		colora_1 <= colora;
		colorb_1 <= colorb;
		colorc_1 <= colorc;
		colord_1 <= colord;

		valid_2 <= valid_1;
		dadr_2 <= dadr_1;
		colora_2 <= colora_1;
		colorb_2 <= colorb_1;
		colorc_2 <= colorc_1;
		colord_2 <= colord_1;

		valid_3 <= valid_2;
		dadr_3 <= dadr_2;

		valid_4 <= valid_3;
		dadr_4 <= dadr_3;

		valid_5 <= valid_4;
		r_5 <= ra_4 + rb_4 + rc_4 + rd_4;
		g_5 <= ga_4 + gb_4 + gc_4 + gd_4;
		b_5 <= ba_4 + bb_4 + bc_4 + bd_4;
		dadr_5 <= dadr_4;
	end
end

tmu2_mult2 m_pa(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.a(7'd64 - x_frac),
	.b(7'd64 - y_frac),
	.p(pa_2)
);
tmu2_mult2 m_pb(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.a(x_frac),
	.b(7'd64 - y_frac),
	.p(pb_2)
);
tmu2_mult2 m_pc(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.a(7'd64 - x_frac),
	.b(y_frac),
	.p(pc_2)
);
tmu2_mult2 m_pd(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.a(x_frac),
	.b(y_frac),
	.p(pd_2)
);

tmu2_mult2 m_ra(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.a(pa_2),
	.b(ra_2),
	.p(ra_4)
);
tmu2_mult2 m_ga(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.a(pa_2),
	.b(ga_2),
	.p(ga_4)
);
tmu2_mult2 m_ba(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.a(pa_2),
	.b(ba_2),
	.p(ba_4)
);
tmu2_mult2 m_rb(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.a(pb_2),
	.b(rb_2),
	.p(rb_4)
);
tmu2_mult2 m_gb(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.a(pb_2),
	.b(gb_2),
	.p(gb_4)
);
tmu2_mult2 m_bb(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.a(pb_2),
	.b(bb_2),
	.p(bb_4)
);
tmu2_mult2 m_rc(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.a(pc_2),
	.b(rc_2),
	.p(rc_4)
);
tmu2_mult2 m_gc(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.a(pc_2),
	.b(gc_2),
	.p(gc_4)
);
tmu2_mult2 m_bc(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.a(pc_2),
	.b(bc_2),
	.p(bc_4)
);
tmu2_mult2 m_rd(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.a(pd_2),
	.b(rd_2),
	.p(rd_4)
);
tmu2_mult2 m_gd(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.a(pd_2),
	.b(gd_2),
	.p(gd_4)
);
tmu2_mult2 m_bd(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.a(pd_2),
	.b(bd_2),
	.p(bd_4)
);

/* Glue logic */

assign pipe_stb_o = valid_5;
assign dadr_f = dadr_5;
assign color = {r_5[16:12], g_5[17:12], b_5[16:12]};

assign pipe_en = ~valid_5 | pipe_ack_i;
assign pipe_ack_o = ~valid_5 | pipe_ack_i;

assign busy = valid_1 | valid_2 | valid_3 | valid_4 | valid_5;

endmodule
