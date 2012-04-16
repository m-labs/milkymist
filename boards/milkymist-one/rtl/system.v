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

`include "setup.v"
`include "lm32_include.v"

module system(
	input clkin50,

	// Boot ROM
	output [23:0] flash_adr,
	inout [15:0] flash_d,
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
	output videoin_rst_n,
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
	input [11:0] exp,

	// PCB revision
	input [3:0] pcb_revision
);

//------------------------------------------------------------------
// Clock and Reset Generation
//------------------------------------------------------------------
wire hard_reset;
wire reset_button = btn1 & btn2 & btn3;

`ifndef SIMULATION
wire clkin50_b;
IBUFG clk50_ibuf(
	.I(clkin50),
	.O(clkin50_b)
);

wire clk24_pll;
wire phy_clk_pll;
wire clkgen600_fb;
PLL_BASE #(
	.COMPENSATION("INTERNAL"),
	.BANDWIDTH("OPTIMIZED"),
	.CLKOUT0_DIVIDE(25),	// 24 MHz
	.CLKOUT1_DIVIDE(24),	// 25 MHz
	.CLKOUT2_DIVIDE(1),
	.CLKOUT3_DIVIDE(1),
	.CLKOUT4_DIVIDE(1),
	.CLKOUT5_DIVIDE(1),
	.CLKOUT0_PHASE(0.0),
	.CLKOUT1_PHASE(0.0),
	.CLKOUT2_PHASE(0.0),
	.CLKOUT3_PHASE(0.0),
	.CLKOUT4_PHASE(0.0),
	.CLKOUT5_PHASE(0.0),
	.CLKOUT0_DUTY_CYCLE(0.50),
	.CLKOUT1_DUTY_CYCLE(0.50),
	.CLKOUT2_DUTY_CYCLE(0.50),
	.CLKOUT3_DUTY_CYCLE(0.50),
	.CLKOUT4_DUTY_CYCLE(0.50),
	.CLKOUT5_DUTY_CYCLE(0.50),
	.CLKFBOUT_MULT(12),		// 600 MHz
	.DIVCLK_DIVIDE(1),
	.CLKFBOUT_PHASE(0.0),
	.REF_JITTER(0.100),
	.CLKIN_PERIOD(0.000)
) clkgen600 (
	.CLKOUT0(clk24_pll),
	.CLKOUT1(phy_clk_pll),
	.CLKOUT2(),
	.CLKOUT3(),
	.CLKOUT4(),
	.CLKOUT5(),
	.CLKFBOUT(clkgen600_fb),
	.CLKIN(clkin50_b),
	.CLKFBIN(clkgen600_fb),
	.LOCKED(),
	.RST(1'b0)
);

wire clk24;
BUFG clk24_buf(
	.I(clk24_pll),
	.O(clk24)
);

OBUF phy_clk_obuf(
	.I(phy_clk_pll),
	.O(phy_clk)
);

wire usb_clk_pll;
wire sys_clk_pll;
wire sys_clk_n_pll;
wire clkgen720_fb;
PLL_BASE #(
	.COMPENSATION("INTERNAL"),
	.BANDWIDTH("OPTIMIZED"),
	.CLKOUT0_DIVIDE(10),	// 72 MHz
	.CLKOUT1_DIVIDE(9),		// 80 MHz
	.CLKOUT2_DIVIDE(9),		// 80 MHz, 180deg phase shift
	.CLKOUT3_DIVIDE(1),
	.CLKOUT4_DIVIDE(1),
	.CLKOUT5_DIVIDE(1),
	.CLKOUT0_PHASE(0.0),
	.CLKOUT1_PHASE(0.0),
	.CLKOUT2_PHASE(180.0),
	.CLKOUT3_PHASE(0.0),
	.CLKOUT4_PHASE(0.0),
	.CLKOUT5_PHASE(0.0),
	.CLKOUT0_DUTY_CYCLE(0.50),
	.CLKOUT1_DUTY_CYCLE(0.50),
	.CLKOUT2_DUTY_CYCLE(0.50),
	.CLKOUT3_DUTY_CYCLE(0.50),
	.CLKOUT4_DUTY_CYCLE(0.50),
	.CLKOUT5_DUTY_CYCLE(0.50),
	.CLKFBOUT_MULT(30),		// 720 MHz
	.DIVCLK_DIVIDE(1),
	.CLKFBOUT_PHASE(0.0),
	.REF_JITTER(0.100),
	.CLKIN_PERIOD(0.000)
) clkgen720 (
	.CLKOUT0(usb_clk_pll),
	.CLKOUT1(sys_clk_pll),
	.CLKOUT2(sys_clk_n_pll),
	.CLKOUT3(),
	.CLKOUT4(),
	.CLKOUT5(),
	.CLKFBOUT(clkgen720_fb),
	.CLKIN(clk24),
	.CLKFBIN(clkgen720_fb),
	.LOCKED(),
	.RST(1'b0)
);

wire usb_clk;
BUFG clkgen720_b1(
	.I(usb_clk_pll),
	.O(usb_clk)
);

wire sys_clk;
BUFG clkgen720_b2(
	.I(sys_clk_pll),
	.O(sys_clk)
);

wire sys_clk_n;
BUFG clkgen720_b3(
	.I(sys_clk_n_pll),
	.O(sys_clk_n)
);

`else
wire sys_clk = clkin;
wire sys_clk_n = ~clkin;
`endif

reg trigger_reset;
always @(posedge sys_clk) trigger_reset <= hard_reset|reset_button;
reg [19:0] rst_debounce;
reg sys_rst;
initial rst_debounce <= 20'hFFFFF;
initial sys_rst <= 1'b1;
always @(posedge sys_clk) begin
	if(trigger_reset)
		rst_debounce <= 20'hFFFFF;
	else if(rst_debounce != 20'd0)
		rst_debounce <= rst_debounce - 20'd1;
	sys_rst <= rst_debounce != 20'd0;
end

assign ac97_rst_n = ~sys_rst;
assign videoin_rst_n = ~sys_rst;

/*
 * We must release the Flash reset before the system reset
 * because the Flash needs some time to come out of reset
 * and the CPU begins fetching instructions from it
 * as soon as the system reset is released.
 * From datasheet, minimum reset pulse width is 100ns
 * and reset-to-read time is 150ns.
 */

reg [7:0] flash_rstcounter;
initial flash_rstcounter <= 8'd0;
always @(posedge sys_clk) begin
	if(trigger_reset)
		flash_rstcounter <= 8'd0;
	else if(~flash_rstcounter[7])
		flash_rstcounter <= flash_rstcounter + 8'd1;
end

assign flash_rst_n = flash_rstcounter[7];

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
`ifdef CFG_HW_DEBUG_ENABLED
		cpuibus_dat_w,
