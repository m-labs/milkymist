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

module tb_navre();

reg sys_clk;
initial sys_clk = 1'b1;
always #5 sys_clk = ~sys_clk;

reg sys_rst;

wire pmem_ce;
wire [9:0] pmem_a;
reg [15:0] pmem_d;

reg [15:0] pmem[0:1023];

always @(posedge sys_clk) begin
	if(pmem_ce)
		pmem_d <= pmem[pmem_a];
end


wire dmem_we;
wire [9:0] dmem_a;
reg [7:0] dmem_di;
wire [7:0] dmem_do;

reg [7:0] dmem[0:1023];

always @(posedge sys_clk) begin
	if(dmem_we) begin
		//$display("DMEM WRITE: adr=%d dat=%d", dmem_a, dmem_do);
		dmem[dmem_a] <= dmem_do;
	end
	dmem_di <= dmem[dmem_a];
end

wire io_re;
wire io_we;
wire [5:0] io_a;
wire [7:0] io_do;
reg [7:0] io_di;

reg end_of_test;
always @(posedge sys_clk) begin
	end_of_test <= 1'b0;
	if(~sys_rst) begin
		if(io_re) begin
			$display("IO READ adr=%x", io_a);
			if((io_a == 6'h11)|(io_a == 6'h12))
				io_di <= 8'hff;
			else
				io_di <= io_a;
		end
		if(io_we) begin
			$display("IO WRITE adr=%x dat=%x", io_a, io_do);
			if((io_a == 0) && (io_do == 254))
				end_of_test <= 1'b1;
		end
	end
end

softusb_navre #(
	.pmem_width(10),
	.dmem_width(10)
) dut (
	.clk(sys_clk),
	.rst(sys_rst),

	.pmem_ce(pmem_ce),
	.pmem_a(pmem_a),
	.pmem_d(pmem_d),

	.dmem_we(dmem_we),
	.dmem_a(dmem_a),
	.dmem_di(dmem_di),
	.dmem_do(dmem_do),

	.io_re(io_re),
	.io_we(io_we),
	.io_a(io_a),
	.io_do(io_do),
	.io_di(io_di),

	.irq(8'b0),

	.dbg_pc()
);

initial begin
	$display("Test: Fibonacci (assembler)");
	$readmemh("fib.rom", pmem);
	sys_rst = 1'b1;
	#15;
	sys_rst = 1'b0;
	@(posedge end_of_test);

	$display("Test: Fibonacci (C)");
	$readmemh("fibc.rom", pmem);
	sys_rst = 1'b1;
	#15;
	sys_rst = 1'b0;
	@(posedge end_of_test);

	$finish;
end

endmodule
