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

`include "setup.v"

module system(
	input clk50,
	
	// Boot ROM
	output [23:0] flash_adr,
	input [15:0] flash_d,
	output flash_oe_n,
	output flash_we_n,
	output flash_ce_n,
	output flash_rst_n,
	input flash_sts,

	// UART
	input uart_rx,
	output uart_tx,

	// GPIO
	input btn1,
	input btn2,
	input btn3,
	output led1,
	output led2,

	// DDR SDRAM
	output sdram_clk_p,
	output sdram_clk_n,
	output sdram_cke,
	output sdram_cs_n,
	output sdram_we_n,
	output sdram_cas_n,
	output sdram_ras_n,
	output [3:0] sdram_dm,
	output [12:0] sdram_adr,
	output [1:0] sdram_ba,
	inout [31:0] sdram_dq,
	inout [3:0] sdram_dqs,

	// VGA
	output vga_psave_n,
	output vga_hsync_n,
	output vga_vsync_n,
	output [7:0] vga_r,
	output [7:0] vga_g,
	output [7:0] vga_b,
	output vga_clk,
	inout vga_sda,
	output vga_sdc,

	// Memory card
	inout [3:0] mc_d,
	inout mc_cmd,
	output mc_clk,
	
	// AC97
	input ac97_clk,
	input ac97_sin,
	output ac97_sout,
	output ac97_sync,
	output ac97_rst_n,

	// USB
	output usba_spd,
	output usba_oe_n,
	input usba_rcv,
	inout usba_vp,
	inout usba_vm,

	output usbb_spd,
	output usbb_oe_n,
	input usbb_rcv,
	inout usbb_vp,
	inout usbb_vm,

	// Ethernet
	output phy_rst_n,
	input phy_tx_clk,
	output [3:0] phy_tx_data,
	output phy_tx_en,
	output phy_tx_er,
	input phy_rx_clk,
	input [3:0] phy_rx_data,
	input phy_dv,
	input phy_rx_er,
	input phy_col,
	input phy_crs,
	input phy_irq_n,
	output phy_mii_clk,
	inout phy_mii_data,
	output phy_clk,

	// Video Input
	input [7:0] videoin_p,
	input videoin_hs,
	input videoin_vs,
	input videoin_field,
	input videoin_llc,
	input videoin_irq_n,
	input videoin_rst_n,
	inout videoin_sda,
	output videoin_sdc,

	// MIDI
	output midi_tx,
	input midi_rx,

	// DMX512
	input dmxa_r,
	output dmxa_de,
	output dmxa_d,
	input dmxb_r,
	output dmxb_de,
	output dmxb_d,

	// IR
	input ir_rx,

	// Expansion connector
	input [11:0] exp
);

//------------------------------------------------------------------
// Clock and Reset Generation
//------------------------------------------------------------------
wire sys_clk;
wire sys_clk_n;
wire hard_reset;

`ifndef SIMULATION
wire sys_clk_dcm;
wire sys_clk_n_dcm;

