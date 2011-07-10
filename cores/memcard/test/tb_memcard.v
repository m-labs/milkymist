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

module tb_memcard();

reg sys_clk;
initial sys_clk = 1'b0;
always #5 sys_clk = ~sys_clk;

reg sys_rst;

reg [13:0] csr_a;
reg csr_we;
reg [31:0] csr_di;
wire [31:0] csr_do;

wire [3:0] mc_d;
wire mc_cmd;
wire mc_clk;

memcard dut(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_di),
	.csr_do(csr_do),

	.mc_d(mc_d),
	.mc_cmd(mc_cmd),
	.mc_clk(mc_clk)
);

pullup(mc_d[0]);
pullup(mc_d[1]);
pullup(mc_d[2]);
pullup(mc_d[3]);
pullup(mc_cmd);

reg cmd_rxen;
integer cmd_bitcount;
reg [47:0] cmd_rxreg;
initial begin
	cmd_rxen <= 1'b0;
	cmd_bitcount <= 0;
end
always @(posedge mc_clk) begin
	if(~mc_cmd)
		cmd_rxen = 1'b1;
	if(cmd_rxen) begin
		cmd_rxreg = {cmd_rxreg[46:0], mc_cmd};
		cmd_bitcount = cmd_bitcount + 1;
	end
	if(cmd_bitcount == 48) begin
		$display("CMD RX: %x", cmd_rxreg);
		cmd_bitcount = 0;
		cmd_rxen = 1'b0;
	end
end

reg cmd_txen;
reg [47:0] cmd_txreg;
initial cmd_txreg = 48'h7f0102030405;
always @(posedge mc_clk) begin
	if(cmd_txen)
		cmd_txreg <= {cmd_txreg[46:0], 1'b1};
end
assign mc_cmd = cmd_txen ? cmd_txreg[47] : 1'bz;

task waitclock;
begin
	@(posedge sys_clk);
	#1;
end
endtask

task waitnclock;
input [15:0] n;
integer i;
begin
	for(i=0;i<n;i=i+1)
		waitclock;
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
	$display("Configuration Write: %x=%x", address, data);
	csr_we = 1'b0;
end
endtask

task csrread;
input [31:0] address;
begin
	csr_a = address[16:2];
	waitclock;
	$display("Configuration Read : %x=%x", address, csr_do);
end
endtask

always begin
	sys_rst = 1'b1;
	csr_a = 14'd0;
	csr_di = 32'd0;
	csr_we = 1'b0;
	cmd_txen = 1'b0;
	waitclock;
	sys_rst = 1'b0;
	waitclock;

	$dumpvars(0, dut);
	$dumpfile("memcard.vcd");

	csrwrite(32'h00, 32'h0a); /* clock fast */
	csrwrite(32'h04, 32'h1); /* enable TX */
	waitnclock(256);
	csrwrite(32'h10, 32'h51);
	waitnclock(256);
	csrwrite(32'h10, 32'h00);
	waitnclock(256);
	csrwrite(32'h10, 32'h00);
	waitnclock(256);
	csrwrite(32'h10, 32'h00);
	waitnclock(256);
	csrwrite(32'h10, 32'h00);
	waitnclock(256);
	csrwrite(32'h10, 32'h55);
	waitnclock(256);

	csrwrite(32'h08, 32'h2); /* reset RX */
	csrwrite(32'h04, 32'h2); /* disable TX and enable RX */
	waitnclock(13);
	cmd_txen = 1'b1;
	waitnclock(256);
	csrread(32'h10);
	csrwrite(32'h08, 32'h2);
	waitnclock(256);
	csrread(32'h10);
	csrwrite(32'h08, 32'h2);

	$finish;
end

endmodule
