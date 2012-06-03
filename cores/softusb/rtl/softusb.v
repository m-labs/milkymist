/*
 * Milkymist SoC
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

module softusb #(
	parameter csr_addr = 4'h0,
	parameter pmem_width = 12,
	parameter dmem_width = 13,
	parameter initprog = ""
) (
	input sys_clk,
	input sys_rst,

	input usb_clk,

	/* CSR interface */
	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output [31:0] csr_do,

	output irq,

	/* WISHBONE to access RAM */
	input [31:0] wb_adr_i,
	output [31:0] wb_dat_o,
	input [31:0] wb_dat_i,
	input [3:0] wb_sel_i,
	input wb_stb_i,
	input wb_cyc_i,
	output wb_ack_o,
	input wb_we_i,

	/* USB port A */
	output usba_spd,
	output usba_oe_n,
	input usba_rcv,
	inout usba_vp,
	inout usba_vm,

	/* USB port B */
	output usbb_spd,
	output usbb_oe_n,
	input usbb_rcv,
	inout usbb_vp,
	inout usbb_vm
);

wire usb_rst;

wire io_re;
wire io_we;
wire [5:0] io_a;
wire [7:0] io_dw;
wire [7:0] io_dr_timer, io_dr_sie;

softusb_timer timer(
	.usb_clk(usb_clk),
	.usb_rst(usb_rst),

	.io_we(io_we),
	.io_a(io_a),
	.io_do(io_dr_timer)
);

wire [pmem_width-1:0] dbg_pc;

softusb_hostif #(
	.csr_addr(csr_addr),
	.pmem_width(pmem_width)
) hostif (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.usb_clk(usb_clk),
	.usb_rst(usb_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_di),
	.csr_do(csr_do),

	.irq(irq),

	.io_we(io_we),
	.io_a(io_a),

	.dbg_pc(dbg_pc)
);

softusb_sie sie(
	.usb_clk(usb_clk),
	.usb_rst(usb_rst),

	.io_re(io_re),
	.io_we(io_we),
	.io_a(io_a),
	.io_di(io_dw),
	.io_do(io_dr_sie),

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

wire pmem_ce;
wire [pmem_width-1:0] pmem_a;
wire [15:0] pmem_d;

wire dmem_we;
wire [dmem_width-1:0] dmem_a;
wire [7:0] dmem_dr;
wire [7:0] dmem_dw;

softusb_ram #(
	.pmem_width(pmem_width),
	.dmem_width(dmem_width),
	.initprog(initprog)
) ram (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.usb_clk(usb_clk),
	.usb_rst(usb_rst),

	.wb_adr_i(wb_adr_i),
	.wb_dat_o(wb_dat_o),
	.wb_dat_i(wb_dat_i),
	.wb_sel_i(wb_sel_i),
	.wb_stb_i(wb_stb_i),
	.wb_cyc_i(wb_cyc_i),
	.wb_ack_o(wb_ack_o),
	.wb_we_i(wb_we_i),

	.pmem_ce(pmem_ce),
	.pmem_a(pmem_a),
	.pmem_d(pmem_d),

	.dmem_we(dmem_we),
	.dmem_a(dmem_a),
	.dmem_di(dmem_dw),
	.dmem_do(dmem_dr)
);

softusb_navre #(
	.pmem_width(pmem_width),
	.dmem_width(dmem_width)
) navre (
	.clk(usb_clk),
	.rst(usb_rst),

	.pmem_ce(pmem_ce),
	.pmem_a(pmem_a),
	.pmem_d(pmem_d),

	.dmem_we(dmem_we),
	.dmem_a(dmem_a),
	.dmem_di(dmem_dr),
	.dmem_do(dmem_dw),

	.io_re(io_re),
	.io_we(io_we),
	.io_a(io_a),
	.io_do(io_dw),
	.io_di(io_dr_sie|io_dr_timer),

	.irq(8'b0),

	.dbg_pc(dbg_pc)
);

endmodule
