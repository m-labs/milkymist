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

module minimac2 #(
	parameter csr_addr = 4'h0
) (
	input sys_clk,
	input sys_rst,

	/* CSR */
	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output [31:0] csr_do,

	/* IRQ */
	output irq_rx,
	output irq_tx,

	/* WISHBONE to access RAM */
	input [31:0] wb_adr_i,
	output [31:0] wb_dat_o,
	input [31:0] wb_dat_i,
	input [3:0] wb_sel_i,
	input wb_stb_i,
	input wb_cyc_i,
	output wb_ack_o,
	input wb_we_i,

	/* To PHY */
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
	inout phy_mii_data,
	output phy_rst_n
);

wire [1:0] sys_rx_ready;
wire [1:0] sys_rx_done;
wire [10:0] sys_rx_count_0;
wire [10:0] sys_rx_count_1;
wire sys_tx_start;
wire sys_tx_done;
wire [10:0] sys_tx_count;
wire [1:0] phy_rx_ready;
wire [1:0] phy_rx_done;
wire [10:0] phy_rx_count_0;
wire [10:0] phy_rx_count_1;
wire phy_tx_start;
wire phy_tx_done;
wire [10:0] phy_tx_count;

minimac2_ctlif #(
	.csr_addr(csr_addr)
) ctlif (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_di),
	.csr_do(csr_do),

	.irq_rx(irq_rx),
	.irq_tx(irq_tx),

	.rx_ready(sys_rx_ready),
	.rx_done(sys_rx_done),
	.rx_count_0(sys_rx_count_0),
	.rx_count_1(sys_rx_count_1),
	
	.tx_start(sys_tx_start),
	.tx_done(sys_tx_done),
	.tx_count(sys_tx_count),

	.phy_mii_clk(phy_mii_clk),
	.phy_mii_data(phy_mii_data),
	.phy_rst_n(phy_rst_n)
);

minimac2_sync sync(
	.sys_clk(sys_clk),
	.phy_rx_clk(phy_rx_clk),
	.phy_tx_clk(phy_tx_clk),
	
	.sys_rx_ready(sys_rx_ready),
	.sys_rx_done(sys_rx_done),
	.sys_rx_count_0(sys_rx_count_0),
	.sys_rx_count_1(sys_rx_count_1),
	.sys_tx_start(sys_tx_start),
	.sys_tx_done(sys_tx_done),
	.sys_tx_count(sys_tx_count),
	
	.phy_rx_ready(phy_rx_ready),
	.phy_rx_done(phy_rx_done),
	.phy_rx_count_0(phy_rx_count_0),
	.phy_rx_count_1(phy_rx_count_1),
	.phy_tx_start(phy_tx_start),
	.phy_tx_done(phy_tx_done),
	.phy_tx_count(phy_tx_count)
);

wire [7:0] rxb0_dat;
wire [10:0] rxb0_adr;
wire rxb0_we;
wire [7:0] rxb1_dat;
wire [10:0] rxb1_adr;
wire rxb1_we;
wire [7:0] txb_dat;
wire [10:0] txb_adr;
minimac2_memory memory(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.phy_rx_clk(phy_rx_clk),
	.phy_tx_clk(phy_tx_clk),

	.wb_adr_i(wb_adr_i),
	.wb_dat_o(wb_dat_o),
	.wb_dat_i(wb_dat_i),
	.wb_sel_i(wb_sel_i),
	.wb_stb_i(wb_stb_i),
	.wb_cyc_i(wb_cyc_i),
	.wb_ack_o(wb_ack_o),
	.wb_we_i(wb_we_i),
	
	.rxb0_dat(rxb0_dat),
	.rxb0_adr(rxb0_adr),
	.rxb0_we(rxb0_we),
	.rxb1_dat(rxb1_dat),
	.rxb1_adr(rxb1_adr),
	.rxb1_we(rxb1_we),
	
	.txb_dat(txb_dat),
	.txb_adr(txb_adr)
);

minimac2_tx tx(
	.phy_tx_clk(phy_tx_clk),
	
	.tx_start(phy_tx_start),
	.tx_done(phy_tx_done),
	.tx_count(phy_tx_count),
	.txb_dat(txb_dat),
	.txb_adr(txb_adr),
	
	.phy_tx_en(phy_tx_en),
	.phy_tx_data(phy_tx_data)
);
assign phy_tx_er = 1'b0;

minimac2_rx rx(
	.phy_rx_clk(phy_rx_clk),
	
	.rx_ready(phy_rx_ready),
	.rx_done(phy_rx_done),
	.rx_count_0(phy_rx_count_0),
	.rx_count_1(phy_rx_count_1),
	
	.rxb0_dat(rxb0_dat),
	.rxb0_adr(rxb0_adr),
	.rxb0_we(rxb0_we),
	.rxb1_dat(rxb1_dat),
	.rxb1_adr(rxb1_adr),
	.rxb1_we(rxb1_we),
	
	.phy_dv(phy_dv),
	.phy_rx_data(phy_rx_data),
	.phy_rx_er(phy_rx_er)
);

endmodule
