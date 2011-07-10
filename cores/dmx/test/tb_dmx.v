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

module tb_dmx();

reg sys_clk;
reg sys_rst;

/* 83.333MHz system clock */
initial sys_clk = 1'b0;
always #6 sys_clk = ~sys_clk;

reg [13:0] csr_a;
reg csr_we;
reg [31:0] csr_di;
wire [31:0] csr_do_tx;
wire [31:0] csr_do_rx;

wire dmx_signal;

dmx_tx #(
	.csr_addr(4'h0),
	.clk_freq(83333333)
) tx_dut (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_do(csr_do_tx),
	.csr_di(csr_di),

	.thru(1'b0),
	.tx(dmx_signal)
);

dmx_rx #(
	.csr_addr(4'h1),
	.clk_freq(83333333)
) rx_dut (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_do(csr_do_rx),
	.csr_di(csr_di),

	.rx(dmx_signal)
);

task waitclock;
begin
	@(posedge sys_clk);
	#1;
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
	$display("CSR read : %x=%x", address, csr_do_tx|csr_do_rx);
end
endtask

always begin
	$dumpfile("dmx.vcd");
	$dumpvars(0, tx_dut);
	$dumpvars(0, rx_dut);

	/* Reset / Initialize our logic */
	sys_rst = 1'b1;

	waitclock;
	
	sys_rst = 1'b0;
	
	waitclock;

	csrread(32'h0000);
	csrwrite(32'h0000, 32'hff);
	csrread(32'h0000);

	#1000000;

	csrread(32'h1000);
	csrread(32'h1004);
	
	#50000000;
	
	$finish;
end

endmodule
