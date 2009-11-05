/*
 * Milkymist VJ SoC
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
