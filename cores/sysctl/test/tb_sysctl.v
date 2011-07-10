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

reg [13:0] csr_a;
reg csr_we;
reg [31:0] csr_di;
wire [31:0] csr_do;

/* 100MHz system clock */
initial sys_clk = 1'b0;
always #5 sys_clk = ~sys_clk;

sysctl dut(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_do(csr_do),
	.csr_di(csr_di)
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
	waitclock;
	waitclock;
	waitclock;
	waitclock;
	waitclock;
	waitclock;
	waitclock;
	waitclock;
	waitclock;
	waitclock;
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
	waitclock;
	sys_rst = 1'b0;
	
	#2000;

	csrwrite(32'h34, 32'h03ffff);
	csrwrite(32'h34, 32'h03ffff);
	csrwrite(32'h34, 32'h03ffff);
	csrwrite(32'h34, 32'h03ffff);
	csrwrite(32'h34, 32'h00aa99);
	csrwrite(32'h34, 32'h005566);
	csrwrite(32'h34, 32'h0030a1);
	csrwrite(32'h34, 32'h000000);
	csrwrite(32'h34, 32'h0030a1);
	csrwrite(32'h34, 32'h00000e);
	csrwrite(32'h34, 32'h002000);
	csrwrite(32'h34, 32'h002000);
	csrwrite(32'h34, 32'h002000);
	csrwrite(32'h34, 32'h002000);
	csrwrite(32'h34, 32'h031111);
	csrwrite(32'h34, 32'h03ffff);

	
	#700;

	$finish;
end

endmodule
