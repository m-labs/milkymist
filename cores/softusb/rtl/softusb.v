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

module softusb #(
	parameter csr_addr = 4'h0
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

wire zpu_we;
wire [3:0] zpu_sel;
wire [31:0] zpu_a;
wire [31:0] zpu_w;
reg [31:0] zpu_r;

wire sel_ram = zpu_a[31:30] == 2'b00;
wire sel_timer = zpu_a[31:30] == 2'b01;
wire sel_hostif = zpu_a[31:30] == 2'b10;
wire sel_sie = zpu_a[31:30] == 2'b11;

wire [31:0] zpu_r_ram;
wire [31:0] zpu_r_timer;
wire [31:0] zpu_r_hostif;
wire [31:0] zpu_r_sie;

reg [1:0] zpu_a_r;
always @(posedge usb_clk)
	zpu_a_r <= zpu_a[31:30];

always @(*) begin
	case(zpu_a_r)
		2'b00: zpu_r = zpu_r_ram;
		2'b01: zpu_r = zpu_r_timer;
		2'b10: zpu_r = zpu_r_hostif;
		default: zpu_r = zpu_r_sie;
	endcase
end

softusb_ram ram(
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

	.zpu_we(sel_ram & zpu_we),
	.zpu_sel(zpu_sel),
	.zpu_a(zpu_a),
	.zpu_dat_i(zpu_w),
	.zpu_dat_o(zpu_r_ram)
);

wire usb_rst;

softusb_timer timer(
	.usb_clk(usb_clk),
	.usb_rst(usb_rst),

	.zpu_we(sel_timer & zpu_we),
	.zpu_dat_o(zpu_r_timer)
);

softusb_hostif #(
	.csr_addr(csr_addr)
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

	.zpu_we(sel_hostif & zpu_we)
);
assign zpu_r_hostif = 32'bx;

softusb_sie sie(
	.usb_clk(usb_clk),
	.usb_rst(usb_rst),

	.zpu_we(sel_sie & zpu_we),
	.zpu_a(zpu_a),
	.zpu_dat_i(zpu_w),
	.zpu_dat_o(zpu_r_sie),

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

wire zpu_re;
reg zpu_ack;

softusb_zpu_core zpu(
	.clk(usb_clk),
	.reset(usb_rst),
	
	.mem_read(zpu_re),
	.mem_write(zpu_we),
	.mem_done(zpu_ack),
	.mem_addr(zpu_a),
	.mem_data_read(zpu_r),
	.mem_data_write(zpu_w),
	.byte_select(zpu_sel)
);

always @(posedge usb_clk) begin
	if(usb_rst)
		zpu_ack <= 1'b0;
	else begin
		if((zpu_re|zpu_we) & ~zpu_ack)
			zpu_ack <= 1'b1;
		else
			zpu_ack <= 1'b0;
	end
end

endmodule

