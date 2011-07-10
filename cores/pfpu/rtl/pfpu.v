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

module pfpu #(
	parameter csr_addr = 4'h0
) (
	input sys_clk,
	input sys_rst,
	
	/* Control interface */
	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output [31:0] csr_do,
	
	output irq,
	
	/* Wishbone DMA master (write only, sel=1111) */
	output [31:0] wbm_dat_o,
	output [31:0] wbm_adr_o,
	output wbm_cyc_o,
	output wbm_stb_o,
	input wbm_ack_i
);

wire alu_rst;
wire [31:0] a;
wire [31:0] b;
wire ifb;
wire [3:0] opcode;
wire [31:0] r;
wire r_valid;
wire dma_en;
wire err_collision;
pfpu_alu alu(
	.sys_clk(sys_clk),
	
	.alu_rst(alu_rst),		/* < from sequencer */
	
	.a(a),				/* < from register file */
	.b(b),				/* < from register file */
	.ifb(ifb),			/* < from register file */
	
	.opcode(opcode),		/* < from program memory */
	
	.r(r),				/* < to register file */
	.r_valid(r_valid),		/* < to register file */

	.dma_en(dma_en),		/* < to DMA engine and sequencer */

	.err_collision(err_collision)	/* < to control interface */
);

wire c_en;
wire [6:0] a_addr;
wire [6:0] b_addr;
wire [6:0] w_addr;
wire [6:0] cr_addr;
wire [31:0] cr_dr;
wire [31:0] cr_dw;
wire cr_w_en;
wire [31:0] r0;
wire [31:0] r1;
wire err_stray;
pfpu_regf regf(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.ifb(ifb),		/* < to ALU */
	.a(a),			/* < to ALU */
	.b(b),			/* < to ALU */
	.r(r),			/* < to ALU */
	.w_en(r_valid),		/* < from ALU */
	
	.a_addr(a_addr),	/* < from program memory */
	.b_addr(b_addr),	/* < from program memory */
	.w_addr(w_addr),	/* < from program memory */
	
	.c_en(c_en),		/* < from sequencer */
	.c_addr(cr_addr),	/* < from control interface */
	.c_do(cr_dr),		/* < to control interface */
	.c_di(cr_dw),		/* < from control interface */
	.c_w_en(cr_w_en),	/* < from control interface */
	
	.r0(r0),		/* < from counters */
	.r1(r1),		/* < from counters */

	.err_stray(err_stray)	/* < to control interface */
);

wire [28:0] dma_base;
wire dma_busy;
wire dma_ack;
pfpu_dma dma(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.dma_en(dma_en),		/* < from ALU */
	.dma_base(dma_base),		/* < from control interface */
	.x(r0[6:0]),			/* < from counters */
	.y(r1[6:0]),			/* < from counters */
	.dma_d1(a),			/* < from register file */
	.dma_d2(b),			/* < from register file */

	.busy(dma_busy),		/* < to sequencer */
	.ack(dma_ack),			/* < to sequencer */

	.wbm_dat_o(wbm_dat_o),
	.wbm_adr_o(wbm_adr_o),
	.wbm_cyc_o(wbm_cyc_o),
	.wbm_stb_o(wbm_stb_o),
	.wbm_ack_i(wbm_ack_i)
);

wire vfirst;
wire vnext;
wire [6:0] hmesh_last;
wire [6:0] vmesh_last;
wire vlast;
pfpu_counters counters(
	.sys_clk(sys_clk),
	
	.first(vfirst),			/* < from sequencer */
	.next(vnext),			/* < from sequencer */
	
	.hmesh_last(hmesh_last),	/* < from control interface */
	.vmesh_last(vmesh_last),	/* < from control interface */
	
	.r0(r0),			/* < to register file */
	.r1(r1),			/* < to register file */
	.last(vlast)			/* < to sequencer */
);

wire pcount_rst;
wire [1:0] cp_page;
wire [8:0] cp_offset;
wire [31:0] cp_dr;
wire [31:0] cp_dw;
wire cp_w_en;
wire [10:0] pc;
pfpu_prog prog(
	.sys_clk(sys_clk),
	
	.count_rst(pcount_rst),	/* < from sequencer */
	.a_addr(a_addr),	/* < to ALU */
	.b_addr(b_addr),	/* < to ALU */
	.opcode(opcode),	/* < to ALU */
	.w_addr(w_addr),	/* < to ALU */

	.c_en(c_en),		/* < from sequencer */
	.c_page(cp_page),	/* < from control interface */
	.c_offset(cp_offset),	/* < from control interface */
	.c_do(cp_dr),		/* < to control interface */
	.c_di(cp_dw),		/* < from control interface */
	.c_w_en(cp_w_en),	/* < from control interface */

	.pc(pc)			/* < to control interface */
);

wire start;
wire busy;
pfpu_seq seq(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.alu_rst(alu_rst),		/* < to ALU */
	
	.dma_en(dma_en),		/* < from ALU */
	.dma_busy(dma_busy),		/* < from DMA engine */
	.dma_ack(dma_ack),		/* < from DMA engine */
	
	.vfirst(vfirst),		/* < to counters */
	.vnext(vnext),			/* < to counters and control interface */
	.vlast(vlast),			/* < from counters */
	
	.pcount_rst(pcount_rst),	/* < to program memory */
	.c_en(c_en),			/* < to register file and program memory */
	
	.start(start),			/* < from control interface */
	.busy(busy)			/* < to control interface */
);

pfpu_ctlif #(
	.csr_addr(csr_addr)
) ctlif (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_di),
	.csr_do(csr_do),
	
	.irq(irq),
	
	.start(start),			/* < to sequencer */
	.busy(busy),			/* < from sequencer */
	
	.dma_base(dma_base),		/* < to DMA engine */
	.hmesh_last(hmesh_last),	/* < to counters */
	.vmesh_last(vmesh_last),	/* < to counters */
	
	.cr_addr(cr_addr),		/* < to register file */
	.cr_di(cr_dr),			/* < from register file */
	.cr_do(cr_dw),			/* < to register file */
	.cr_w_en(cr_w_en),		/* < to register file */
	
	.cp_page(cp_page),		/* < to program memory */
	.cp_offset(cp_offset),		/* < to program memory */
	.cp_di(cp_dr),			/* < from program memory */
	.cp_do(cp_dw),			/* < to program memory */
	.cp_w_en(cp_w_en),		/* < to program memory */

	.vnext(vnext),			/* < from sequencer */
	.err_collision(err_collision),	/* < from ALU */
	.err_stray(err_stray),		/* < from register file */
	.pc(pc),			/* < from program memory */

	.wbm_adr_o(wbm_adr_o),		/* < from DMA engine */
	.wbm_ack_i(wbm_ack_i)		/* < from DMA engine */
);

endmodule
