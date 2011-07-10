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

`include "setup.v"

module vga #(
	parameter csr_addr = 4'h0,
	parameter fml_depth = 26
) (
	input sys_clk,
	input clk50,
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

	/* Direct Cache Bus */
	output dcb_stb,
	output [fml_depth-1:0] dcb_adr,
	input [63:0] dcb_dat,
	input dcb_hit,
	
	/* VGA pads */
	output vga_psave_n,
	output vga_hsync_n,
	output vga_vsync_n,
	output [7:0] vga_r,
	output [7:0] vga_g,
	output [7:0] vga_b,
	output vga_clk,

	/* DDC */
	inout vga_sda,
	output vga_sdc
);

reg vga_iclk_25;
wire vga_iclk_50;
wire vga_iclk_65;

wire [1:0] clksel;
reg vga_iclk_sel;
wire vga_iclk;

always @(posedge clk50) vga_iclk_25 <= ~vga_iclk_25;
assign vga_iclk_50 = clk50;

DCM_SP #(
	.CLKDV_DIVIDE(2.0),		// 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5

	.CLKFX_DIVIDE(16),		// 1 to 32
	.CLKFX_MULTIPLY(13),		// 2 to 32

	.CLKIN_DIVIDE_BY_2("FALSE"),
	.CLKIN_PERIOD(`CLOCK_PERIOD),
	.CLKOUT_PHASE_SHIFT("NONE"),
	.CLK_FEEDBACK("NONE"),
	.DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"),
	.DUTY_CYCLE_CORRECTION("TRUE"),
	.PHASE_SHIFT(0),
	.STARTUP_WAIT("TRUE")
) clkgen_vga (
	.CLK0(),
	.CLK90(),
	.CLK180(),
	.CLK270(),

	.CLK2X(),
	.CLK2X180(),

	.CLKDV(),
	.CLKFX(vga_iclk_65),
	.CLKFX180(),
	.LOCKED(),
	.CLKFB(),
	.CLKIN(sys_clk),
	.RST(sys_rst),

	.PSEN(1'b0)
);
always @(*) begin
	case(clksel)
		2'd0: vga_iclk_sel = vga_iclk_25;
		2'd1: vga_iclk_sel = vga_iclk_50;
		default: vga_iclk_sel = vga_iclk_65;
	endcase
end
BUFG b(
	.I(vga_iclk_sel),
	.O(vga_iclk)
);

ODDR2 #(
	.DDR_ALIGNMENT("NONE"),
	.INIT(1'b0),
	.SRTYPE("SYNC")
) clock_forward (
	.Q(vga_clk),
	.C0(vga_iclk),
	.C1(~vga_iclk),
	.CE(1'b1),
	.D0(1'b1),
	.D1(1'b0),
	.R(1'b0),
	.S(1'b0)
);

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

	.dcb_stb(dcb_stb),
	.dcb_adr(dcb_adr),
	.dcb_dat(dcb_dat),
	.dcb_hit(dcb_hit),
	
	.vga_clk(vga_iclk),
	.vga_psave_n(vga_psave_n),
	.vga_hsync_n(vga_hsync_n),
	.vga_vsync_n(vga_vsync_n),
	.vga_r(vga_r),
	.vga_g(vga_g),
	.vga_b(vga_b),

	.vga_sda(vga_sda),
	.vga_sdc(vga_sdc),
	
	.clksel(clksel)
);

endmodule
