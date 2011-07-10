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

/* Program memory has 2048 25-bit words */

module pfpu_prog(
	input sys_clk,
	input count_rst,

	output [6:0] a_addr,
	output [6:0] b_addr,
	output [3:0] opcode,
	output [6:0] w_addr,
	
	/* Control interface */
	input c_en,
	input [1:0] c_page,
	input [8:0] c_offset,
	output [31:0] c_do,
	input [31:0] c_di,
	input c_w_en,

	output [10:0] pc
);

/* Infer single port RAM */
wire [10:0] mem_a;
wire [24:0] mem_di;
reg [24:0] mem_do;
wire mem_we;
reg [24:0] mem[0:2047];
always @(posedge sys_clk) begin
	if(mem_we)
		mem[mem_a] <= mem_di;
	mem_do <= mem[mem_a];
end

/* Control logic */
reg [10:0] counter;
always @(posedge sys_clk) begin
	if(count_rst)
		counter <= 10'd0;
	else
		counter <= counter + 10'd1;
end
assign mem_a = c_en ? {c_page, c_offset} : counter;

assign c_do = {7'd0, mem_do};
assign mem_di = c_di[24:0];
assign mem_we = c_en & c_w_en;

assign a_addr = mem_do[24:18];	// 7
assign b_addr = mem_do[17:11];	// 7
assign opcode = mem_do[10:7];	// 4
assign w_addr = mem_do[6:0];	// 7

assign pc = counter;

endmodule
