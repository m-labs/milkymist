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

module system(
	input clkin,
	input resetin,
	
	// Boot ROM
	output [21:0] flash_adr,
	input [7:0] flash_d,
	output flash_byte_n,
	output flash_oe_n,
	output flash_we_n,
	output flash_ce_n,
	output flash_reset_n,

	// UART
	input uart_rxd,
	output uart_txd,

	// GPIO
	input [2:0] btn,    // 3
	output [3:0] led    //        2 (2 LEDs for UART activity)
);

//------------------------------------------------------------------
// Clock and Reset Generation
//------------------------------------------------------------------
wire sys_clk;

`ifndef SIMULATION
DCM_SP #(
	.CLKDV_DIVIDE(1.5), // 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5

	.CLKFX_DIVIDE(1), // 1 to 32
	.CLKFX_MULTIPLY(4), // 2 to 32

	.CLKIN_DIVIDE_BY_2("FALSE"),
	.CLKIN_PERIOD(62.5),
	.CLKOUT_PHASE_SHIFT("NONE"),
	.CLK_FEEDBACK("NONE"),
	.DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"),
	.DFS_FREQUENCY_MODE("LOW"),
	.DLL_FREQUENCY_MODE("LOW"),
	.DUTY_CYCLE_CORRECTION("TRUE"),
	.FACTORY_JF(16'hF0F0),
	.PHASE_SHIFT(0),
	.STARTUP_WAIT("TRUE")
) clkgen (
	.CLK0(),
	.CLK90(),
	.CLK180(),
	.CLK270(),

	.CLK2X(),
	.CLK2X180(),

	.CLKDV(),
	.CLKFX(sys_clk),
	.CLKFX180(),
	.LOCKED(),
	.CLKFB(),
	.CLKIN(clkin),
	.RST(1'b0)
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

/* Debounce it
 * and generate power-on reset.
 */
reg [19:0] rst_debounce;
reg sys_rst;
initial rst_debounce <= 20'hFFFFF;
initial sys_rst <= 1'b1;
always @(posedge sys_clk) begin
	if(rst1)
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
 */

reg [7:0] flash_rstcounter;
initial flash_rstcounter <= 8'd0;
always @(posedge sys_clk) begin
	if(~sys_rst)
		flash_rstcounter <= 8'd0;
	else if(~flash_rstcounter[7])
		flash_rstcounter <= flash_rstcounter + 8'd1;
end

assign flash_reset_n = ~flash_rstcounter[7];

`else
wire sys_rst;
assign sys_rst = resetin;
`endif

//------------------------------------------------------------------
// Wishbone master wires
//------------------------------------------------------------------
wire [31:0]	cpuibus_adr,
		cpudbus_adr;

wire [2:0]	cpuibus_cti,
		cpudbus_cti;

wire [31:0]	cpuibus_dat_r,
		cpudbus_dat_r,
		cpudbus_dat_w;

wire [3:0]	cpudbus_sel;

wire		cpudbus_we;

wire		cpuibus_cyc,
		cpudbus_cyc;

wire		cpuibus_stb,
		cpudbus_stb;

wire		cpuibus_ack,
		cpudbus_ack;

//------------------------------------------------------------------
// Wishbone slave wires
//------------------------------------------------------------------
wire [31:0]	brg_adr,
		norflash_adr,
		bram_adr,
		csrbrg_adr;

wire [2:0]	brg_cti,
		bram_cti;

wire [31:0]	norflash_dat_r,
		bram_dat_r,
		bram_dat_w,
		csrbrg_dat_r,
		csrbrg_dat_w;

wire [3:0]	bram_sel;

wire		bram_we,
		csrbrg_we,
		aceusb_we;

wire		norflash_cyc,
		bram_cyc,
		csrbrg_cyc;

wire		norflash_stb,
		bram_stb,
		csrbrg_stb;

wire		norflash_ack,
		bram_ack,
		csrbrg_ack;

//---------------------------------------------------------------------------
// Wishbone switch
//---------------------------------------------------------------------------
conbus #(
	.s_addr_w(3),
	.s0_addr(3'b000),	// norflash	0x00000000
	.s1_addr(3'b001),	// bram		0x20000000
	.s2_addr(3'b010),	// free		0x40000000
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
	.m2_dat_i(32'bx),
	.m2_dat_o(),
	.m2_adr_i(32'bx),
	.m2_cti_i(3'bx),
	.m2_we_i(1'bx),
	.m2_sel_i(4'bx),
	.m2_cyc_i(1'b0),
	.m2_stb_i(1'b0),
	.m2_ack_o(),
	// Master 3
	.m3_dat_i(32'bx),
	.m3_dat_o(),
	.m3_adr_i(32'bx),
	.m3_cti_i(3'bx),
	.m3_we_i(1'bx),
	.m3_sel_i(4'bx),
	.m3_cyc_i(1'b0),
	.m3_stb_i(1'b0),
	.m3_ack_o(),
	// Master 4
	.m4_dat_i(32'bx),
	.m4_dat_o(),
	.m4_adr_i(32'bx),
	.m4_cti_i(3'bx),
	.m4_we_i(1'bx),
	.m4_sel_i(4'bx),
	.m4_cyc_i(1'b0),
	.m4_stb_i(1'b0),
	.m4_ack_o(),

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
	.s2_dat_i(32'bx),
	.s2_dat_o(),
	.s2_adr_o(),
	.s2_cti_o(),
	.s2_sel_o(),
	.s2_we_o(),
	.s2_cyc_o(),
	.s2_stb_o(),
	.s2_ack_i(1'b0),
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
		csr_dr_sysctl;

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
	)
);


//---------------------------------------------------------------------------
// Interrupts
//---------------------------------------------------------------------------
wire gpio_irq;
wire timer0_irq;
wire timer1_irq;
wire uartrx_irq;
wire uarttx_irq;

wire [31:0] cpu_interrupt_n;
assign cpu_interrupt_n = {{27{1'b1}},
	~uarttx_irq,
	~uartrx_irq,
	~timer1_irq,
	~timer0_irq,
	~gpio_irq
};

//---------------------------------------------------------------------------
// LM32 CPU
//---------------------------------------------------------------------------
lm32_top cpu(
	.clk_i(sys_clk),
	.rst_i(sys_rst),
	.interrupt_n(cpu_interrupt_n),

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
norflash8 #(
	.adr_width(22)
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

assign flash_byte_n = 1'b0;
assign flash_oe_n = 1'b0;
assign flash_we_n = 1'b1;
assign flash_ce_n = 1'b0;

//---------------------------------------------------------------------------
// BRAM
//---------------------------------------------------------------------------
//
// On this board, we have 16k of SRAM instead of 4k
// so that we have space for loading some programs.
//
bram #(
	.adr_width(14)
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
		txcounter <= txcounter - 19'd1;
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
	.ninputs(3),
	.noutputs(2),
	.systemid(32'h53334145) /* S3AE */
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

	.gpio_inputs(btn),
	.gpio_outputs(led[3:2]) /* LED0 and LED1 are used as TX/RX indicators */
);

endmodule
