/*
 * Milkymist SoC
 * Copyright (C) 2007, 2008, 2009, 2010, 2011 Sebastien Bourdeauducq
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

module tmu2_qpram #(
	parameter depth = 11 /* < log2 of the capacity in bytes */
) (
	input sys_clk,
	
	input [depth-1:0] raa, /* < in bytes, 16-bit aligned */
	output reg [15:0] rda,
	input [depth-1:0] rab,
	output reg [15:0] rdb,
	input [depth-1:0] rac,
	output reg [15:0] rdc,
	input [depth-1:0] rad,
	output reg [15:0] rdd,
	
	input we,
	input [depth-1:0] wa, /* < in bytes, 256-bit aligned */
	input [255:0] wd
);

wire [63:0] rd64a;
wire [63:0] rd64b;
wire [63:0] rd64c;
wire [63:0] rd64d;

reg [1:0] rala;
reg [1:0] ralb;
reg [1:0] ralc;
reg [1:0] rald;

always @(posedge sys_clk) begin
	rala <= raa[2:1];
	ralb <= rab[2:1];
	ralc <= rac[2:1];
	rald <= rad[2:1];
end

always @(*) begin
	case(rala)
		2'd0: rda = rd64a[63:48];
		2'd1: rda = rd64a[47:32];
		2'd2: rda = rd64a[31:16];
		default: rda = rd64a[15:0];
	endcase
	case(ralb)
		2'd0: rdb = rd64b[63:48];
		2'd1: rdb = rd64b[47:32];
		2'd2: rdb = rd64b[31:16];
		default: rdb = rd64b[15:0];
	endcase
	case(ralc)
		2'd0: rdc = rd64c[63:48];
		2'd1: rdc = rd64c[47:32];
		2'd2: rdc = rd64c[31:16];
		default: rdc = rd64c[15:0];
	endcase
	case(rald)
		2'd0: rdd = rd64d[63:48];
		2'd1: rdd = rd64d[47:32];
		2'd2: rdd = rd64d[31:16];
		default: rdd = rd64d[15:0];
	endcase
end

tmu2_tdpram #(
	.depth(depth-3),
	.width(64)
) ram0 (
	.sys_clk(sys_clk),

	.a(we ? {wa[depth-1:5], 2'b00} : raa[depth-1:3]),
	.we(we),
	.di(wd[255:192]),
	.do(rd64a),

	.a2(we ? {wa[depth-1:5], 2'b01} : rab[depth-1:3]),
	.we2(we),
	.di2(wd[191:128]),
	.do2(rd64b)
);

tmu2_tdpram #(
	.depth(depth-3),
	.width(64)
) ram1 (
	.sys_clk(sys_clk),

	.a(we ? {wa[depth-1:5], 2'b10} : rac[depth-1:3]),
	.we(we),
	.di(wd[127:64]),
	.do(rd64c),

	.a2(we ? {wa[depth-1:5], 2'b11} : rad[depth-1:3]),
	.we2(we),
	.di2(wd[63:0]),
	.do2(rd64d)
);

endmodule
