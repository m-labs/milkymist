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

module norflash32 #(
	parameter adr_width = 21 /* in 32-bit words */
) (
	input sys_clk,
	input sys_rst,

	input [31:0] wb_adr_i,
	output reg [31:0] wb_dat_o,
	input wb_stb_i,
	input wb_cyc_i,
	output reg wb_ack_o,
	
	/* 32-bit granularity */
	output reg [adr_width-1:0] flash_adr,
	input [31:0] flash_d
);

always @(posedge sys_clk) begin
	/* Use IOB registers to prevent glitches on address lines */
	if(wb_cyc_i & wb_stb_i) /* register only when needed to reduce EMI */
		flash_adr <= wb_adr_i[adr_width+1:2];
	wb_dat_o <= flash_d;
end

/*
 * Timing of the ML401 flash chips is 110ns.
 * By using 16 cycles at 100MHz and counting
 * the I/O registers delay we have some margins
 * and simple hardware for generating WB ack.
 */
reg [3:0] counter;
always @(posedge sys_clk) begin
	if(sys_rst)
		counter <= 4'd1;
	else begin
		if(wb_cyc_i & wb_stb_i)
			counter <= counter + 4'd1;
		wb_ack_o <= &counter;
	end
end

endmodule
