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
	input clkin,
	input resetin,
	
	// Boot ROM
	output [24:0] flash_adr,
	input [31:0] flash_d,
	output flash_byte_n,
	output flash_oe_n,
	output flash_we_n,
	output flash_ce,
	output flash_ac97_reset_n,
	
	output sram_clk,
	output sram_ce_n,
	output sram_zz,

	// UART
	input uart_rxd,
	output uart_txd,

	// DDR SDRAM
	output sdram_clk_p,
	output sdram_clk_n,
	input sdram_clk_fb,
	output sdram_cke,
	output sdram_cs_n,
	output sdram_we_n,
	output sdram_cas_n,
	output sdram_ras_n,
	output [3:0] sdram_dqm,
	output [12:0] sdram_adr,
	output [1:0] sdram_ba,
	inout [31:0] sdram_dq,
	inout [3:0] sdram_dqs,
	
	// GPIO
	input [4:0] btn,     // 5
	output [4:0] btnled, //        5
	output [3:0] led,    //        2 (2 LEDs for UART activity)
	input [7:0] dipsw,   // 8
	output lcd_e,        //        1
	output lcd_rs,       //        1
	output lcd_rw,       //        1
	output [3:0] lcd_d,  //        4
	                     // 13     14

	// VGA
	output vga_psave_n,
	output vga_hsync_n,
	output vga_vsync_n,
	output vga_sync_n,
	output vga_blank_n,
	output [7:0] vga_r,
	output [7:0] vga_g,
	output [7:0] vga_b,
	output vga_clkout,
	
	// SystemACE/USB
	output [6:0] aceusb_a,
	inout [15:0] aceusb_d,
	output aceusb_oe_n,
	output aceusb_we_n,
	input ace_clkin,
	output ace_mpce_n,
	input ace_mpirq,
	output usb_cs_n,
	output usb_hpi_reset_n,
	input usb_hpi_int,
	
	// AC97
	input ac97_clk,
	input ac97_sin,
	output ac97_sout,
	output ac97_sync,

	// PS2
	inout ps2_clk1,
	inout ps2_data1,
	inout ps2_clk2,
	inout ps2_data2,

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
	output phy_mii_clk,
	inout phy_mii_data
);

//------------------------------------------------------------------
// Clock and Reset Generation
//------------------------------------------------------------------
wire sys_clk;
wire hard_reset;

`ifndef SIMULATION
BUFG clkbuf(
	.I(clkin),
	.O(sys_clk)
);
`else
assign sys_clk = clkin;
`endif

`ifndef SIMULATION
/* Synchronize the reset input */
reg rst0;
reg rst1;
always @(posedge sys_clk) rst0 <= resetin;
always @(posedge sys_clk) rst1 <= rst0;

/* Debounce it (counter holds reset for 10.49ms),
 * and generate power-on reset.
 */
reg [19:0] rst_debounce;
reg sys_rst;
initial rst_debounce <= 20'hFFFFF;
initial sys_rst <= 1'b1;
always @(posedge sys_clk) begin
	if(~rst1 | hard_reset) /* reset pin is active low */
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
 * On the ML401, the reset is combined with the AC97
 * reset, which must be held for 1us.
 * Here we use a 7-bit counter that holds reset
 * for 1.28us and makes everybody happy.
 */

reg [7:0] flash_rstcounter;
initial flash_rstcounter <= 8'd0;
always @(posedge sys_clk) begin
	if(~rst1 & ~sys_rst) /* ~sys_rst is for debouncing */
		flash_rstcounter <= 8'd0;
	else if(~flash_rstcounter[7])
		flash_rstcounter <= flash_rstcounter + 8'd1;
end

assign flash_ac97_reset_n = flash_rstcounter[7];

wire ac97_rst_n;
assign ac97_rst_n = flash_rstcounter[7];

/* Just use the same signal for PHY reset */
assign phy_rst_n = flash_rstcounter[7];

`else
wire sys_rst;
assign sys_rst = ~resetin;
`endif

//------------------------------------------------------------------
// Wishbone master wires
//------------------------------------------------------------------
wire [31:0]	cpuibus_adr,
		cpudbus_adr,
		ac97bus_adr,
		pfpubus_adr,
		tmumbus_adr,
		ethernetrxbus_adr,
		ethernettxbus_adr;

wire [2:0]	cpuibus_cti,
		cpudbus_cti,
		ac97bus_cti,
		tmumbus_cti,
		ethernetrxbus_cti,
		ethernettxbus_cti;

wire [31:0]	cpuibus_dat_r,
		cpudbus_dat_r,
		cpudbus_dat_w,
		ac97bus_dat_r,
		ac97bus_dat_w,
		pfpubus_dat_w,
		tmumbus_dat_r,
		ethernetrxbus_dat_w,
		ethernettxbus_dat_r;

