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

module tb_softusb();

reg sys_clk;
reg sys_rst;

reg usb_clk;

reg [31:0] wb_adr_i;
reg [31:0] wb_dat_i;
wire [31:0] wb_dat_o;
reg wb_cyc_i;
reg wb_stb_i;
reg wb_we_i;
wire wb_ack_o;

reg [13:0] csr_a;
reg csr_we;
reg [31:0] csr_di;
wire [31:0] csr_do;

wire irq;

/* 100MHz system clock */
initial sys_clk = 1'b0;
always #5 sys_clk = ~sys_clk;

/* 50MHz USB clock (should be 48) */
initial usb_clk = 1'b0;
always #10 usb_clk = ~usb_clk;

wire usba_vp;
wire usba_vm;
softusb dut(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.usb_clk(usb_clk),
	
	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_do(csr_do),
	.csr_di(csr_di),
	
	.irq(irq),
	
	.wb_adr_i(wb_adr_i),
	.wb_dat_i(wb_dat_i),
	.wb_dat_o(wb_dat_o),
	.wb_cyc_i(wb_cyc_i),
	.wb_stb_i(wb_stb_i),
	.wb_we_i(wb_we_i),
	.wb_sel_i(4'hf),
	.wb_ack_o(wb_ack_o),
	
	.usba_spd(),
	.usba_oe_n(),
	.usba_rcv(usba_vp),
	.usba_vp(usba_vp),
	.usba_vm(usba_vm),

	.usbb_spd(),
	.usbb_oe_n(),
	.usbb_rcv(),
	.usbb_vp(),
	.usbb_vm()
);

task waitclock;
begin
	@(posedge sys_clk);
	#1;
end
endtask

task wbwrite;
input [31:0] address;
input [31:0] data;
integer i;
begin
	wb_adr_i = address;
	wb_dat_i = data;
	wb_cyc_i = 1'b1;
	wb_stb_i = 1'b1;
	wb_we_i = 1'b1;
	i = 0;
	while(~wb_ack_o) begin
		i = i+1;
		waitclock;
	end
	waitclock;
	$display("WB Write: %x=%x acked in %d clocks", address, data, i);
	wb_cyc_i = 1'b0;
	wb_stb_i = 1'b0;
	wb_we_i = 1'b0;
end
endtask

task wbread;
input [31:0] address;
integer i;
begin
	wb_adr_i = address;
	wb_cyc_i = 1'b1;
	wb_stb_i = 1'b1;
	wb_we_i = 1'b0;
	i = 0;
	while(~wb_ack_o) begin
		i = i+1;
		waitclock;
	end
	$display("WB Read : %x=%x acked in %d clocks", address, wb_dat_o, i);
	waitclock;
	wb_cyc_i = 1'b0;
	wb_stb_i = 1'b0;
	wb_we_i = 1'b0;
end
endtask

task csrwrite;
input [31:0] address;
input [31:0] data;
begin
	csr_a = address[16:2];
	csr_di = data;
	csr_we = 1'b1;
	waitclock;
	$display("CSR write: %x=%x", address, data);
	csr_we = 1'b0;
end
endtask

task csrread;
input [31:0] address;
begin
	csr_a = address[16:2];
	waitclock;
	$display("CSR read : %x=%x", address, csr_do);
end
endtask

always begin
	$dumpfile("softusb.vcd");
	$dumpvars(0, dut);
	/* Reset / Initialize our logic */
	sys_rst = 1'b1;
	
	wb_adr_i = 32'd0;
	wb_dat_i = 32'd0;
	wb_cyc_i = 1'b0;
	wb_stb_i = 1'b0;
	wb_we_i = 1'b0;
	
	waitclock;
	
	sys_rst = 1'b0;
	
	waitclock;

	csrwrite(32'h00, 32'h00);
	
	#7000;

	wbread(32'h00020000);
	wbread(32'h00020004);
	
	$finish;
end

/* transmitter */

reg usb_clk_tx;
initial usb_clk_tx = 1'b0;
always #10 usb_clk_tx = ~usb_clk_tx;

reg usb_rst_tx;

reg [7:0] tx_data;
reg tx_valid;

wire txp;
wire txm;
wire txoe;
softusb_tx tx(
	.usb_clk(usb_clk_tx),
	.usb_rst(usb_rst_tx),

	.tx_data(tx_data),
	.tx_valid(tx_valid),
	.tx_ready(),

	.txp(txp),
	.txm(txm),
	.txoe(txoe),

	.low_speed(1'b0),
	.generate_eop(1'b0)
);

pullup(usba_vp);
pulldown(usba_vm);

assign usba_vp = txoe ? txp : 1'bz;
assign usba_vm = txoe ? txm : 1'bz;

initial begin
	$dumpvars(0, tx);
	usb_rst_tx = 1'b1;
	tx_valid = 1'b0;
	#20;
	usb_rst_tx = 1'b0;
	
	#4000;

	tx_data = 8'h80;
	tx_valid = 1'b1;
	#400;
	tx_data = 8'h56;
	#400;
	tx_valid = 1'b0;
end

endmodule
