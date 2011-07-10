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

module pfpu_regf(
	input sys_clk,
	input sys_rst,
	
	/* ALU interface */
	output reg ifb,
	output [31:0] a,
	output [31:0] b,
	input [31:0] r,
	input w_en,
	
	/* Program Memory interface */
	input [6:0] a_addr,
	input [6:0] b_addr,
	input [6:0] w_addr,
	
	/* CSR interface */
	input c_en,
	input [6:0] c_addr,
	output [31:0] c_do,
	input [31:0] c_di,
	input c_w_en,
	
	/* Address Generator interface */
	input [31:0] r0,
	input [31:0] r1,

	output err_stray
);

/* Triple-port RAM for most of the registers.
 * R0 and R1 are overlaid on top of it.
 */
wire [6:0] p1_a;
wire [31:0] p1_d;
wire [6:0] p2_a;
wire [31:0] p2_d;
wire p3_en;
wire [6:0] p3_a;
wire [31:0] p3_d;
pfpu_tpram tpram(
	.sys_clk(sys_clk),
	.p1_a(p1_a),
	.p1_d(p1_d),
	.p2_a(p2_a),
	.p2_d(p2_d),
	.p3_en(p3_en),
	.p3_a(p3_a),
	.p3_d(p3_d)
);

/* Port 1 (RO) - Shared between ALU and CSR interface */
assign p1_a = c_en ? c_addr : a_addr;
reg p1_bram_en;
reg p1_overlay_en;
reg [31:0] p1_overlay;
always @(posedge sys_clk) begin
	p1_bram_en <= 1'b0;
	p1_overlay_en <= 1'b1;

	     if(p1_a == 7'd0) p1_overlay <= r0;
	else if(p1_a == 7'd1) p1_overlay <= r1;
	else begin
		p1_bram_en <= 1'b1;
		p1_overlay_en <= 1'b0;
		p1_overlay <= 32'bx;
	end
end
assign a = ({32{p1_bram_en}} & p1_d)|({32{p1_overlay_en}} & p1_overlay);
assign c_do = a;

/* Port 2 (RO) - Dedicated to ALU */
assign p2_a = b_addr;
reg p2_bram_en;
reg p2_overlay_en;
reg [31:0] p2_overlay;
always @(posedge sys_clk) begin
	p2_bram_en <= 1'b0;
	p2_overlay_en <= 1'b1;

	     if(p2_a == 7'd0) p2_overlay <= r0;
	else if(p2_a == 7'd1) p2_overlay <= r1;
	else begin
		p2_bram_en <= 1'b1;
		p2_overlay_en <= 1'b0;
		p2_overlay <= 32'bx;
	end
end
assign b = ({32{p2_bram_en}} & p2_d)|({32{p2_overlay_en}} & p2_overlay);

/* Port 3 (WO) - Shared between ALU and CSR interface */
assign p3_en = c_en ? c_w_en : w_en;
assign p3_a = c_en ? c_addr : w_addr;
assign p3_d = c_en ? c_di : r;

/* Catch writes to R2 and update the IF Branch */
always @(posedge sys_clk) begin
	if(p3_en) begin
		if(p3_a == 7'd2)
			ifb <= p3_d != 32'd0;
	end
end

/* Catch writes to register 0 */
assign err_stray = p3_en & (p3_a == 7'd0);

endmodule