wire [3:0]	cpudbus_sel;

wire		cpudbus_we,
		ac97bus_we;

wire		cpuibus_cyc,
		cpudbus_cyc,
		ac97bus_cyc,
		pfpubus_cyc,
		tmumbus_cyc,
		ethernetrxbus_cyc,
		ethernettxbus_cyc;

wire		cpuibus_stb,
		cpudbus_stb,
		ac97bus_stb,
		pfpubus_stb,
		tmumbus_stb,
		ethernetrxbus_stb,
		ethernettxbus_stb;

wire		cpuibus_ack,
		cpudbus_ack,
		ac97bus_ack,
		tmumbus_ack,
		pfpubus_ack,
		ethernetrxbus_ack,
		ethernettxbus_ack;

//------------------------------------------------------------------
// Wishbone slave wires
//------------------------------------------------------------------
wire [31:0]	brg_adr,
		norflash_adr,
		bram_adr,
		csrbrg_adr,
		aceusb_adr;

wire [2:0]	brg_cti,
		bram_cti;

wire [31:0]	brg_dat_r,
		brg_dat_w,
		norflash_dat_r,
		bram_dat_r,
		bram_dat_w,
		csrbrg_dat_r,
		csrbrg_dat_w,
		aceusb_dat_r,
		aceusb_dat_w;

wire [3:0]	brg_sel,
		bram_sel;

wire		brg_we,
		bram_we,
		csrbrg_we,
		aceusb_we;

wire		brg_cyc,
		norflash_cyc,
		bram_cyc,
		csrbrg_cyc,
		aceusb_cyc;

wire		brg_stb,
		norflash_stb,
		bram_stb,
		csrbrg_stb,
		aceusb_stb;

wire		brg_ack,
		norflash_ack,
		bram_ack,
		csrbrg_ack,
		aceusb_ack;

