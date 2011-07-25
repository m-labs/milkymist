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

wire [127:0] rd128a;
wire [127:0] rd128b;
wire [127:0] rd128c;
wire [127:0] rd128d;

reg [2:0] rala;
reg [2:0] ralb;
reg [2:0] ralc;
reg [2:0] rald;

always @(posedge sys_clk) begin
	rala <= raa[3:1];
	ralb <= rab[3:1];
	ralc <= rac[3:1];
	rald <= rad[3:1];
end

always @(*) begin
	case(rala)
		3'd0: rda = rd128a[127:112];
		3'd1: rda = rd128a[111:96];
		3'd2: rda = rd128a[95:80];
		3'd3: rda = rd128a[79:64];
		3'd4: rda = rd128a[63:48];
		3'd5: rda = rd128a[47:32];
		3'd6: rda = rd128a[31:16];
		default: rda = rd128a[15:0];
	endcase
	case(ralb)
		3'd0: rdb = rd128b[127:112];
		3'd1: rdb = rd128b[111:96];
		3'd2: rdb = rd128b[95:80];
		3'd3: rdb = rd128b[79:64];
		3'd4: rdb = rd128b[63:48];
		3'd5: rdb = rd128b[47:32];
		3'd6: rdb = rd128b[31:16];
		default: rdb = rd128b[15:0];
	endcase
	case(ralc)
		3'd0: rdc = rd128c[127:112];
		3'd1: rdc = rd128c[111:96];
		3'd2: rdc = rd128c[95:80];
		3'd3: rdc = rd128c[79:64];
		3'd4: rdc = rd128c[63:48];
		3'd5: rdc = rd128c[47:32];
		3'd6: rdc = rd128c[31:16];
		default: rdc = rd128c[15:0];
	endcase
	case(rald)
		3'd0: rdd = rd128d[127:112];
		3'd1: rdd = rd128d[111:96];
		3'd2: rdd = rd128d[95:80];
		3'd3: rdd = rd128d[79:64];
		3'd4: rdd = rd128d[63:48];
		3'd5: rdd = rd128d[47:32];
		3'd6: rdd = rd128d[31:16];
		default: rdd = rd128d[15:0];
	endcase
end

tmu2_tdpram #(
	.depth(depth-4),
	.width(128)
) ram0 (
	.sys_clk(sys_clk),

	.a(we ? {wa[depth-1:5], 1'b0} : raa[depth-1:4]),
	.we(we),
	.di(wd[255:128]),
	.do(rd128a),

	.a2(we ? {wa[depth-1:5], 1'b1} : rab[depth-1:4]),
	.we2(we),
	.di2(wd[127:0]),
	.do2(rd128b)
);

tmu2_tdpram #(
	.depth(depth-4),
	.width(128)
) ram1 (
	.sys_clk(sys_clk),

	.a(we ? {wa[depth-1:5], 1'b0} : rac[depth-1:4]),
	.we(we),
	.di(wd[255:128]),
	.do(rd128c),

	.a2(we ? {wa[depth-1:5], 1'b1} : rad[depth-1:4]),
	.we2(we),
	.di2(wd[127:0]),
	.do2(rd128d)
);

endmodule
