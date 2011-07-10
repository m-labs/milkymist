/*
 * Milkymist SoC
 * Copyright (C) 2007, 2008, 2009, 2011 Sebastien Bourdeauducq
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

`timescale 1ns/1ps

module tb_ac97();

reg sys_clk;
reg sys_rst;
reg ac97_clk;
reg ac97_rst_n;

initial begin
	sys_clk = 1'b0;
	ac97_clk = 1'b0;
end
always #5 sys_clk <= ~sys_clk;
always #40 ac97_clk <= ~ac97_clk;

reg [13:0] csr_a;
reg csr_we;
reg [31:0] csr_di;

wire [31:0] wbm_adr_o;
wire wbm_we_o;
wire wbm_stb_o;
reg wbm_ack_i;
reg [31:0] wbm_dat_i;
wire [31:0] wbm_dat_o;

wire dat;
ac97 dut(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.ac97_clk(ac97_clk),
	.ac97_rst_n(ac97_rst_n),
	
	.ac97_sin(dat),
	.ac97_sout(dat),
	.ac97_sync(),
	
	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_di),
	.csr_do(csr_do),
	
	.crrequest_irq(),
	.crreply_irq(),
	.dmar_irq(),
	.dmaw_irq(),
	
	.wbm_adr_o(wbm_adr_o),
	.wbm_cti_o(),
	.wbm_we_o(wbm_we_o),
	.wbm_cyc_o(),
	.wbm_stb_o(wbm_stb_o),
	.wbm_ack_i(wbm_ack_i),
	.wbm_dat_i(wbm_dat_i),
	.wbm_dat_o(wbm_dat_o)
);

always @(posedge sys_clk) begin
	if(wbm_stb_o & ~wbm_ack_i) begin
		wbm_ack_i <= 1'b1;
		if(wbm_we_o) begin
			$display("WB WRITE at addr %x, dat %x", wbm_adr_o, wbm_dat_o);
		end else begin
			wbm_dat_i = wbm_adr_o;
			$display("WB READ at addr %x, dat %x", wbm_adr_o, wbm_dat_i);
		end
	end else
		wbm_ack_i <= 1'b0;
end

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

initial begin
	$dumpfile("ac97.vcd");
	$dumpvars(0, dut);
	ac97_rst_n = 1'b1;
	sys_rst = 1'b0;
	wbm_ack_i = 1'b0;
	#161;
	ac97_rst_n = 1'b0;
	sys_rst = 1'b1;
	#160;
	ac97_rst_n = 1'b1;
	sys_rst = 1'b0;
	#100000;
	
	//csrwrite(32'h8, 32'hcafe);
	//csrwrite(32'h0, 32'h3);
	//csrread(32'h0);
	//#100000;
	//csrread(32'h0);
	//csrread(32'hc);
	
	csrwrite(32'h14, 32'h0);
	csrwrite(32'h18, 32'd40);
	csrwrite(32'h10, 32'd1);
	#500000;
	$finish;
end

endmodule
