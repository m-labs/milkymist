/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
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

`include "setup.v"

module vga #(
	parameter csr_addr = 4'h0,
	parameter fml_depth = 26
) (
	input sys_clk,
	input sys_rst,
	
	/* Configuration interface */
	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output [31:0] csr_do,
	
	/* Framebuffer FML 4x64 interface */
	output [fml_depth-1:0] fml_adr,
	output fml_stb,
	input fml_ack,
	input [63:0] fml_di,

	/* VGA pads */
	output vga_psave_n,
	output vga_hsync_n,
	output vga_vsync_n,
	output vga_sync_n,
	output vga_blank_n,
	output [7:0] vga_r,
	output [7:0] vga_g,
	output [7:0] vga_b,
	output vga_clkout
);

wire vga_clk;

reg [1:0] fcounter;
wire [1:0] vga_clk_sel;
always @(posedge sys_clk) fcounter <= fcounter + 2'd1;
BUFGMUX BUFGMUX_vgaclk (
	.O(vga_clk),
	.I0(fcounter[1]),
	.I1(fcounter[0]),
	.S(vga_clk_sel[0])
);

assign vga_clkout = vga_clk;

vgafb #(
	.csr_addr(csr_addr),
	.fml_depth(fml_depth)
) vgafb (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_di),
	.csr_do(csr_do),
	
	.fml_adr(fml_adr),
	.fml_stb(fml_stb),
	.fml_ack(fml_ack),
	.fml_di(fml_di),
	
	.vga_clk(vga_clk),
	.vga_psave_n(vga_psave_n),
	.vga_hsync_n(vga_hsync_n),
	.vga_vsync_n(vga_vsync_n),
	.vga_sync_n(vga_sync_n),
	.vga_blank_n(vga_blank_n),
	.vga_r(vga_r),
	.vga_g(vga_g),
	.vga_b(vga_b),
	.vga_clk_sel(vga_clk_sel)
);

endmodule
