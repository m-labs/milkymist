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

module tb_memtest();

parameter fml_depth = 26;

reg sys_clk;
reg sys_rst;

reg [13:0] csr_a;
reg csr_we;
reg [31:0] csr_di;
wire [31:0] csr_do;

wire irq;

wire [fml_depth-1:0] fml_adr;
wire fml_we;
wire fml_stb;
reg fml_ack;
reg [63:0] fml_di;
wire [63:0] fml_do;

/* 100MHz system clock */
initial sys_clk = 1'b0;
always #5 sys_clk = ~sys_clk;

memtest #(
	.fml_depth(fml_depth),
	.csr_addr(4'h0)
) dut (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_di),
	.csr_do(csr_do),
	
	.fml_adr(fml_adr),
	.fml_we(fml_we),
	.fml_stb(fml_stb),
	.fml_ack(fml_ack),
	.fml_sel(fml_sel),
	.fml_di(fml_di),
	.fml_do(fml_do)
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
	$display("CSR read : %x=%x (%d)", address, csr_do, csr_do);
end
endtask

parameter memsize = 32*1024*1024;
reg [63:0] mem[0:memsize-1];

integer burstcount;
integer addr;
integer we;
initial burstcount = 0;
always @(posedge sys_clk) begin
	fml_ack = 1'b0;
	if(burstcount == 0) begin
		if(fml_stb & (($random % 5) == 0)) begin
			burstcount = 1;
			addr = fml_adr;
			we = fml_we;
			
			//$display("Starting   FML burst at address %x, data=%x", addr, fml_do);
			
			fml_di = mem[addr/8];
			if(we)
				mem[addr/8] = fml_do;
			
			fml_ack = 1'b1;
		end
	end else begin
		addr = addr + 8;
		burstcount = burstcount + 1;

		fml_di = mem[addr/8];
		if(we)
			mem[addr/8] = fml_do;

		//$display("Continuing FML burst at address %x, data=%x", addr, fml_do);
		
		if(burstcount == 4)
			burstcount = 0;
	end
end

always begin
	sys_rst = 1'b1;
	
	csr_a = 14'd0;
	csr_di = 32'd0;
	csr_we = 1'b0;
	
	fml_di = 64'd0;
	fml_ack = 1'b0;

	waitclock;
	
	sys_rst = 1'b0;
	
	waitclock;
	
	$dumpfile("memtest.vcd");
	$dumpvars(0, dut);

	$display("WRITING");
	csrwrite(32'h4, 32'd0);
	csrwrite(32'h8, 32'd0);
	csrwrite(32'hc, 32'd1);
	csrwrite(32'h0, 32'd209716);

	csrread(32'h0);
	while(|csr_do) begin
		#10000;
		csrread(32'h0);
	end
	
	$display("");
	$display("READING");
	
	csrwrite(32'h4, 32'd0);
	csrwrite(32'h8, 32'd0);
	csrwrite(32'hc, 32'd0);
	csrwrite(32'h0, 32'd209716);
	
	csrread(32'h0);
	while(|csr_do) begin
		#10000;
		csrread(32'h0);
	end
	
	csrread(32'h4); /* error count */

	$finish;
end

endmodule
