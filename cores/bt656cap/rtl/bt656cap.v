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

module bt656cap #(
	parameter csr_addr = 4'h0,
	parameter fml_depth = 27
) (
	input sys_clk,
	input sys_rst,

	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output [31:0] csr_do,

	output irq,

	output [fml_depth-1:0] fml_adr,
	output fml_stb,
	input fml_ack,
	output [63:0] fml_do,

	input vid_clk,
	input [7:0] p,
	inout sda,
	output sdc
);

wire v_stb;
wire v_ack;
wire v_field;
wire [31:0] v_rgb565;
bt656cap_input in(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.vid_clk(vid_clk),

	.p(p),

	.stb(v_stb),
	.ack(v_ack),
	.field(v_field),
	.rgb565(v_rgb565)
);

wire [1:0] field_filter;
wire in_frame;
wire [fml_depth-1-5:0] fml_adr_base;
wire start_of_frame;
wire next_burst;
wire last_burst;
bt656cap_dma #(
	.fml_depth(fml_depth)
) dma (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.field_filter(field_filter),
	.in_frame(in_frame),
	.fml_adr_base(fml_adr_base),
	.start_of_frame(start_of_frame),
	.next_burst(next_burst),
	.last_burst(last_burst),

	.v_stb(v_stb),
	.v_ack(v_ack),
	.v_field(v_field),
	.v_rgb565(v_rgb565),

	.fml_adr(fml_adr),
	.fml_stb(fml_stb),
	.fml_ack(fml_ack),
	.fml_do(fml_do)
);

bt656cap_ctlif #(
	.fml_depth(fml_depth),
	.csr_addr(csr_addr)
) ctlif (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_di),
	.csr_do(csr_do),

	.irq(irq),

	.field_filter(field_filter),
	.in_frame(in_frame),
	.fml_adr_base(fml_adr_base),
	.start_of_frame(start_of_frame),
	.next_burst(next_burst),
	.last_burst(last_burst),

	.sda(sda),
	.sdc(sdc)
);

endmodule
