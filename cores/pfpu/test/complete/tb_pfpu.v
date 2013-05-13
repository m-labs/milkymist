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

module tb_pfpu();

`define TEST_SIMPLE
`define TEST_SUM
//`define TEST_ROTATION

/* 100MHz system clock */
reg sys_clk;
initial sys_clk = 1'b0;
always #5 sys_clk = ~sys_clk;

reg sys_rst;

reg [13:0] csr_a;
reg csr_we;
reg [31:0] csr_di;
wire [31:0] csr_do;

wire irq;

wire [31:0] wbm_dat_o;
wire [31:0] wbm_adr_o;
wire wbm_cyc_o;
wire wbm_stb_o;
reg wbm_ack_i;

real r;
always @(posedge sys_clk) begin
	if(sys_rst)
		wbm_ack_i <= 1'b0;
	else begin
		wbm_ack_i <= 1'b0;
		if(wbm_stb_o & ~wbm_ack_i & (($random % 3) == 0)) begin
			wbm_ack_i <= 1'b1;
			$fromfloat(wbm_dat_o, r);
			$display("DMA write addr %x:%x (%b - %f)", wbm_adr_o, wbm_dat_o, wbm_adr_o[2], r);
		end
	end
end

pfpu dut(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_di),
	.csr_do(csr_do),
	
	.irq(irq),
	
	.wbm_dat_o(wbm_dat_o),
	.wbm_adr_o(wbm_adr_o),
	.wbm_cyc_o(wbm_cyc_o),
	.wbm_stb_o(wbm_stb_o),
	.wbm_ack_i(wbm_ack_i)
);

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
real rrv;
begin
	csr_a = address[16:2];
	waitclock;
	$fromfloat(csr_do, rrv);
	$display("Configuration Read : %x=%x (%f)", address, csr_do,rrv);
end
endtask

task showdiags;
begin
	$display("Vertices:");
	csrread(32'h0014);
	$display("Collisions:");
	csrread(32'h0018);
	$display("Stray writes:");
	csrread(32'h001C);
	$display("Pending DMA requests:");
	csrread(32'h0020);
	$display("Program counter:");
	csrread(32'h0024);
end
endtask

reg [31:0] a;
always begin
	/* Reset / Initialize our logic */
	sys_rst = 1'b1;
	csr_a = 14'd0;
	csr_di = 32'd0;
	csr_we = 1'b0;
	waitclock;
	sys_rst = 1'b0;
	waitclock;

`ifdef TEST_SIMPLE
	/* TEST 1 - Compute the sum of two registers and write the value via DMA */
	
	/* Mesh size : 1x1 */
	csrwrite(32'h0008, 32'd0);
	csrwrite(32'h000C, 32'd0);
	
	/* Write test operands to register file */
	$tofloat(3.0, a);
	csrwrite(32'h040C, a);
	$tofloat(9.0, a);
	csrwrite(32'h0410, a);
	
	/* Check they are correctly written */
	csrread(32'h040C);
	csrread(32'h0410);
	
	/* Load test microcode */
	/*                       PAD     OPA     OPB   OPCD   DEST */
	csrwrite(32'h0800, 32'b0000000_0000011_0000100_0001_0000000); /* FADD R3, R4 */
	csrwrite(32'h0804, 32'b0000000_0000000_0000000_0000_0000000); /* NOP */
	csrwrite(32'h0808, 32'b0000000_0000000_0000000_0000_0000000); /* NOP */
	csrwrite(32'h080C, 32'b0000000_0000000_0000000_0000_0000000); /* NOP */
	csrwrite(32'h0810, 32'b0000000_0000000_0000000_0000_0000000); /* NOP */
	csrwrite(32'h0814, 32'b0000000_0000000_0000000_0000_0000011); /* NOP | EXIT R3 */
	csrwrite(32'h0818, 32'b0000000_0000011_0000100_0111_0000000); /* VECTOUT R3, R4 */
	
	/* DMA base */
	csrwrite(32'h0004, 32'h401de328);
	
	/* Start */
	csrwrite(32'h0000, 32'h00000001);
	
	@(posedge irq);
	showdiags;
`endif

`ifdef TEST_SUM
	/* TEST 2 - Compute the sum of the two mesh coordinates and write it via DMA,
	 * for each vertex.
	 */
	
	/* Mesh size : 12x10 */
	csrwrite(32'h0008, 32'd11);
	csrwrite(32'h000C, 32'd9);
	
	/* Load test microcode */
	/*                       PAD     OPA     OPB   OPCD   DEST */
	csrwrite(32'h0800, 32'b0000000_0000000_0000000_0110_0000000); /* I2F R0 */
	csrwrite(32'h0804, 32'b0000000_0000001_0000000_0110_0000000); /* I2F R1 */
	csrwrite(32'h0808, 32'b0000000_0000000_0000000_0000_0000000); /* NOP */
	csrwrite(32'h080C, 32'b0000000_0000000_0000000_0000_0000011); /* NOP | EXIT R3 */
	csrwrite(32'h0810, 32'b0000000_0000000_0000000_0000_0000100); /* NOP | EXIT R4 */
	csrwrite(32'h0814, 32'b0000000_0000011_0000100_0001_0000000); /* FADD R3, R4 */
	csrwrite(32'h0818, 32'b0000000_0000000_0000000_0000_0000000); /* NOP */
	csrwrite(32'h081C, 32'b0000000_0000000_0000000_0000_0000000); /* NOP */
	csrwrite(32'h0820, 32'b0000000_0000000_0000000_0000_0000000); /* NOP */
	csrwrite(32'h0824, 32'b0000000_0000000_0000000_0000_0000000); /* NOP */
	csrwrite(32'h0828, 32'b0000000_0000000_0000000_0000_0000101); /* NOP | EXIT R5 */
	csrwrite(32'h082C, 32'b0000000_0000101_0000101_0111_0000000); /* VECTOUT R5, R5 */

	/* DMA base */
	csrwrite(32'h0004, 32'h401de328);
	
	/* Start */
	csrwrite(32'h0000, 32'h00000001);
	
	@(posedge irq);
	showdiags;
`endif

	$finish;
end

endmodule