`endif
		cpudbus_dat_r,
		cpudbus_dat_w,
		ac97bus_dat_r,
		ac97bus_dat_w,
		pfpubus_dat_w,
		tmumbus_dat_r;

wire [3:0]	cpudbus_sel;
`ifdef CFG_HW_DEBUG_ENABLED
wire [3:0]	cpuibus_sel;
`endif

wire		cpudbus_we,
`ifdef CFG_HW_DEBUG_ENABLED
		cpuibus_we,
`endif
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
wire [31:0]	norflash_adr,
		monitor_adr,
		usb_adr,
		eth_adr,
		brg_adr,
		csrbrg_adr;

wire [2:0]	brg_cti;

wire [31:0]	norflash_dat_r,
		norflash_dat_w,
		monitor_dat_r,
		monitor_dat_w,
		usb_dat_r,
		usb_dat_w,
		eth_dat_r,
		eth_dat_w,
		brg_dat_r,
		brg_dat_w,
		csrbrg_dat_r,
		csrbrg_dat_w;

wire [3:0]	norflash_sel,
		monitor_sel,
		usb_sel,
		eth_sel,
		brg_sel;

wire		norflash_we,
		monitor_we,
		usb_we,
		eth_we,
		brg_we,
		csrbrg_we;

wire		norflash_cyc,
		monitor_cyc,
		usb_cyc,
		eth_cyc,
		brg_cyc,
		csrbrg_cyc;

wire		norflash_stb,
		monitor_stb,
		usb_stb,
		eth_stb,
		brg_stb,
		csrbrg_stb;

wire		norflash_ack,
		monitor_ack,
		usb_ack,
		eth_ack,
		brg_ack,
		csrbrg_ack;

//---------------------------------------------------------------------------
// Wishbone switch
//---------------------------------------------------------------------------
// norflash     0x00000000 (shadow @0x80000000)
// debug        0x10000000 (shadow @0x90000000)
// USB          0x20000000 (shadow @0xa0000000)
// Ethernet     0x30000000 (shadow @0xb0000000)
// SDRAM        0x40000000 (shadow @0xc0000000)
// CSR bridge   0x60000000 (shadow @0xe0000000)

// MSB (Bit 31) is ignored for slave address decoding
conbus5x6 #(
	.s0_addr(3'b000), // norflash
	.s1_addr(3'b001), // debug
	.s2_addr(3'b010), // USB
	.s3_addr(3'b011), // Ethernet
	.s4_addr(2'b10),  // SDRAM
	.s5_addr(2'b11)   // CSR
) wbswitch (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	// Master 0
`ifdef CFG_HW_DEBUG_ENABLED
	.m0_dat_i(cpuibus_dat_w),
