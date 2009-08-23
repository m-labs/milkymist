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

`timescale 1ns / 1ps

module tb_norflash8();

reg sys_clk;
reg sys_rst;

reg [31:0] wb_adr_i;
wire [31:0] wb_dat_o;
reg wb_cyc_i;
reg wb_stb_i;
wire wb_ack_o;

wire [6:0] aceusb_a;
wire [15:0] aceusb_d;

wire [21:0] flash_adr;
reg [7:0] flash_d;

always @(flash_adr) #110 flash_d <= flash_adr[7:0] + 8'd1;

norflash8 dut(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.wb_adr_i(wb_adr_i),
	.wb_dat_o(wb_dat_o),
	.wb_cyc_i(wb_cyc_i),
	.wb_stb_i(wb_stb_i),
	.wb_ack_o(wb_ack_o),

	.flash_adr(flash_adr),
	.flash_d(flash_d)
);

task wbread;
	input [31:0] address;
	integer i;
	begin
		wb_adr_i = address;
		wb_cyc_i = 1'b1;
		wb_stb_i = 1'b1;
		
		i = 1;
		while(~wb_ack_o) begin
			#5 sys_clk = 1'b1;
			#5 sys_clk = 1'b0;
			i = i + 1;
		end
		
		$display("Read address %h completed in %d cycles, result %h", address, i, wb_dat_o);
		
		/* Let the core release its ack */
		#5 sys_clk = 1'b1;
		#5 sys_clk = 1'b0;
		
		wb_cyc_i = 1'b0;
		wb_stb_i = 1'b0;
	end
endtask

initial begin
	sys_rst = 1'b1;
	sys_clk = 1'b0;
	
	wb_adr_i = 32'h00000000;
	wb_cyc_i = 1'b0;
	wb_stb_i = 1'b0;

	#5 sys_clk = 1'b1;
	#5 sys_clk = 1'b0;
	
	sys_rst = 1'b0;
	#5 sys_clk = 1'b1;
	#5 sys_clk = 1'b0;
	
	wbread(32'h00000020);
	wbread(32'h00000010);
	#5 sys_clk = 1'b1;
	#5 sys_clk = 1'b0;
	#5 sys_clk = 1'b1;
	#5 sys_clk = 1'b0;
	wbread(32'h00000040);
	
	$finish;
end

endmodule

