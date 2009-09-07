/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 *
 * This program is free and excepted software; you can use it, redistribute it
 * and/or modify it under the terms of the Exception General Public License as
 * published by the Exception License Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the Exception General Public License for more
 * details.
 *
 * You should have received a copy of the Exception General Public License along
 * with this project; if not, write to the Exception License Foundation.
 */

`include "setup.v"

module ddram #(
	parameter csr_addr = 4'h0
) (
	input sys_clk,
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
	input sdram_clk_fb,
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
wire dqs_clk;
wire idelay_clk;
wire idelay_clk_buffered;
wire locked1;
DCM_PS #(
	.CLKDV_DIVIDE(1.5),		// 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5

	.CLKFX_DIVIDE(3),		// 1 to 32
	.CLKFX_MULTIPLY(2),		// 2 to 32
	
	.CLKIN_DIVIDE_BY_2("FALSE"),
	.CLKIN_PERIOD(`CLOCK_PERIOD),
	.CLKOUT_PHASE_SHIFT("NONE"),
	.CLK_FEEDBACK("1X"),
	.DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"),
	.DFS_FREQUENCY_MODE("LOW"),
	.DLL_FREQUENCY_MODE("LOW"),
	.DUTY_CYCLE_CORRECTION("TRUE"),
	.FACTORY_JF(16'hF0F0),
	.PHASE_SHIFT(0),
	.STARTUP_WAIT("FALSE")
) clkgen_sdram (
	.CLK0(sdram_clk_p),
	.CLK90(),
	.CLK180(sdram_clk_n),
	.CLK270(),

	.CLK2X(idelay_clk),
	.CLK2X180(),

	.CLKDV(),
	.CLKFX(),
	.CLKFX180(),
	.LOCKED(locked1),
	.CLKFB(sdram_clk_fb),
	.CLKIN(sys_clk),
	.RST(1'b0)
);

wire psen;
wire psincdec;
wire psdone;
wire locked2;
DCM_PS #(
	.CLKDV_DIVIDE(1.5),		// 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5

	.CLKFX_DIVIDE(3),		// 1 to 32
	.CLKFX_MULTIPLY(2),		// 2 to 32
	
	.CLKIN_DIVIDE_BY_2("FALSE"),
	.CLKIN_PERIOD(`CLOCK_PERIOD),
	.CLKOUT_PHASE_SHIFT("VARIABLE_POSITIVE"),
	.CLK_FEEDBACK("1X"),
	.DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"),
	.DFS_FREQUENCY_MODE("LOW"),
	.DLL_FREQUENCY_MODE("LOW"),
	.DUTY_CYCLE_CORRECTION("TRUE"),
	.FACTORY_JF(16'hF0F0),
	.PHASE_SHIFT(0),
	.STARTUP_WAIT("FALSE")
) clkgen_dqs (
	.CLK0(dqs_clk),
	.CLK90(),
	.CLK180(),
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

BUFG idelay_clk_buffer(
	.I(idelay_clk),
	.O(idelay_clk_buffered)
);

IDELAYCTRL idelay_calibration(
	.RDY(),
	.REFCLK(idelay_clk_buffered),
	.RST(1'b0)
);
`else
reg dqs_clk;
assign sdram_clk_p = sys_clk;
assign sdram_clk_n = ~sys_clk;
always @(sys_clk) #2.5 dqs_clk <= sys_clk;
wire locked1 = 1'b1;
wire locked2 = 1'b1;
`endif

hpdmc #(
	.csr_addr(csr_addr),
	.sdram_depth(`SDRAM_DEPTH),
	.sdram_columndepth(`SDRAM_COLUMNDEPTH)
) hpdmc (
	.sys_clk(sys_clk),
	.sys_clk_n(1'b0), /* < not needed on Virtex-4 */
	.dqs_clk(dqs_clk),
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
