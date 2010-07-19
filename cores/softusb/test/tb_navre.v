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

module tb_navre();

reg sys_clk;
initial sys_clk = 1'b1;
always #5 sys_clk = ~sys_clk;

reg sys_rst;
initial begin
	sys_rst = 1'b1;
	#15;
	sys_rst = 1'b0;
end

wire pmem_ce;
wire [9:0] pmem_a;
reg [15:0] pmem_d;

always @(posedge sys_clk) begin
	if(pmem_ce) begin
		case(pmem_a)
			10'd0: pmem_d <= 16'b1110_0000_0000_0100; /* LDI R16, 4 */
			10'd1: pmem_d <= 16'b1110_0010_0001_0110; /* LDI R17, 38 */
			10'd2: pmem_d <= 16'b0000_1111_0000_0001; /* ADD R16, R17 */
			10'd3: pmem_d <= 16'b1011_1001_0000_0000; /* OUT 0, R16 */
			10'd4: pmem_d <= 16'b1110_1111_0000_1110; /* LDI R16, 254 */
			10'd5: pmem_d <= 16'b1011_1001_0000_0000; /* OUT 0, R16 */
			default: pmem_d <= 16'd0;
		endcase
	end
end

wire io_re;
wire io_we;
wire [5:0] io_a;
wire [7:0] io_do;
reg [7:0] io_di;

always @(posedge sys_clk) begin
	if(~sys_rst) begin
		if(io_re) begin
			$display("IO READ adr=%d", io_a);
			io_di <= io_a;
		end
		if(io_we) begin
			$display("IO WRITE adr=%d dat=%d", io_a, io_do);
			if((io_a == 0) && (io_do == 254))
				$finish;
		end
	end
end

softusb_navre #(
	.pmem_width(10)
) dut (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.pmem_ce(pmem_ce),
	.pmem_a(pmem_a),
	.pmem_d(pmem_d),

	.io_re(io_re),
	.io_we(io_we),
	.io_a(io_a),
	.io_do(io_do),
	.io_di(io_di)
);

endmodule