`else
	.m0_dat_i(32'hx),
`endif
	.m0_dat_o(cpuibus_dat_r),
	.m0_adr_i(cpuibus_adr),
	.m0_cti_i(cpuibus_cti),
`ifdef CFG_HW_DEBUG_ENABLED
	.m0_we_i(cpuibus_we),
	.m0_sel_i(cpuibus_sel),
`else
	.m0_we_i(1'b0),
	.m0_sel_i(4'hf),
`endif
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
	.s0_dat_o(norflash_dat_w),
	.s0_adr_o(norflash_adr),
	.s0_cti_o(),
	.s0_sel_o(norflash_sel),
	.s0_we_o(norflash_we),
	.s0_cyc_o(norflash_cyc),
	.s0_stb_o(norflash_stb),
	.s0_ack_i(norflash_ack),
	// Slave 1
	.s1_dat_i(monitor_dat_r),
	.s1_dat_o(monitor_dat_w),
	.s1_adr_o(monitor_adr),
	.s1_cti_o(),
	.s1_sel_o(monitor_sel),
	.s1_we_o(monitor_we),
	.s1_cyc_o(monitor_cyc),
	.s1_stb_o(monitor_stb),
	.s1_ack_i(monitor_ack),
	// Slave 2
	.s2_dat_i(usb_dat_r),
	.s2_dat_o(usb_dat_w),
	.s2_adr_o(usb_adr),
	.s2_cti_o(),
	.s2_sel_o(usb_sel),
	.s2_we_o(usb_we),
	.s2_cyc_o(usb_cyc),
	.s2_stb_o(usb_stb),
	.s2_ack_i(usb_ack),
	// Slave 3
	.s3_dat_i(eth_dat_r),
	.s3_dat_o(eth_dat_w),
	.s3_adr_o(eth_adr),
	.s3_cti_o(),
	.s3_sel_o(eth_sel),
	.s3_we_o(eth_we),
	.s3_cyc_o(eth_cyc),
	.s3_stb_o(eth_stb),
	.s3_ack_i(eth_ack),
	// Slave 4
	.s4_dat_i(brg_dat_r),
	.s4_dat_o(brg_dat_w),
	.s4_adr_o(brg_adr),
	.s4_cti_o(brg_cti),
	.s4_sel_o(brg_sel),
	.s4_we_o(brg_we),
	.s4_cyc_o(brg_cyc),
	.s4_stb_o(brg_stb),
	.s4_ack_i(brg_ack),
	// Slave 5
	.s5_dat_i(csrbrg_dat_r),
	.s5_dat_o(csrbrg_dat_w),
	.s5_adr_o(csrbrg_adr),
	.s5_cti_o(),
	.s5_sel_o(),
	.s5_we_o(csrbrg_we),
	.s5_cyc_o(csrbrg_cyc),
	.s5_stb_o(csrbrg_stb),
	.s5_ack_i(csrbrg_ack)
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
		csr_dr_memcard,
		csr_dr_ac97,
		csr_dr_pfpu,
		csr_dr_tmu,
		csr_dr_ethernet,
		csr_dr_fmlmeter,
		csr_dr_videoin,
		csr_dr_midi,
		csr_dr_dmx_tx,
		csr_dr_dmx_rx,
		csr_dr_ir,
		csr_dr_usb;

//------------------------------------------------------------------
// FML master wires
//------------------------------------------------------------------
wire [`SDRAM_DEPTH-1:0]	fml_brg_adr,
			fml_vga_adr,
			fml_tmur_adr,
			fml_tmudr_adr,
			fml_tmuw_adr,
			fml_videoin_adr;

wire			fml_brg_stb,
			fml_vga_stb,
			fml_tmur_stb,
			fml_tmudr_stb,
			fml_tmuw_stb,
			fml_videoin_stb;

wire			fml_brg_we,
			fml_tmur_we;

wire			fml_brg_ack,
			fml_vga_ack,
			fml_tmur_ack,
			fml_tmudr_ack,
			fml_tmuw_ack,
			fml_videoin_ack;

wire [7:0]		fml_brg_sel,
			fml_tmur_sel,
			fml_tmuw_sel;

wire [63:0]		fml_brg_dw,
			fml_tmur_dw,
			fml_tmuw_dw,
			fml_videoin_dw;

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
wire fml_eack;
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
	/* Also used as memory test port */
	.m2_adr(fml_tmur_adr),
	.m2_stb(fml_tmur_stb),
	.m2_we(fml_tmur_we),
	.m2_ack(fml_tmur_ack),
	.m2_sel(fml_tmur_sel),
	.m2_di(fml_tmur_dw),
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

	/* Video in */
	.m5_adr(fml_videoin_adr),
	.m5_stb(fml_videoin_stb),
	.m5_we(1'b1),
	.m5_ack(fml_videoin_ack),
	.m5_sel(8'hff),
	.m5_di(fml_videoin_dw),
	.m5_do(),

	.s_adr(fml_adr),
	.s_stb(fml_stb),
	.s_we(fml_we),
	.s_eack(fml_eack),
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
		|csr_dr_memcard
		|csr_dr_ac97
		|csr_dr_pfpu
		|csr_dr_tmu
		|csr_dr_ethernet
		|csr_dr_fmlmeter
		|csr_dr_videoin
		|csr_dr_midi
		|csr_dr_dmx_tx
		|csr_dr_dmx_rx
		|csr_dr_ir
		|csr_dr_usb
	)
);

//---------------------------------------------------------------------------
// WISHBONE to FML bridge
//---------------------------------------------------------------------------
wire dcb_stb;
wire [`SDRAM_DEPTH-1:0] dcb_adr;
wire [63:0] dcb_dat;
wire dcb_hit;

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
	.fml_do(fml_brg_dw),

	.dcb_stb(dcb_stb),
	.dcb_adr(dcb_adr),
	.dcb_dat(dcb_dat),
	.dcb_hit(dcb_hit)
);

//---------------------------------------------------------------------------
// Interrupts
//---------------------------------------------------------------------------
wire uart_irq;
wire gpio_irq;
wire timer0_irq;
wire timer1_irq;
wire ac97crrequest_irq;
wire ac97crreply_irq;
wire ac97dmar_irq;
wire ac97dmaw_irq;
wire pfpu_irq;
wire tmu_irq;
wire ethernetrx_irq;
wire ethernettx_irq;
wire videoin_irq;
wire midi_irq;
wire ir_irq;
wire usb_irq;

wire [31:0] cpu_interrupt;
assign cpu_interrupt = {16'd0,
	usb_irq,
	ir_irq,
	midi_irq,
	videoin_irq,
	ethernettx_irq,
	ethernetrx_irq,
	tmu_irq,
	pfpu_irq,
	ac97dmaw_irq,
	ac97dmar_irq,
	ac97crreply_irq,
	ac97crrequest_irq,
	timer1_irq,
	timer0_irq,
	gpio_irq,
	uart_irq
};

//---------------------------------------------------------------------------
// LM32 CPU
//---------------------------------------------------------------------------
wire bus_errors_en;
wire cpuibus_err;
wire cpudbus_err;
`ifdef CFG_BUS_ERRORS_ENABLED
// Catch NULL pointers and similar errors
// NOTE: ERR is asserted at the same time as ACK, which violates
// Wishbone rule 3.45. But LM32 doesn't care.
reg locked_addr_i;
reg locked_addr_d;
always @(posedge sys_clk) begin
	locked_addr_i <= cpuibus_adr[31:18] == 14'd0;
	locked_addr_d <= cpudbus_adr[31:18] == 14'd0;
end
assign cpuibus_err = bus_errors_en & locked_addr_i & cpuibus_ack;
assign cpudbus_err = bus_errors_en & locked_addr_d & cpudbus_ack;
`else
assign cpuibus_err = 1'b0;
assign cpudbus_err = 1'b0;
`endif

wire ext_break;
lm32_top cpu(
	.clk_i(sys_clk),
	.rst_i(sys_rst),
	.interrupt(cpu_interrupt),

	.I_ADR_O(cpuibus_adr),
	.I_DAT_I(cpuibus_dat_r),
`ifdef CFG_HW_DEBUG_ENABLED
	.I_DAT_O(cpuibus_dat_w),
	.I_SEL_O(cpuibus_sel),
`else
	.I_DAT_O(),
	.I_SEL_O(),
`endif
	.I_CYC_O(cpuibus_cyc),
	.I_STB_O(cpuibus_stb),
	.I_ACK_I(cpuibus_ack),
`ifdef CFG_HW_DEBUG_ENABLED
	.I_WE_O(cpuibus_we),
`else
	.I_WE_O(),
`endif
	.I_CTI_O(cpuibus_cti),
	.I_LOCK_O(),
	.I_BTE_O(),
	.I_ERR_I(cpuibus_err),
	.I_RTY_I(1'b0),
`ifdef CFG_EXTERNAL_BREAK_ENABLED
	.ext_break(ext_break),
`endif

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
	.D_ERR_I(cpudbus_err),
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
	.wb_dat_i(norflash_dat_w),
	.wb_sel_i(norflash_sel),
	.wb_stb_i(norflash_stb),
	.wb_cyc_i(norflash_cyc),
	.wb_ack_o(norflash_ack),
	.wb_we_i(norflash_we),

	.flash_adr(flash_adr),
	.flash_d(flash_d),
	.flash_oe_n(flash_oe_n),
	.flash_we_n(flash_we_n)
);

assign flash_ce_n = 1'b0;

//---------------------------------------------------------------------------
// Monitor ROM / RAM
//---------------------------------------------------------------------------
wire debug_write_lock;
`ifdef CFG_ROM_DEBUG_ENABLED
monitor(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.write_lock(debug_write_lock),

	.wb_adr_i(monitor_adr),
	.wb_dat_o(monitor_dat_r),
	.wb_dat_i(monitor_dat_w),
	.wb_sel_i(monitor_sel),
	.wb_stb_i(monitor_stb),
	.wb_cyc_i(monitor_cyc),
	.wb_ack_o(monitor_ack),
	.wb_we_i(monitor_we)
);
`else
assign monitor_dat_r = 32'bx;
assign monitor_ack = 1'b0;
`endif

//---------------------------------------------------------------------------
// UART
//---------------------------------------------------------------------------
uart #(
	.csr_addr(4'h0),
	.clk_freq(`CLOCK_FREQUENCY),
	.baud(`BAUD_RATE),
	.break_en_default(1'b1)
) uart (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_dw),
	.csr_do(csr_dr_uart),

	.irq(uart_irq),

	.uart_rx(uart_rx),
	.uart_tx(uart_tx),

`ifdef CFG_EXTERNAL_BREAK_ENABLED
	.break(ext_break)
`else
	.break()
`endif
);

//---------------------------------------------------------------------------
// System Controller
//---------------------------------------------------------------------------
wire [13:0] gpio_outputs;
wire [31:0] capabilities;

sysctl #(
	.csr_addr(4'h1),
	.ninputs(7),
	.noutputs(2),
	.clk_freq(`CLOCK_FREQUENCY),
	.systemid(32'h13004D31) /* 1.3.0 final (0) on M1 */
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

	.gpio_inputs({pcb_revision, btn3, btn2, btn1}),
	.gpio_outputs({led2, led1}),

	.debug_write_lock(debug_write_lock),
	.bus_errors_en(bus_errors_en),

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
	.fml_eack(fml_eack),
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
	.sdram_dm(sdram_dm),
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
	.clk50(clkin50_b),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_dw),
	.csr_do(csr_dr_vga),

	.fml_adr(fml_vga_adr),
	.fml_stb(fml_vga_stb),
	.fml_ack(fml_vga_ack),
	.fml_di(fml_vga_dr),

	.dcb_stb(dcb_stb),
	.dcb_adr(dcb_adr),
	.dcb_dat(dcb_dat),
	.dcb_hit(dcb_hit),

	.vga_psave_n(vga_psave_n),
	.vga_hsync_n(vga_hsync_n),
	.vga_vsync_n(vga_vsync_n),
	.vga_r(vga_r),
	.vga_g(vga_g),
	.vga_b(vga_b),
	.vga_clk(vga_clk),

	.vga_sda(vga_sda),
	.vga_sdc(vga_sdc)
);

//---------------------------------------------------------------------------
// Memory card
//---------------------------------------------------------------------------
`ifdef ENABLE_MEMORYCARD
memcard #(
	.csr_addr(4'h4)
) memcard (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_dw),
	.csr_do(csr_dr_memcard),

	.mc_d(mc_d),
	.mc_cmd(mc_cmd),
	.mc_clk(mc_clk)
);
`else
assign csr_dr_memcard = 32'd0;
assign mc_d[3:0] = 4'bz;
assign mc_cmd = 1'bz;
assign mc_clk = 1'b0;
`endif

//---------------------------------------------------------------------------
// AC97
//---------------------------------------------------------------------------
wire ac97_clk_bio;
wire ac97_clk_b;
BUFIO2 bio_ac97(
	.I(ac97_clk),
	.DIVCLK(ac97_clk_bio)
);
BUFG b_ac97(
	.I(ac97_clk_bio),
	.O(ac97_clk_b)
);
`ifdef ENABLE_AC97
ac97 #(
	.csr_addr(4'h5)
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
	.csr_addr(4'h6)
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
	.csr_addr(4'h7),
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
`ifdef ENABLE_MEMTEST
memtest #(
	.csr_addr(4'h7),
	.fml_depth(`SDRAM_DEPTH)
) memtest (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_dw),
	.csr_do(csr_dr_tmu),

	.fml_adr(fml_tmur_adr),
	.fml_stb(fml_tmur_stb),
	.fml_we(fml_tmur_we),
	.fml_ack(fml_tmur_ack),
	.fml_di(fml_tmur_dr),
	.fml_sel(fml_tmur_sel),
	.fml_do(fml_tmur_dw)
);
assign tmu_irq = 1'b0;

assign tmumbus_adr = 32'hx;
assign tmumbus_cti = 3'bxxx;
assign tmumbus_cyc = 1'b0;
assign tmumbus_stb = 1'b0;

assign fml_tmudr_adr = {`SDRAM_DEPTH{1'bx}};
assign fml_tmudr_stb = 1'b0;

assign fml_tmuw_adr = {`SDRAM_DEPTH{1'bx}};
assign fml_tmuw_stb = 1'b0;
assign fml_tmuw_sel = 8'bx;
assign fml_tmuw_dw = 64'bx;
`else
assign csr_dr_tmu = 32'd0;

assign tmu_irq = 1'b0;

assign tmumbus_adr = 32'hx;
assign tmumbus_cti = 3'bxxx;
assign tmumbus_cyc = 1'b0;
assign tmumbus_stb = 1'b0;

assign fml_tmur_adr = {`SDRAM_DEPTH{1'bx}};
assign fml_tmur_stb = 1'b0;
assign fml_tmur_we = 1'bx;
assign fml_tmur_sel = 8'bx;
assign fml_tmur_dw = 64'bx;

assign fml_tmudr_adr = {`SDRAM_DEPTH{1'bx}};
assign fml_tmudr_stb = 1'b0;

assign fml_tmuw_adr = {`SDRAM_DEPTH{1'bx}};
assign fml_tmuw_stb = 1'b0;
assign fml_tmuw_sel = 8'bx;
assign fml_tmuw_dw = 64'bx;
`endif
`endif

//---------------------------------------------------------------------------
// Ethernet
//---------------------------------------------------------------------------
wire phy_tx_clk_b;
BUFG b_phy_tx_clk(
	.I(phy_tx_clk),
	.O(phy_tx_clk_b)
);
wire phy_rx_clk_b;
BUFG b_phy_rx_clk(
	.I(phy_rx_clk),
	.O(phy_rx_clk_b)
);
`ifdef ENABLE_ETHERNET
minimac2 #(
	.csr_addr(4'h8)
) ethernet (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_dw),
	.csr_do(csr_dr_ethernet),

	.irq_rx(ethernetrx_irq),
	.irq_tx(ethernettx_irq),
	
	.wb_adr_i(eth_adr),
	.wb_dat_o(eth_dat_r),
	.wb_dat_i(eth_dat_w),
	.wb_sel_i(eth_sel),
	.wb_stb_i(eth_stb),
	.wb_cyc_i(eth_cyc),
	.wb_ack_o(eth_ack),
	.wb_we_i(eth_we),

	.phy_tx_clk(phy_tx_clk_b),
	.phy_tx_data(phy_tx_data),
	.phy_tx_en(phy_tx_en),
	.phy_tx_er(phy_tx_er),
	.phy_rx_clk(phy_rx_clk_b),
	.phy_rx_data(phy_rx_data),
	.phy_dv(phy_dv),
	.phy_rx_er(phy_rx_er),
	.phy_col(phy_col),
	.phy_crs(phy_crs),
	.phy_mii_clk(phy_mii_clk),
	.phy_mii_data(phy_mii_data),
	.phy_rst_n(phy_rst_n)
);
`else
assign csr_dr_ethernet = 32'd0;
assign eth_dat_r = 32'bx;
assign eth_ack = 1'b0;
assign ethernetrx_irq = 1'b0;
assign ethernettx_irq = 1'b0;
assign phy_tx_data = 4'b0;
assign phy_tx_en = 1'b0;
assign phy_tx_er = 1'b0;
assign phy_mii_clk = 1'b0;
assign phy_mii_data = 1'bz;
assign phy_rst_n = 1'b0;
`endif

//---------------------------------------------------------------------------
// FastMemoryLink usage and performance meter
//---------------------------------------------------------------------------
`ifdef ENABLE_FMLMETER
fmlmeter #(
	.csr_addr(4'h9),
	.fml_depth(`SDRAM_DEPTH)
) fmlmeter (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_dw),
	.csr_do(csr_dr_fmlmeter),

	.fml_stb(fml_stb),
	.fml_ack(fml_eack),
	.fml_we(fml_we),
	.fml_adr(fml_adr)
);
`else
assign csr_dr_fmlmeter = 32'd0;
`endif

//---------------------------------------------------------------------------
// Video Input
//---------------------------------------------------------------------------
wire videoin_llc_b;
BUFG b_videoin(
	.I(videoin_llc),
	.O(videoin_llc_b)
);
`ifdef ENABLE_VIDEOIN
bt656cap #(
	.csr_addr(4'ha),
	.fml_depth(`SDRAM_DEPTH)
) videoin (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_dw),
	.csr_do(csr_dr_videoin),

	.irq(videoin_irq),

	.fml_adr(fml_videoin_adr),
	.fml_stb(fml_videoin_stb),
	.fml_ack(fml_videoin_ack),
	.fml_do(fml_videoin_dw),

	.vid_clk(videoin_llc_b),
	.p(videoin_p),
	.sda(videoin_sda),
	.sdc(videoin_sdc)
);
`else
assign csr_dr_videoin = 32'd0;
assign videoin_irq = 1'b0;

assign fml_videoin_adr = {`SDRAM_DEPTH{1'bx}};
assign fml_videoin_stb = 1'b0;
assign fml_videoin_dw = 64'bx;

assign videoin_sda = 1'bz;
assign videoin_sdc = 1'b0;
`endif

//---------------------------------------------------------------------------
// MIDI
//---------------------------------------------------------------------------
`ifdef ENABLE_MIDI
uart #(
	.csr_addr(4'hb),
	.clk_freq(`CLOCK_FREQUENCY),
	.baud(31250),
	.break_en_default(1'b0)
) midi (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_dw),
	.csr_do(csr_dr_midi),

	.irq(midi_irq),

	.uart_rx(midi_rx),
	.uart_tx(midi_tx)
);
`else
assign csr_dr_midi = 32'd0;
assign midi_irq = 1'b0;
assign midi_tx = 1'b1;
`endif

//---------------------------------------------------------------------------
// DMX
//---------------------------------------------------------------------------
`ifdef ENABLE_DMX
dmx_tx #(
	.csr_addr(4'hc),
	.clk_freq(`CLOCK_FREQUENCY)
) dmx_tx (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_dw),
	.csr_do(csr_dr_dmx_tx),

	.thru(dmxb_r),
	.tx(dmxa_d)
);
assign dmxa_de = 1'b1;
dmx_rx #(
	.csr_addr(4'hd),
	.clk_freq(`CLOCK_FREQUENCY)
) dmx_rx (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_dw),
	.csr_do(csr_dr_dmx_rx),

	.rx(dmxb_r)
);
assign dmxb_de = 1'b0;
assign dmxb_d = 1'b0;
`else
assign csr_dr_dmx_tx = 32'd0;
assign csr_dr_dmx_rx = 32'd0;
assign dmxa_de = 1'b0;
assign dmxa_d = 1'b0;
assign dmxb_de = 1'b0;
assign dmxb_d = 1'b0;
`endif

//---------------------------------------------------------------------------
// IR
//---------------------------------------------------------------------------
`ifdef ENABLE_IR
rc5 #(
	.csr_addr(4'he),
	.clk_freq(`CLOCK_FREQUENCY)
) ir (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_dw),
	.csr_do(csr_dr_ir),

	.rx_irq(ir_irq),

	.rx(~ir_rx)
);
`else
assign csr_dr_ir = 32'd0;
assign ir_irq = 1'b0;
`endif

//---------------------------------------------------------------------------
// USB
//---------------------------------------------------------------------------
`ifdef ENABLE_USB
softusb #(
	.csr_addr(4'hf)
) usb (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.usb_clk(usb_clk),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_dw),
	.csr_do(csr_dr_usb),

	.irq(usb_irq),

	.wb_adr_i(usb_adr),
	.wb_dat_o(usb_dat_r),
	.wb_dat_i(usb_dat_w),
	.wb_sel_i(usb_sel),
	.wb_stb_i(usb_stb),
	.wb_cyc_i(usb_cyc),
	.wb_ack_o(usb_ack),
	.wb_we_i(usb_we),

	.usba_spd(usba_spd),
	.usba_oe_n(usba_oe_n),
	.usba_rcv(usba_rcv),
	.usba_vp(usba_vp),
	.usba_vm(usba_vm),

	.usbb_spd(usbb_spd),
	.usbb_oe_n(usbb_oe_n),
	.usbb_rcv(usbb_rcv),
	.usbb_vp(usbb_vp),
	.usbb_vm(usbb_vm)
);
`else
assign csr_dr_usb = 32'd0;
assign usb_irq = 1'b0;

assign usb_dat_r = 32'bx;
assign usb_ack = 1'b0;

assign usba_spd = 1'b0;
assign usba_oe_n = 1'b0;
assign usba_vp = 1'bz;
assign usba_vm = 1'bz;

assign usbb_spd = 1'b0;
assign usbb_oe_n = 1'b0;
assign usbb_vp = 1'bz;
assign usbb_vm = 1'bz;

// HACK: we need to put something on usb_clk, otherwise the net is
// optimized away and the tools later complain about invalid clock
// constraints. Attribute KEEP on usb_clk won't work for some reason.
(* LOCK_PINS="ALL" *)
FD workaround(
	.C(usb_clk),
	.D(1'b0),
	.Q()
);

`endif

endmodule