//---------------------------------------------------------------------------
// Wishbone switch
//---------------------------------------------------------------------------
conbus #(
	.s_addr_w(3),
	.s0_addr(3'b000),	// norflash	0x00000000
	.s1_addr(3'b001),	// bram		0x20000000
	.s2_addr(3'b010),	// FML bridge	0x40000000
	.s3_addr(3'b100),	// CSR bridge	0x80000000
	.s4_addr(3'b101)	// aceusb	0xa0000000
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
	// Master 5
	.m5_dat_i(ethernetrxbus_dat_w),
	.m5_dat_o(),
	.m5_adr_i(ethernetrxbus_adr),
	.m5_cti_i(ethernetrxbus_cti),
	.m5_we_i(1'b1),
	.m5_sel_i(4'hf),
	.m5_cyc_i(ethernetrxbus_cyc),
	.m5_stb_i(ethernetrxbus_stb),
	.m5_ack_o(ethernetrxbus_ack),
	// Master 6
	.m6_dat_i(),
	.m6_dat_o(ethernettxbus_dat_r),
	.m6_adr_i(ethernettxbus_adr),
	.m6_cti_i(ethernettxbus_cti),
	.m6_we_i(1'b0),
	.m6_sel_i(4'hf),
	.m6_cyc_i(ethernettxbus_cyc),
	.m6_stb_i(ethernettxbus_stb),
	.m6_ack_o(ethernettxbus_ack),

	// Slave 0
	.s0_dat_i(norflash_dat_r),
	.s0_adr_o(norflash_adr),
	.s0_cyc_o(norflash_cyc),
	.s0_stb_o(norflash_stb),
	.s0_ack_i(norflash_ack),
	// Slave 1
	.s1_dat_i(bram_dat_r),
	.s1_dat_o(bram_dat_w),
	.s1_adr_o(bram_adr),
	.s1_cti_o(bram_cti),
	.s1_sel_o(bram_sel),
	.s1_we_o(bram_we),
	.s1_cyc_o(bram_cyc),
	.s1_stb_o(bram_stb),
	.s1_ack_i(bram_ack),
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
	.s4_dat_i(aceusb_dat_r),
	.s4_dat_o(aceusb_dat_w),
	.s4_adr_o(aceusb_adr),
	.s4_we_o(aceusb_we),
	.s4_cyc_o(aceusb_cyc),
	.s4_stb_o(aceusb_stb),
	.s4_ack_i(aceusb_ack)
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
		csr_dr_ps2,
		csr_dr_mouse,
		csr_dr_ethernet;

//------------------------------------------------------------------
// FML master wires
//------------------------------------------------------------------
wire [`SDRAM_DEPTH-1:0]	fml_brg_adr,
			fml_vga_adr,
			fml_tmur_adr,
			fml_tmuw_adr;

wire			fml_brg_stb,
			fml_vga_stb,
			fml_tmur_stb,
			fml_tmuw_stb;

wire			fml_brg_we;

wire			fml_brg_ack,
			fml_vga_ack,
			fml_tmur_ack,
			fml_tmuw_ack;

wire [7:0]		fml_brg_sel,
			fml_tmuw_sel;

wire [63:0]		fml_brg_dw,
			fml_tmuw_dw;

wire [63:0]		fml_brg_dr,
			fml_vga_dr,
			fml_tmur_dr;

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
	
	/* TMU, pixel read DMA */
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
		|csr_dr_ps2
		|csr_dr_mouse
		|csr_dr_ethernet
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
wire keyboard_irq;
wire mouse_irq;
wire ethernetrx_irq;
wire ethernettx_irq;

wire [31:0] cpu_interrupt;
assign cpu_interrupt = {17'd0,
	ethernettx_irq,
	ethernetrx_irq,
	mouse_irq,
	keyboard_irq,
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
norflash32 #(
	.adr_width(21)
) norflash (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.wb_adr_i(norflash_adr),
	.wb_dat_o(norflash_dat_r),
	.wb_stb_i(norflash_stb),
	.wb_cyc_i(norflash_cyc),
	.wb_ack_o(norflash_ack),
	
	.flash_adr(flash_adr[21:1]),
	.flash_d(flash_d)

);

assign flash_adr[0] = 1'b0;
assign flash_adr[24:22] = 3'b000;

assign flash_byte_n = 1'b1;
assign flash_oe_n = 1'b0;
assign flash_we_n = 1'b1;
assign flash_ce = 1'b1;

/*
 * Disable the SRAM.
 * Since CE_N is a synchronous input
 * we also clock the SRAM so that
 * we make sure it gets the message.
 */
assign sram_clk = sys_clk;
assign sram_ce_n = 1'b1;
assign sram_zz = 1'b1;

//---------------------------------------------------------------------------
// BRAM
//---------------------------------------------------------------------------
bram #(
	.adr_width(12)
) bram (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.wb_adr_i(bram_adr),
	.wb_dat_o(bram_dat_r),
	.wb_dat_i(bram_dat_w),
	.wb_sel_i(bram_sel),
	.wb_stb_i(bram_stb),
	.wb_cyc_i(bram_cyc),
	.wb_ack_o(bram_ack),
	.wb_we_i(bram_we)
);

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
	
	.uart_rxd(uart_rxd),
	.uart_txd(uart_txd)
);

/* LED0 and LED1 are used as TX/RX indicators.
 * Generate long pulses so we have time to see them
 */
reg [18:0] rxcounter;
reg rxled;
always @(posedge sys_clk) begin
	if(~uart_rxd)
		rxcounter <= {19{1'b1}};
	else if(rxcounter != 19'd0)
		rxcounter <= rxcounter - 19'd1;
	rxled <= rxcounter != 19'd0;
end

reg [18:0] txcounter;
reg txled;
always @(posedge sys_clk) begin
	if(~uart_txd)
		txcounter <= {19{1'b1}};
	else if(txcounter != 19'd0)
		txcounter <= txcounter - 20'd1;
	txled <= txcounter != 19'd0;
end

assign led[0] = txled;
assign led[1] = rxled;

//---------------------------------------------------------------------------
// System Controller
//---------------------------------------------------------------------------
wire [13:0] gpio_outputs;

sysctl #(
	.csr_addr(4'h1),
	.ninputs(13),
	.noutputs(14),
	.systemid(32'h58343031) /* X401 */
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

	.gpio_inputs({dipsw, btn}),
	.gpio_outputs(gpio_outputs),

	.hard_reset(hard_reset)
);

/* LED0 and LED1 are used as TX/RX indicators. */

assign led[2] = gpio_outputs[0];
assign led[3] = gpio_outputs[1];
assign btnled = gpio_outputs[6:2];
assign lcd_e = gpio_outputs[7];
assign lcd_rs = gpio_outputs[8];
assign lcd_rw = gpio_outputs[9];
assign lcd_d = gpio_outputs[13:10];

//---------------------------------------------------------------------------
// SystemACE/USB interface
//---------------------------------------------------------------------------
`ifdef ENABLE_ACEUSB
aceusb aceusb(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.wb_cyc_i(aceusb_cyc),
	.wb_stb_i(aceusb_stb),
	.wb_ack_o(aceusb_ack),
	.wb_adr_i(aceusb_adr),
	.wb_dat_i(aceusb_dat_w),
	.wb_dat_o(aceusb_dat_r),
	.wb_we_i(aceusb_we),
	
	.aceusb_a(aceusb_a),
	.aceusb_d(aceusb_d),
	.aceusb_oe_n(aceusb_oe_n),
	.aceusb_we_n(aceusb_we_n),
	.ace_clkin(ace_clkin),
	.ace_mpce_n(ace_mpce_n),
	.ace_mpirq(ace_mpirq),
	.usb_cs_n(usb_cs_n),
	.usb_hpi_reset_n(usb_hpi_reset_n),
	.usb_hpi_int(usb_hpi_int)
);
`else
assign aceusb_a = 7'd0;
assign aceusb_d = 16'bz;
assign aceusb_oe_n = 1'b1;
assign aceusb_we_n = 1'b1;
assign ace_mpce_n = 1'b0;
assign usb_cs_n = 1'b1;
assign usb_hpi_reset_n = 1'b1;
assign aceusb_ack = aceusb_cyc & aceusb_stb;
assign aceusb_dat_r = 32'habadface;
`endif

//---------------------------------------------------------------------------
// DDR SDRAM
//---------------------------------------------------------------------------
ddram #(
	.csr_addr(4'h2)
) ddram (
	.sys_clk(sys_clk),
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
	.sdram_clk_fb(sdram_clk_fb),
	.sdram_cke(sdram_cke),
	.sdram_cs_n(sdram_cs_n),
	.sdram_we_n(sdram_we_n),
	.sdram_cas_n(sdram_cas_n),
	.sdram_ras_n(sdram_ras_n),
	.sdram_dqm(sdram_dqm),
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

	.dcb_stb(dcb_stb),
	.dcb_adr(dcb_adr),
	.dcb_dat(dcb_dat),
	.dcb_hit(dcb_hit),
	
	.vga_psave_n(vga_psave_n),
	.vga_hsync_n(vga_hsync_n),
	.vga_vsync_n(vga_vsync_n),
	.vga_sync_n(vga_sync_n),
	.vga_blank_n(vga_blank_n),
	.vga_r(vga_r),
	.vga_g(vga_g),
	.vga_b(vga_b),
	.vga_clkout(vga_clkout)
);

//---------------------------------------------------------------------------
// AC97
//---------------------------------------------------------------------------
`ifdef ENABLE_AC97
ac97 #(
	.csr_addr(4'h4)
) ac97 (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.ac97_clk(ac97_clk),
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

assign fml_tmuw_adr = {`SDRAM_DEPTH{1'bx}};
assign fml_tmuw_stb = 1'b0;
assign fml_tmuw_sel = 8'bx;
assign fml_tmuw_dw = 64'bx;
`endif

//---------------------------------------------------------------------------
// PS2 Interface
//---------------------------------------------------------------------------
`ifdef ENABLE_PS2_KEYBOARD
ps2 #(
	.csr_addr(4'h7),
	.clk_freq(`CLOCK_FREQUENCY)
) ps2_keyboard (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_dw),
	.csr_do(csr_dr_ps2),

	.ps2_clk(ps2_clk1),
	.ps2_data(ps2_data1),

	.irq(keyboard_irq)

);
`else
assign csr_dr_ps2 = 32'd0;
assign keyboard_irq = 1'd0;
`endif
`ifdef ENABLE_PS2_MOUSE
ps2 #(
	.csr_addr(4'h8),
	.clk_freq(`CLOCK_FREQUENCY)
) ps2_mouse (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_dw),
	.csr_do(csr_dr_mouse),

	.ps2_clk(ps2_clk2),
	.ps2_data(ps2_data2),

	.irq(mouse_irq)

);
`else
assign csr_dr_mouse = 32'd0;
assign mouse_irq = 1'd0;
`endif

`ifdef ENABLE_ETHERNET
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

	.phy_tx_clk(phy_tx_clk),
	.phy_tx_data(phy_tx_data),
	.phy_tx_en(phy_tx_en),
	.phy_tx_er(phy_tx_er),
	.phy_rx_clk(phy_rx_clk),
	.phy_rx_data(phy_rx_data),
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
assign ethernetrxbus_we = 1'bx;
assign ethernetrxbus_cyc = 1'b0;
assign ethernetrxbus_stb = 1'b0;
assign ethernetrxbus_sel = 3'bx;
assign ethernetrxbus_dat_w = 32'bx;

assign ethernetrx_irq = 1'b0;
assign ethernettx_irq = 1'b0;

assign phy_tx_data = 4'b0;
assign phy_tx_en = 1'b0;
assign phy_tx_er = 1'b0;
assign phy_mii_clk = 1'b0;
assign phy_mii_data = 1'bz;
`endif

endmodule
