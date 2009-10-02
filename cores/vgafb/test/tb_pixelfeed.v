/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 *
 * This program is free and excepted software; you can use it, redistribute it
 * and/or modify it under the terms of the Exception General Public License as
 * published by the Exception License Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the Exception General Public License for more
 * details.
 *
 * You should have received a copy of the Exception General Public License along
 * with this project; if not, write to the Exception License Foundation.
 */

module tb_pixelfeed();

reg sys_clk;
initial sys_clk = 1'b0;
always #5 sys_clk = ~sys_clk;

reg sys_rst;
reg vga_rst;

wire pixel_valid;
wire fml_stb;
wire [25:0] fml_adr;

initial begin
	sys_rst = 1'b1;
	vga_rst = 1'b1;
	#20 sys_rst = 1'b0;
	#20 vga_rst = 1'b0;
end

vgafb_pixelfeed dut(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.vga_rst(vga_rst),
	
	.nbursts(18'd100),
	.baseaddress(26'd1024),
	.baseaddress_ack(),
	
	.fml_adr(fml_adr),
	.fml_stb(fml_stb),
	.fml_ack(fml_stb),
	.fml_di(64'hcafebabedeadbeef),
	
	.pixel_valid(pixel_valid),
	.pixel(),
	.pixel_ack(pixel_valid)
);

always @(posedge sys_clk) $display("%x", fml_adr);

initial #600 $finish;

endmodule
