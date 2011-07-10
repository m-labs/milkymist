/*
 * Milkymist SoC
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

module ac97 #(
	parameter csr_addr = 4'h0
) (
	input sys_clk,
	input sys_rst,
	input ac97_clk,
	input ac97_rst_n,
	
	/* Codec interface */
	input ac97_sin,
	output ac97_sout,
	output ac97_sync,
	
	/* Control interface */
	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output [31:0] csr_do,
	
	/* Interrupts */
	output crrequest_irq,
	output crreply_irq,
	output dmar_irq,
	output dmaw_irq,
	
	/* DMA */
	output [31:0] wbm_adr_o,
	output [2:0] wbm_cti_o,
	output wbm_we_o,
	output wbm_cyc_o,
	output wbm_stb_o,
	input wbm_ack_i,
	input [31:0] wbm_dat_i,
	output [31:0] wbm_dat_o
);

wire up_stb;
wire up_ack;
wire up_sync;
wire up_sdata;
wire down_ready;
wire down_stb;
wire down_sync;
wire down_sdata;
ac97_transceiver transceiver(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.ac97_clk(ac97_clk),
	.ac97_rst_n(ac97_rst_n),
	
	.ac97_sin(ac97_sin),
	.ac97_sout(ac97_sout),
	.ac97_sync(ac97_sync),
	
	.up_stb(up_stb),
	.up_ack(up_ack),
	.up_sync(up_sync),
	.up_data(up_sdata),
	
	.down_ready(down_ready),
	.down_stb(down_stb),
	.down_sync(down_sync),
	.down_data(down_sdata)
);

wire down_en;
wire down_next_frame;
wire down_addr_valid;
wire [19:0] down_addr;
wire down_data_valid;
wire [19:0] down_data;
wire down_pcmleft_valid;
wire [19:0] down_pcmleft;
wire down_pcmright_valid;
wire [19:0] down_pcmright;
ac97_framer framer(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	/* to transceiver */
	.down_ready(down_ready),
	.down_stb(down_stb),
	.down_sync(down_sync),
	.down_data(down_sdata),
	
	/* frame data */
	.en(down_en),
	.next_frame(down_next_frame),
	.addr_valid(down_addr_valid),
	.addr(down_addr),
	.data_valid(down_data_valid),
	.data(down_data),
	.pcmleft_valid(down_pcmleft_valid),
	.pcmleft(down_pcmleft),
	.pcmright_valid(down_pcmright_valid),
	.pcmright(down_pcmright)
);

wire up_en;
wire up_next_frame;
wire up_frame_valid;
wire up_addr_valid;
wire [19:0] up_addr;
wire up_data_valid;
wire [19:0] up_data;
wire up_pcmleft_valid;
wire [19:0] up_pcmleft;
wire up_pcmright_valid;
wire [19:0] up_pcmright;
ac97_deframer deframer(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.up_stb(up_stb),
	.up_ack(up_ack),
	.up_sync(up_sync),
	.up_data(up_sdata),
	
	.en(up_en),
	.next_frame(up_next_frame),
	.frame_valid(up_frame_valid),
	.addr_valid(up_addr_valid),
	.addr(up_addr),
	.data_valid(up_data_valid),
	.data(up_data),
	.pcmleft_valid(up_pcmleft_valid),
	.pcmleft(up_pcmleft),
	.pcmright_valid(up_pcmright_valid),
	.pcmright(up_pcmright)
);

wire dmar_en;
wire [29:0] dmar_addr;
wire [15:0] dmar_remaining;
wire dmar_next;
wire dmaw_en;
wire [29:0] dmaw_addr;
wire [15:0] dmaw_remaining;
wire dmaw_next;
ac97_ctlif #(
	.csr_addr(csr_addr)
) ctlif (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_di),
	.csr_do(csr_do),
	
	.crrequest_irq(crrequest_irq),
	.crreply_irq(crreply_irq),
	.dmar_irq(dmar_irq),
	.dmaw_irq(dmaw_irq),
	
	.down_en(down_en),
	.down_next_frame(down_next_frame),
	.down_addr_valid(down_addr_valid),
	.down_addr(down_addr),
	.down_data_valid(down_data_valid),
	.down_data(down_data),

	.up_en(up_en),
	.up_next_frame(up_next_frame),
	.up_frame_valid(up_frame_valid),
	.up_addr_valid(up_addr_valid),
	.up_addr(up_addr),
	.up_data_valid(up_data_valid),
	.up_data(up_data),
	
	.dmar_en(dmar_en),
	.dmar_addr(dmar_addr),
	.dmar_remaining(dmar_remaining),
	.dmar_next(dmar_next),
	.dmaw_en(dmaw_en),
	.dmaw_addr(dmaw_addr),
	.dmaw_remaining(dmaw_remaining),
	.dmaw_next(dmaw_next)
);

ac97_dma dma(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.wbm_adr_o(wbm_adr_o),
	.wbm_cti_o(wbm_cti_o),
	.wbm_we_o(wbm_we_o),
	.wbm_cyc_o(wbm_cyc_o),
	.wbm_stb_o(wbm_stb_o),
	.wbm_ack_i(wbm_ack_i),
	.wbm_dat_i(wbm_dat_i),
	.wbm_dat_o(wbm_dat_o),
	
	.down_en(down_en),
	.down_next_frame(down_next_frame),
	.down_pcmleft_valid(down_pcmleft_valid),
	.down_pcmleft(down_pcmleft),
	.down_pcmright_valid(down_pcmright_valid),
	.down_pcmright(down_pcmright),
	
	.up_en(up_en),
	.up_next_frame(up_next_frame),
	.up_frame_valid(up_frame_valid),
	.up_pcmleft_valid(up_pcmleft_valid),
	.up_pcmleft(up_pcmleft),
	.up_pcmright_valid(up_pcmright_valid),
	.up_pcmright(up_pcmright),
	
	.dmar_en(dmar_en),
	.dmar_addr(dmar_addr),
	.dmar_remaining(dmar_remaining),
	.dmar_next(dmar_next),
	.dmaw_en(dmaw_en),
	.dmaw_addr(dmaw_addr),
	.dmaw_remaining(dmaw_remaining),
	.dmaw_next(dmaw_next)
);

endmodule