DCM_SP #(
	.CLKDV_DIVIDE(1.5),		// 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5

	.CLKFX_DIVIDE(3),		// 1 to 32
	.CLKFX_MULTIPLY(5),		// 2 to 32

	.CLKIN_DIVIDE_BY_2("FALSE"),
	.CLKIN_PERIOD(20.0),
	.CLKOUT_PHASE_SHIFT("NONE"),
	.CLK_FEEDBACK("NONE"),
	.DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"),
	.DFS_FREQUENCY_MODE("LOW"),
	.DLL_FREQUENCY_MODE("LOW"),
	.DUTY_CYCLE_CORRECTION("TRUE"),
	.PHASE_SHIFT(0),
	.STARTUP_WAIT("TRUE")
) clkgen_sys (
	.CLK0(),
	.CLK90(),
	.CLK180(),
	.CLK270(),

	.CLK2X(),
	.CLK2X180(),

	.CLKDV(),
	.CLKFX(sys_clk_dcm),
	.CLKFX180(sys_clk_n_dcm),
	.LOCKED(),
	.CLKFB(),
	.CLKIN(clk50),
	.RST(1'b0),
	.PSEN(1'b0)
);
AUTOBUF b1(
	.I(sys_clk_dcm),
	.O(sys_clk)
);
AUTOBUF b2(
	.I(sys_clk_n_dcm),
	.O(sys_clk_n)
);
`else
assign sys_clk = clkin;
assign sys_clk_n = ~clkin;
`endif

/* Debounce it (counter holds reset for 10.49ms),
 * and generate power-on reset.
 */
reg [19:0] rst_debounce;
reg sys_rst;
initial rst_debounce <= 20'hFFFFF;
initial sys_rst <= 1'b1;
always @(posedge sys_clk) begin
	if(hard_reset)
		rst_debounce <= 20'hFFFFF;
	else if(rst_debounce != 20'd0)
		rst_debounce <= rst_debounce - 20'd1;
	sys_rst <= rst_debounce != 20'd0;
end

/*
 * We must release the Flash reset before the system reset
 * because the Flash needs some time to come out of reset
 * and the CPU begins fetching instructions from it
 * as soon as the system reset is released.
 * From datasheet, minimum reset pulse width is 100ns
 * and reset-to-read time is 150ns.
 * The reset is combined with the AC97 reset, which must be held for 1us.
 * Here we use a 7-bit counter that holds reset
 * for 1.28us and makes everybody happy.
 */

reg [7:0] flash_rstcounter;
initial flash_rstcounter <= 8'd0;
always @(posedge sys_clk) begin
	if(hard_reset)
		flash_rstcounter <= 8'd0;
	else if(~flash_rstcounter[7])
		flash_rstcounter <= flash_rstcounter + 8'd1;
end

assign flash_rst_n = flash_rstcounter[7];
assign ac97_rst_n = flash_rstcounter[7];
assign phy_rst_n = flash_rstcounter[7];

//------------------------------------------------------------------
// Wishbone master wires
//------------------------------------------------------------------
wire [31:0]	cpuibus_adr,
		cpudbus_adr,
		ac97bus_adr,
		pfpubus_adr,
		tmumbus_adr;

wire [2:0]	cpuibus_cti,
		cpudbus_cti,
		ac97bus_cti,
		tmumbus_cti;

wire [31:0]	cpuibus_dat_r,
		cpudbus_dat_r,
		cpudbus_dat_w,
		ac97bus_dat_r,
		ac97bus_dat_w,
		pfpubus_dat_w,
		tmumbus_dat_r;

wire [3:0]	cpudbus_sel;

wire		cpudbus_we,
		ac97bus_we;

wire		cpuibus_cyc,
		cpudbus_cyc,
		ac97bus_cyc,
		pfpubus_cyc,
		tmumbus_cyc;

wire		cpuibus_stb,
		cpudbus_stb,
		ac97bus_stb,
		pfpubus_stb,
		tmumbus_stb;

wire		cpuibus_ack,
		cpudbus_ack,
		ac97bus_ack,
		tmumbus_ack,
		pfpubus_ack;

//------------------------------------------------------------------
// Wishbone slave wires
//------------------------------------------------------------------
wire [31:0]	brg_adr,
		norflash_adr,
		csrbrg_adr;

wire [2:0]	brg_cti;

wire [31:0]	brg_dat_r,
		brg_dat_w,
		norflash_dat_r,
		csrbrg_dat_r,
		csrbrg_dat_w;

wire [3:0]	brg_sel;

wire		brg_we,
		csrbrg_we;

wire		brg_cyc,
		norflash_cyc,
		csrbrg_cyc;

wire		brg_stb,
		norflash_stb,
		csrbrg_stb;

wire		brg_ack,
		norflash_ack,
		csrbrg_ack;

//---------------------------------------------------------------------------
// Wishbone switch
//---------------------------------------------------------------------------
conbus #(
	.s_addr_w(3),
	.s0_addr(3'b000),	// norflash	0x00000000
	.s1_addr(3'b001),	// free		0x20000000
	.s2_addr(3'b010),	// FML bridge	0x40000000
	.s3_addr(3'b100),	// CSR bridge	0x80000000
	.s4_addr(3'b101)	// free		0xa0000000
) conbus (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	// Master 0
	.m0_dat_i(32'hx),
	.m0_dat_o(cpuibus_dat_r),
	.m0_adr_i(cpuibus_adr),
	.m0_cti_i(cpuibus_cti),
	.m0_we_i(1'b0),
	.m0_sel_i(4'hf),
	.m0_cyc_i(cpuibus_cyc),
	.m0_stb_i(cpuibus_stb),
	.m0_ack_o(cpuibus_ack),
	// Master 1
	.m1_dat_i(cpudbus_dat_w),
	.m1_dat_o(cpudbus_dat_r),
	.m1_adr_i(cpudbus_adr),
	.m1_cti_i(cpudbus_cti),
	.m1_we_i(cpudbus_we),
	.m1_sel_i(cpudbus_sel),
	.m1_cyc_i(cpudbus_cyc),
	.m1_stb_i(cpudbus_stb),
	.m1_ack_o(cpudbus_ack),
	// Master 2
	.m2_dat_i(ac97bus_dat_w),
	.m2_dat_o(ac97bus_dat_r),
	.m2_adr_i(ac97bus_adr),
	.m2_cti_i(ac97bus_cti),
	.m2_we_i(ac97bus_we),
	.m2_sel_i(4'hf),
	.m2_cyc_i(ac97bus_cyc),
	.m2_stb_i(ac97bus_stb),
	.m2_ack_o(ac97bus_ack),
	// Master 3
	.m3_dat_i(pfpubus_dat_w),
	.m3_dat_o(),
	.m3_adr_i(pfpubus_adr),
	.m3_cti_i(3'd0),
	.m3_we_i(1'b1),
	.m3_sel_i(4'hf),
	.m3_cyc_i(pfpubus_cyc),
	.m3_stb_i(pfpubus_stb),
	.m3_ack_o(pfpubus_ack),
	// Master 4
	.m4_dat_i(32'bx),
	.m4_dat_o(tmumbus_dat_r),
	.m4_adr_i(tmumbus_adr),
	.m4_cti_i(tmumbus_cti),
	.m4_we_i(1'b0),
	.m4_sel_i(4'hf),
	.m4_cyc_i(tmumbus_cyc),
	.m4_stb_i(tmumbus_stb),
	.m4_ack_o(tmumbus_ack),

	// Slave 0
	.s0_dat_i(norflash_dat_r),
	.s0_adr_o(norflash_adr),
	.s0_cyc_o(norflash_cyc),
	.s0_stb_o(norflash_stb),
	.s0_ack_i(norflash_ack),
	// Slave 1
	.s1_dat_i(32'bx),
	.s1_dat_o(),
	.s1_adr_o(),
	.s1_cti_o(),
	.s1_sel_o(),
	.s1_we_o(),
	.s1_cyc_o(),
	.s1_stb_o(),
	.s1_ack_i(1'b0),
	// Slave 2
	.s2_dat_i(brg_dat_r),
	.s2_dat_o(brg_dat_w),
	.s2_adr_o(brg_adr),
	.s2_cti_o(brg_cti),
	.s2_sel_o(brg_sel),
	.s2_we_o(brg_we),
	.s2_cyc_o(brg_cyc),
	.s2_stb_o(brg_stb),
	.s2_ack_i(brg_ack),
	// Slave 3
	.s3_dat_i(csrbrg_dat_r),
	.s3_dat_o(csrbrg_dat_w),
	.s3_adr_o(csrbrg_adr),
	.s3_we_o(csrbrg_we),
	.s3_cyc_o(csrbrg_cyc),
	.s3_stb_o(csrbrg_stb),
	.s3_ack_i(csrbrg_ack),
	// Slave 4
	.s4_dat_i(32'bx),
	.s4_dat_o(),
	.s4_adr_o(),
	.s4_we_o(),
	.s4_cyc_o(),
	.s4_stb_o(),
	.s4_ack_i(1'b0)
);

//------------------------------------------------------------------
// CSR bus
//------------------------------------------------------------------
wire [13:0]	csr_a;
wire		csr_we;
wire [31:0]	csr_dw;
wire [31:0]	csr_dr_uart,
		csr_dr_sysctl,
		csr_dr_hpdmc,
		csr_dr_vga,
		csr_dr_ac97,
		csr_dr_pfpu,
		csr_dr_tmu,
		csr_dr_ethernet,
		csr_dr_fmlmeter;

//------------------------------------------------------------------
// FML master wires
//------------------------------------------------------------------
wire [`SDRAM_DEPTH-1:0]	fml_brg_adr,
			fml_vga_adr,
			fml_tmur_adr,
			fml_tmudr_adr,
			fml_tmuw_adr;

wire			fml_brg_stb,
			fml_vga_stb,
			fml_tmur_stb,
			fml_tmudr_stb,
			fml_tmuw_stb;

wire			fml_brg_we;

wire			fml_brg_ack,
			fml_vga_ack,
			fml_tmur_ack,
			fml_tmudr_ack,
			fml_tmuw_ack;

wire [7:0]		fml_brg_sel,
			fml_tmuw_sel;

wire [63:0]		fml_brg_dw,
			fml_tmuw_dw;

wire [63:0]		fml_brg_dr,
			fml_vga_dr,
			fml_tmur_dr,
			fml_tmudr_dr;

//------------------------------------------------------------------
// FML slave wires, to memory controller
//------------------------------------------------------------------
wire [`SDRAM_DEPTH-1:0] fml_adr;
wire fml_stb;
wire fml_we;
wire fml_ack;
wire [7:0] fml_sel;
wire [63:0] fml_dw;
wire [63:0] fml_dr;

//---------------------------------------------------------------------------
// FML arbiter
//---------------------------------------------------------------------------
fmlarb #(
	.fml_depth(`SDRAM_DEPTH)
) fmlarb (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	/* VGA framebuffer (high priority) */
	.m0_adr(fml_vga_adr),
	.m0_stb(fml_vga_stb),
	.m0_we(1'b0),
	.m0_ack(fml_vga_ack),
	.m0_sel(8'bx),
	.m0_di(64'bx),
	.m0_do(fml_vga_dr),

	/* WISHBONE bridge */
	.m1_adr(fml_brg_adr),
	.m1_stb(fml_brg_stb),
	.m1_we(fml_brg_we),
	.m1_ack(fml_brg_ack),
	.m1_sel(fml_brg_sel),
	.m1_di(fml_brg_dw),
	.m1_do(fml_brg_dr),

	/* TMU, pixel read DMA (texture) */
	.m2_adr(fml_tmur_adr),
	.m2_stb(fml_tmur_stb),
	.m2_we(1'b0),
	.m2_ack(fml_tmur_ack),
	.m2_sel(8'bx),
	.m2_di(64'bx),
	.m2_do(fml_tmur_dr),

	/* TMU, pixel write DMA */
	.m3_adr(fml_tmuw_adr),
	.m3_stb(fml_tmuw_stb),
	.m3_we(1'b1),
	.m3_ack(fml_tmuw_ack),
	.m3_sel(fml_tmuw_sel),
	.m3_di(fml_tmuw_dw),
	.m3_do(),

	/* TMU, pixel read DMA (destination) */
	.m4_adr(fml_tmudr_adr),
	.m4_stb(fml_tmudr_stb),
	.m4_we(1'b0),
	.m4_ack(fml_tmudr_ack),
	.m4_sel(8'bx),
	.m4_di(64'bx),
	.m4_do(fml_tmudr_dr),

	.s_adr(fml_adr),
	.s_stb(fml_stb),
	.s_we(fml_we),
	.s_ack(fml_ack),
	.s_sel(fml_sel),
	.s_di(fml_dr),
	.s_do(fml_dw)
);

//---------------------------------------------------------------------------
// WISHBONE to CSR bridge
//---------------------------------------------------------------------------
csrbrg csrbrg(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.wb_adr_i(csrbrg_adr),
	.wb_dat_i(csrbrg_dat_w),
	.wb_dat_o(csrbrg_dat_r),
	.wb_cyc_i(csrbrg_cyc),
	.wb_stb_i(csrbrg_stb),
	.wb_we_i(csrbrg_we),
	.wb_ack_o(csrbrg_ack),
	
	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_do(csr_dw),
	/* combine all slave->master data lines with an OR */
	.csr_di(
		 csr_dr_uart
		|csr_dr_sysctl
		|csr_dr_hpdmc
		|csr_dr_vga
		|csr_dr_ac97
		|csr_dr_pfpu
		|csr_dr_tmu
		|csr_dr_ethernet
		|csr_dr_fmlmeter
	)
);

//---------------------------------------------------------------------------
// WISHBONE to FML bridge
//---------------------------------------------------------------------------
fmlbrg #(
	.fml_depth(`SDRAM_DEPTH)
) fmlbrg (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.wb_adr_i(brg_adr),
	.wb_cti_i(brg_cti),
	.wb_dat_o(brg_dat_r),
	.wb_dat_i(brg_dat_w),
	.wb_sel_i(brg_sel),
	.wb_stb_i(brg_stb),
	.wb_cyc_i(brg_cyc),
	.wb_ack_o(brg_ack),
	.wb_we_i(brg_we),
	
	.fml_adr(fml_brg_adr),
	.fml_stb(fml_brg_stb),
	.fml_we(fml_brg_we),
	.fml_ack(fml_brg_ack),
	.fml_sel(fml_brg_sel),
	.fml_di(fml_brg_dr),
	.fml_do(fml_brg_dw)
);

//---------------------------------------------------------------------------
// Interrupts
//---------------------------------------------------------------------------
wire gpio_irq;
wire timer0_irq;
wire timer1_irq;
wire uartrx_irq;
wire uarttx_irq;
wire ac97crrequest_irq;
wire ac97crreply_irq;
wire ac97dmar_irq;
wire ac97dmaw_irq;
wire pfpu_irq;
wire tmu_irq;

wire [31:0] cpu_interrupt;
assign cpu_interrupt = {21'd0,
	tmu_irq,
	pfpu_irq,
	ac97dmaw_irq,
	ac97dmar_irq,
	ac97crreply_irq,
	ac97crrequest_irq,
	uarttx_irq,
	uartrx_irq,
	timer1_irq,
	timer0_irq,
	gpio_irq
};

//---------------------------------------------------------------------------
// LM32 CPU
//---------------------------------------------------------------------------
lm32_top cpu(
	.clk_i(sys_clk),
	.rst_i(sys_rst),
	.interrupt(cpu_interrupt),

	.I_ADR_O(cpuibus_adr),
	.I_DAT_I(cpuibus_dat_r),
	.I_DAT_O(),
	.I_SEL_O(),
	.I_CYC_O(cpuibus_cyc),
	.I_STB_O(cpuibus_stb),
	.I_ACK_I(cpuibus_ack),
	.I_WE_O(),
	.I_CTI_O(cpuibus_cti),
	.I_LOCK_O(),
	.I_BTE_O(),
	.I_ERR_I(1'b0),
	.I_RTY_I(1'b0),

	.D_ADR_O(cpudbus_adr),
	.D_DAT_I(cpudbus_dat_r),
	.D_DAT_O(cpudbus_dat_w),
	.D_SEL_O(cpudbus_sel),
	.D_CYC_O(cpudbus_cyc),
	.D_STB_O(cpudbus_stb),
	.D_ACK_I(cpudbus_ack),
	.D_WE_O (cpudbus_we),
	.D_CTI_O(cpudbus_cti),
	.D_LOCK_O(),
	.D_BTE_O(),
	.D_ERR_I(1'b0),
	.D_RTY_I(1'b0)
);

//---------------------------------------------------------------------------
// Boot ROM
//---------------------------------------------------------------------------
norflash16 #(
	.adr_width(24)
) norflash (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.wb_adr_i(norflash_adr),
	.wb_dat_o(norflash_dat_r),
	.wb_stb_i(norflash_stb),
	.wb_cyc_i(norflash_cyc),
	.wb_ack_o(norflash_ack),
	
	.flash_adr(flash_adr),
	.flash_d(flash_d)
);

assign flash_oe_n = 1'b0;
assign flash_we_n = 1'b1;
assign flash_ce_n = 1'b0;

//---------------------------------------------------------------------------
// UART
//---------------------------------------------------------------------------
uart #(
	.csr_addr(4'h0),
	.clk_freq(`CLOCK_FREQUENCY),
	.baud(`BAUD_RATE)
) uart (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_dw),
	.csr_do(csr_dr_uart),
	
	.rx_irq(uartrx_irq),
	.tx_irq(uarttx_irq),
	
	.uart_rxd(uart_rx),
	.uart_txd(uart_tx)
);

//---------------------------------------------------------------------------
// System Controller
//---------------------------------------------------------------------------
wire [13:0] gpio_outputs;
wire [31:0] capabilities;

sysctl #(
	.csr_addr(4'h1),
	.ninputs(3),
	.noutputs(2),
	.systemid(32'h4D4F4E45) /* MONE */
) sysctl (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.gpio_irq(gpio_irq),
	.timer0_irq(timer0_irq),
	.timer1_irq(timer1_irq),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_dw),
	.csr_do(csr_dr_sysctl),

	.gpio_inputs({btn3, btn2, btn1}),
	.gpio_outputs({led2, led1}),

	.capabilities(capabilities),
	.hard_reset(hard_reset)
);

gen_capabilities gen_capabilities(
	.capabilities(capabilities)
);

//---------------------------------------------------------------------------
// DDR SDRAM
//---------------------------------------------------------------------------
ddram #(
	.csr_addr(4'h2)
) ddram (
	.sys_clk(sys_clk),
	.sys_clk_n(sys_clk_n),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_dw),
	.csr_do(csr_dr_hpdmc),

	.fml_adr(fml_adr),
	.fml_stb(fml_stb),
	.fml_we(fml_we),
	.fml_ack(fml_ack),
	.fml_sel(fml_sel),
	.fml_di(fml_dw),
	.fml_do(fml_dr),
	
	.sdram_clk_p(sdram_clk_p),
	.sdram_clk_n(sdram_clk_n),
	.sdram_cke(sdram_cke),
	.sdram_cs_n(sdram_cs_n),
	.sdram_we_n(sdram_we_n),
	.sdram_cas_n(sdram_cas_n),
	.sdram_ras_n(sdram_ras_n),
	.sdram_dqm(sdram_dm),
	.sdram_adr(sdram_adr),
	.sdram_ba(sdram_ba),
	.sdram_dq(sdram_dq),
	.sdram_dqs(sdram_dqs)
);

//---------------------------------------------------------------------------
// VGA
//---------------------------------------------------------------------------
vga #(
	.csr_addr(4'h3),
	.fml_depth(`SDRAM_DEPTH)
) vga (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_dw),
	.csr_do(csr_dr_vga),
	
	.fml_adr(fml_vga_adr),
	.fml_stb(fml_vga_stb),
	.fml_ack(fml_vga_ack),
	.fml_di(fml_vga_dr),
	
	.vga_psave_n(vga_psave_n),
	.vga_hsync_n(vga_hsync_n),
	.vga_vsync_n(vga_vsync_n),
	.vga_r(vga_r),
	.vga_g(vga_g),
	.vga_b(vga_b),
	.vga_clk(vga_clk)
);

//---------------------------------------------------------------------------
// AC97
//---------------------------------------------------------------------------
`ifdef ENABLE_AC97
wire ac97_clk_b;
AUTOBUF b_ac97(
	.I(ac97_clk),
	.O(ac97_clk_b)
);
ac97 #(
	.csr_addr(4'h4)
) ac97 (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.ac97_clk(ac97_clk_b),
	.ac97_rst_n(ac97_rst_n),
	
	.ac97_sin(ac97_sin),
	.ac97_sout(ac97_sout),
	.ac97_sync(ac97_sync),
	
	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_dw),
	.csr_do(csr_dr_ac97),
	
	.crrequest_irq(ac97crrequest_irq),
	.crreply_irq(ac97crreply_irq),
	.dmar_irq(ac97dmar_irq),
	.dmaw_irq(ac97dmaw_irq),
	
	.wbm_adr_o(ac97bus_adr),
	.wbm_cti_o(ac97bus_cti),
	.wbm_we_o(ac97bus_we),
	.wbm_cyc_o(ac97bus_cyc),
	.wbm_stb_o(ac97bus_stb),
	.wbm_ack_i(ac97bus_ack),
	.wbm_dat_i(ac97bus_dat_r),
	.wbm_dat_o(ac97bus_dat_w)
);

`else
assign csr_dr_ac97 = 32'd0;

assign ac97crrequest_irq = 1'b0;
assign ac97crreply_irq = 1'b0;
assign ac97dmar_irq = 1'b0;
assign ac97dmaw_irq = 1'b0;

assign ac97_sout = 1'b0;
assign ac97_sync = 1'b0;

assign ac97bus_adr = 32'bx;
assign ac97bus_cti = 3'bx;
assign ac97bus_we = 1'bx;
assign ac97bus_cyc = 1'b0;
assign ac97bus_stb = 1'b0;
assign ac97bus_dat_w = 32'bx;
`endif

//---------------------------------------------------------------------------
// Programmable FPU
//---------------------------------------------------------------------------
`ifdef ENABLE_PFPU
pfpu #(
	.csr_addr(4'h5)
) pfpu (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_dw),
	.csr_do(csr_dr_pfpu),
	
	.irq(pfpu_irq),
	
	.wbm_dat_o(pfpubus_dat_w),
	.wbm_adr_o(pfpubus_adr),
	.wbm_cyc_o(pfpubus_cyc),
	.wbm_stb_o(pfpubus_stb),
	.wbm_ack_i(pfpubus_ack)
);

`else
assign csr_dr_pfpu = 32'd0;

assign pfpu_irq = 1'b0;

assign pfpubus_dat_w = 32'hx;
assign pfpubus_adr = 32'hx;
assign pfpubus_cyc = 1'b0;
assign pfpubus_stb = 1'b0;
`endif

//---------------------------------------------------------------------------
// Texture Mapping Unit
//---------------------------------------------------------------------------
`ifdef ENABLE_TMU
tmu2 #(
	.csr_addr(4'h6),
	.fml_depth(`SDRAM_DEPTH)
) tmu (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_dw),
	.csr_do(csr_dr_tmu),

	.irq(tmu_irq),

	.wbm_adr_o(tmumbus_adr),
	.wbm_cti_o(tmumbus_cti),
	.wbm_cyc_o(tmumbus_cyc),
	.wbm_stb_o(tmumbus_stb),
	.wbm_ack_i(tmumbus_ack),
	.wbm_dat_i(tmumbus_dat_r),

	.fmlr_adr(fml_tmur_adr),
	.fmlr_stb(fml_tmur_stb),
	.fmlr_ack(fml_tmur_ack),
	.fmlr_di(fml_tmur_dr),

	.fmldr_adr(fml_tmudr_adr),
	.fmldr_stb(fml_tmudr_stb),
	.fmldr_ack(fml_tmudr_ack),
	.fmldr_di(fml_tmudr_dr),

	.fmlw_adr(fml_tmuw_adr),
	.fmlw_stb(fml_tmuw_stb),
	.fmlw_ack(fml_tmuw_ack),
	.fmlw_sel(fml_tmuw_sel),
	.fmlw_do(fml_tmuw_dw)
);

`else
assign csr_dr_tmu = 32'd0;

assign tmu_irq = 1'b0;

assign tmumbus_adr = 32'hx;
assign tmumbus_cti = 3'bxxx;
assign tmumbus_cyc = 1'b0;
assign tmumbus_stb = 1'b0;

assign fml_tmur_adr = {`SDRAM_DEPTH{1'bx}};
assign fml_tmur_stb = 1'b0;

assign fml_tmudr_adr = {`SDRAM_DEPTH{1'bx}};
assign fml_tmudr_stb = 1'b0;

assign fml_tmuw_adr = {`SDRAM_DEPTH{1'bx}};
assign fml_tmuw_stb = 1'b0;
assign fml_tmuw_sel = 8'bx;
assign fml_tmuw_dw = 64'bx;
`endif

//---------------------------------------------------------------------------
// Ethernet
//---------------------------------------------------------------------------
`ifdef ENABLE_ETHERNET
wire phy_tx_clk_b;
AUTOBUF b_phy_tx_clk(
	.I(phy_tx_clk),
	.O(phy_tx_clk_b)
);
wire phy_rx_clk_b;
AUTOBUF b_phy_rx_clk(
	.I(phy_rx_clk),
	.O(phy_rx_clk_b)
);
minimac #(
	.csr_addr(4'h9)
) ethernet (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_dw),
	.csr_do(csr_dr_ethernet),

	.wbrx_adr_o(ethernetrxbus_adr),
	.wbrx_cti_o(ethernetrxbus_cti),
	.wbrx_cyc_o(ethernetrxbus_cyc),
	.wbrx_stb_o(ethernetrxbus_stb),
	.wbrx_ack_i(ethernetrxbus_ack),
	.wbrx_dat_o(ethernetrxbus_dat_w),

	.wbtx_adr_o(ethernettxbus_adr),
	.wbtx_cti_o(ethernettxbus_cti),
	.wbtx_cyc_o(ethernettxbus_cyc),
	.wbtx_stb_o(ethernettxbus_stb),
	.wbtx_ack_i(ethernettxbus_ack),
	.wbtx_dat_i(ethernettxbus_dat_r),

	.irq_rx(ethernetrx_irq),
	.irq_tx(ethernettx_irq),

	.phy_tx_clk(phy_tx_clk_b),
	.phy_tx_data(phy_tx_data),
	.phy_tx_en(phy_tx_en),
	.phy_tx_er(phy_tx_er),
	.phy_rx_clk(phy_rx_clk),
	.phy_rx_data(phy_rx_data_b),
	.phy_dv(phy_dv),
	.phy_rx_er(phy_rx_er),
	.phy_col(phy_col),
	.phy_crs(phy_crs),
	.phy_mii_clk(phy_mii_clk),
	.phy_mii_data(phy_mii_data)
);
`else
assign csr_dr_ethernet = 32'd0;
assign ethernetrxbus_adr = 32'bx;
assign ethernetrxbus_cti = 3'bx;
assign ethernetrxbus_cyc = 1'b0;
assign ethernetrxbus_stb = 1'b0;
assign ethernetrxbus_dat_w = 32'bx;
assign ethernettxbus_adr = 32'bx;
assign ethernettxbus_cti = 3'bx;
assign ethernettxbus_cyc = 1'b0;
assign ethernettxbus_stb = 1'b0;
assign ethernettxbus_dat_r = 32'bx;
assign ethernetrx_irq = 1'b0;
assign ethernettx_irq = 1'b0;
assign phy_tx_data = 4'b0;
assign phy_tx_en = 1'b0;
assign phy_tx_er = 1'b0;
assign phy_mii_clk = 1'b0;
assign phy_mii_data = 1'bz;
`endif

// TODO
assign phy_clk = 1'b0;

//---------------------------------------------------------------------------
// FastMemoryLink usage and performance meter
//---------------------------------------------------------------------------
`ifdef ENABLE_FMLMETER
fmlmeter #(
	.csr_addr(4'ha)
) fmlmeter (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_dw),
	.csr_do(csr_dr_fmlmeter),

	.fml_stb(fml_stb),
	.fml_ack(fml_ack)
);
`else
assign csr_dr_fmlmeter = 32'd0;
`endif

// TODO
assign vga_sda = 1'b0;
assign vga_sdc = 1'b0;

assign mc_d[3:0] = 4'bz;
assign mc_cmd = 1'bz;
assign mc_clk = 1'b0;

assign usba_spd = 1'b0;
assign usba_oe_n = 1'b0;
assign usba_vp = 1'bz;
assign usba_vm = 1'bz;
assign usbb_spd = 1'b0;
assign usbb_oe_n = 1'b0;
assign usbb_vp = 1'bz;
assign usbb_vm = 1'bz;

assign videoin_sda = 1'bz;
assign videoin_sdc = 1'b0;

assign midi_tx = 1'b0;

assign dmxa_de = 1'b0;
assign dmxa_d = 1'b0;
assign dmxb_de = 1'b0;
assign dmxb_d = 1'b0;

endmodule
