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

module ddram #(
	parameter csr_addr = 4'h0
) (
	input sys_clk,
	input sys_clk_n,
	input sys_rst,
	
	/* Configuration interface */
	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output [31:0] csr_do,
	
	/* FML 4x64 interface */
	input [`SDRAM_DEPTH-1:0] fml_adr,
	input fml_stb,
	input fml_we,
	output fml_ack,
	input [7:0] fml_sel,
	input [63:0] fml_di,
	output [63:0] fml_do,
	
	/* DDRAM pads */
	output sdram_clk_p,
	output sdram_clk_n,
	output sdram_cke,
	output sdram_cs_n,
	output sdram_we_n,
	output sdram_cas_n,
	output sdram_ras_n,
	output [12:0] sdram_adr,
	output [1:0] sdram_ba,
	output [3:0] sdram_dqm,
	inout [31:0] sdram_dq,
	inout [3:0] sdram_dqs
);

`ifndef SIMULATION
wire dqs_clk_dcm;
wire dqs_clk_n_dcm;
wire dqs_clk;
wire dqs_clk_n;
wire locked1 = 1'b1;

ODDR2 #(
	.DDR_ALIGNMENT("NONE"),
	.INIT(1'b0),
	.SRTYPE("SYNC")
) clock_forward_p (
	.Q(sdram_clk_p),
	.C0(sys_clk),
	.C1(sys_clk_n),
	.CE(1'b1),
	.D0(1'b1),
	.D1(1'b0),
	.R(1'b0),
	.S(1'b0)
);

ODDR2 #(
	.DDR_ALIGNMENT("NONE"),
	.INIT(1'b0),
	.SRTYPE("SYNC")
) clock_forward_n (
	.Q(sdram_clk_n),
	.C0(sys_clk),
	.C1(sys_clk_n),
	.CE(1'b1),
	.D0(1'b0),
	.D1(1'b1),
	.R(1'b0),
	.S(1'b0)
);

wire psen;
wire psincdec;
wire psdone;
wire locked2;
DCM_SP #(
	.CLKDV_DIVIDE(1.5),		// 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5

	.CLKFX_DIVIDE(3),		// 1 to 32
	.CLKFX_MULTIPLY(2),		// 2 to 32
	
	.CLKIN_DIVIDE_BY_2("FALSE"),
	.CLKIN_PERIOD(`CLOCK_PERIOD),
	.CLKOUT_PHASE_SHIFT("VARIABLE"),
	.CLK_FEEDBACK("1X"),
	.DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"),
	.DFS_FREQUENCY_MODE("LOW"),
	.DLL_FREQUENCY_MODE("LOW"),
	.DUTY_CYCLE_CORRECTION("TRUE"),
	.PHASE_SHIFT(0),
	.STARTUP_WAIT("FALSE")
) clkgen_dqs (
	.CLK0(dqs_clk_dcm),
	.CLK90(),
	.CLK180(dqs_clk_n_dcm),
	.CLK270(),

	.CLK2X(),
	.CLK2X180(),

	.CLKDV(),
	.CLKFX(),
	.CLKFX180(),
	.LOCKED(locked2),
	.CLKFB(dqs_clk),
	.CLKIN(sys_clk),
	.RST(sys_rst),
	
	.PSEN(psen),
	.PSINCDEC(psincdec),
	.PSDONE(psdone),
	.PSCLK(sys_clk)
);
AUTOBUF b1(
	.I(dqs_clk_dcm),
	.O(dqs_clk)
);
AUTOBUF b2(
	.I(dqs_clk_n_dcm),
	.O(dqs_clk_n)
);
`else
reg dqs_clk;
wire dqs_clk_n;
assign sdram_clk_p = sys_clk;
assign sdram_clk_n = ~sys_clk;
always @(sys_clk) #2.5 dqs_clk <= sys_clk;
assign dqs_clk_n = ~dqs_clk;
wire locked1 = 1'b1;
wire locked2 = 1'b1;
`endif

hpdmc #(
	.csr_addr(csr_addr),
	.sdram_depth(`SDRAM_DEPTH),
	.sdram_columndepth(`SDRAM_COLUMNDEPTH)
) hpdmc (
	.sys_clk(sys_clk),
	.sys_clk_n(sys_clk_n),
	.dqs_clk(dqs_clk),
	.dqs_clk_n(dqs_clk_n),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_di),
	.csr_do(csr_do),
	
	.fml_adr(fml_adr),
	.fml_stb(fml_stb),
	.fml_we(fml_we),
	.fml_ack(fml_ack),
	.fml_sel(fml_sel),
	.fml_di(fml_di),
	.fml_do(fml_do),
	
	.sdram_cke(sdram_cke),
	.sdram_cs_n(sdram_cs_n),
	.sdram_we_n(sdram_we_n),
	.sdram_cas_n(sdram_cas_n),
	.sdram_ras_n(sdram_ras_n),
	.sdram_dqm(sdram_dqm),
	.sdram_adr(sdram_adr),
	.sdram_ba(sdram_ba),
	.sdram_dq(sdram_dq),
	.sdram_dqs(sdram_dqs),
	
	.dqs_psen(psen),
	.dqs_psincdec(psincdec),
	.dqs_psdone(psdone),

	.pll_stat({locked2, locked1})
);

endmodule
