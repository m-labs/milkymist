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

module minimac #(
	parameter csr_addr = 4'h0
) (
	input sys_clk,
	input sys_rst,

	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output [31:0] csr_do,

	output irq_rx,
	output irq_tx,

	// WE=1 and SEL=1111 are assumed
	output [31:0] wbrx_adr_o,
	output [2:0] wbrx_cti_o,
	output wbrx_cyc_o,
	output wbrx_stb_o,
	input wbrx_ack_i,
	output [31:0] wbrx_dat_o,

	// WE=0 is assumed
	output [31:0] wbtx_adr_o,
	output [2:0] wbtx_cti_o,
	output wbtx_cyc_o,
	output wbtx_stb_o,
	input wbtx_ack_i,
	input [31:0] wbtx_dat_i,

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

assign wbrx_cti_o = 3'd0;
assign wbtx_cti_o = 3'd0;

wire rx_rst;
wire tx_rst;

wire rx_valid;
wire [29:0] rx_adr;
wire rx_incrcount;
wire rx_endframe;

wire fifo_full;

wire tx_valid;
wire [29:0] tx_adr;
wire [1:0] tx_bytecount;
wire tx_next;

minimac_ctlif #(
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

	.rx_rst(rx_rst),
	.tx_rst(tx_rst),

	.rx_valid(rx_valid),
	.rx_adr(rx_adr),
	.rx_incrcount(rx_incrcount),
	.rx_endframe(rx_endframe),

	.fifo_full(fifo_full),

	.tx_valid(tx_valid),
	.tx_adr(tx_adr),
	.tx_bytecount(tx_bytecount),
	.tx_next(tx_next),

	.phy_mii_clk(phy_mii_clk),
	.phy_mii_data(phy_mii_data)
);

assign phy_rst_n = ~(rx_rst & tx_rst);

minimac_rx rx(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.rx_rst(rx_rst),

	.wbm_adr_o(wbrx_adr_o),
	.wbm_cyc_o(wbrx_cyc_o),
	.wbm_stb_o(wbrx_stb_o),
	.wbm_ack_i(wbrx_ack_i),
	.wbm_dat_o(wbrx_dat_o),

	.rx_valid(rx_valid),
	.rx_adr(rx_adr),
	.rx_incrcount(rx_incrcount),
	.rx_endframe(rx_endframe),

	.fifo_full(fifo_full),

	.phy_rx_clk(phy_rx_clk),
	.phy_rx_data(phy_rx_data),
	.phy_dv(phy_dv),
	.phy_rx_er(phy_rx_er)
);

minimac_tx tx(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.tx_rst(tx_rst),

	.tx_valid(tx_valid),
	.tx_adr(tx_adr),
	.tx_bytecount(tx_bytecount),
	.tx_next(tx_next),

	.wbtx_adr_o(wbtx_adr_o),
	.wbtx_cyc_o(wbtx_cyc_o),
	.wbtx_stb_o(wbtx_stb_o),
	.wbtx_ack_i(wbtx_ack_i),
	.wbtx_dat_i(wbtx_dat_i),

	.phy_tx_clk(phy_tx_clk),
	.phy_tx_en(phy_tx_en),
	.phy_tx_data(phy_tx_data)
);

assign phy_tx_er = 1'b0;

endmodule
