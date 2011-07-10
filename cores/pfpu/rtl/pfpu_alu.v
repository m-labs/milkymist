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

module pfpu_alu(
	input sys_clk,
	input alu_rst,
	
	input [31:0] a,
	input [31:0] b,
	input ifb,
	
	input [3:0] opcode,
	
	output [31:0] r,
	output r_valid,

	output reg dma_en,
	
	output err_collision
);

/* Compensate for the latency cycle of the register file SRAM. */
reg [3:0] opcode_r;

always @(posedge sys_clk) begin
	if(alu_rst)
		opcode_r <= 4'd0;
	else
		opcode_r <= opcode;
end

/* Detect VECTOUT opcodes and trigger DMA */
always @(posedge sys_clk) begin
	if(alu_rst)
		dma_en <= 1'b0;
	else
		dma_en <= opcode == 4'h7;
end

/* Computation units */
wire faddsub_valid;
wire [31:0] r_faddsub;
pfpu_faddsub u_faddsub(
	.sys_clk(sys_clk),
	.alu_rst(alu_rst),
	
	.a(a),
	.b(b),
	.sub(~opcode_r[0]),
	.valid_i((opcode_r == 4'h1) | (opcode_r == 4'h2)),
	
	.r(r_faddsub),
	.valid_o(faddsub_valid)
);

wire fmul_valid;
wire [31:0] r_fmul;
pfpu_fmul u_fmul(
	.sys_clk(sys_clk),
	.alu_rst(alu_rst),
	
	.a(a),
	.b(b),
	.valid_i(opcode_r == 4'h3),
	
	.r(r_fmul),
	.valid_o(fmul_valid)
);

wire tsign_valid;
wire [31:0] r_tsign;
pfpu_tsign u_tsign(
	.sys_clk(sys_clk),
	.alu_rst(alu_rst),
	
	.a(a),
	.b(b),
	.tsign(opcode_r[3]),
	.valid_i((opcode_r == 4'h4) | (opcode_r == 4'he)),
	
	.r(r_tsign),
	.valid_o(tsign_valid)
);

wire f2i_valid;
wire [31:0] r_f2i;
pfpu_f2i u_f2i(
	.sys_clk(sys_clk),
	.alu_rst(alu_rst),
	
	.a(a),
	.valid_i(opcode_r == 4'h5),
	
	.r(r_f2i),
	.valid_o(f2i_valid)
);

wire i2f_valid;
wire [31:0] r_i2f;
pfpu_i2f u_i2f(
	.sys_clk(sys_clk),
	.alu_rst(alu_rst),
	
	.a(a),
	.valid_i(opcode_r == 4'h6),
	
	.r(r_i2f),
	.valid_o(i2f_valid)
);

wire sincos_valid;
wire [31:0] r_sincos;
pfpu_sincos u_sincos(
	.sys_clk(sys_clk),
	.alu_rst(alu_rst),
	
	.a(a),
	.cos(opcode_r[0]),
	.valid_i((opcode_r == 4'h8) | (opcode_r == 4'h9)),
	
	.r(r_sincos),
	.valid_o(sincos_valid)
);

wire above_valid;
wire [31:0] r_above;
pfpu_above u_above(
	.sys_clk(sys_clk),
	.alu_rst(alu_rst),

	.a(a),
	.b(b),
	.valid_i(opcode_r == 4'ha),

	.r(r_above),
	.valid_o(above_valid)
);

wire equal_valid;
wire [31:0] r_equal;
pfpu_equal u_equal(
	.sys_clk(sys_clk),
	.alu_rst(alu_rst),

	.a(a),
	.b(b),
	.valid_i(opcode_r == 4'hb),

	.r(r_equal),
	.valid_o(equal_valid)
);

wire copy_valid;
wire [31:0] r_copy;
pfpu_copy u_copy(
	.sys_clk(sys_clk),
	.alu_rst(alu_rst),

	.a(a),
	.valid_i(opcode_r == 4'hc),

	.r(r_copy),
	.valid_o(copy_valid)
);

wire if_valid;
wire [31:0] r_if;
pfpu_if u_if(
	.sys_clk(sys_clk),
	.alu_rst(alu_rst),

	.a(a),
	.b(b),
	.ifb(ifb),
	.valid_i(opcode_r == 4'hd),

	.r(r_if),
	.valid_o(if_valid)
);

wire quake_valid;
wire [31:0] r_quake;
pfpu_quake u_quake(
	.sys_clk(sys_clk),
	.alu_rst(alu_rst),

	.a(a),
	.valid_i(opcode_r == 4'hf),

	.r(r_quake),
	.valid_o(quake_valid)
);

/* Generate output */
assign r =
	 ({32{faddsub_valid}}	& r_faddsub)
	|({32{fmul_valid}}	& r_fmul)
	|({32{tsign_valid}}	& r_tsign)
	|({32{f2i_valid}}	& r_f2i)
	|({32{i2f_valid}}	& r_i2f)
	|({32{sincos_valid}}	& r_sincos)
	|({32{above_valid}}	& r_above)
	|({32{equal_valid}}	& r_equal)
	|({32{copy_valid}}	& r_copy)
	|({32{if_valid}}	& r_if)
	|({32{quake_valid}}	& r_quake);

assign r_valid =
	 faddsub_valid
	|fmul_valid
	|tsign_valid
	|f2i_valid
	|i2f_valid
	|sincos_valid
	|above_valid
	|equal_valid
	|copy_valid
	|if_valid
	|quake_valid;

assign err_collision =
	 (faddsub_valid & (fmul_valid|tsign_valid|f2i_valid|i2f_valid|sincos_valid|above_valid|equal_valid|copy_valid|if_valid|quake_valid))
	|(fmul_valid    & (tsign_valid|f2i_valid|i2f_valid|sincos_valid|above_valid|equal_valid|copy_valid|if_valid|quake_valid))
	|(tsign_valid   & (f2i_valid|i2f_valid|sincos_valid|above_valid|equal_valid|copy_valid|if_valid|quake_valid))
	|(f2i_valid     & (i2f_valid|sincos_valid|above_valid|equal_valid|copy_valid|if_valid|quake_valid))
	|(i2f_valid     & (sincos_valid|above_valid|equal_valid|copy_valid|if_valid|quake_valid))
	|(sincos_valid  & (above_valid|equal_valid|copy_valid|if_valid|quake_valid))
	|(above_valid   & (equal_valid|copy_valid|if_valid|quake_valid))
	|(equal_valid   & (copy_valid|if_valid|quake_valid))
	|(copy_valid    & (if_valid|quake_valid))
	|(if_valid      & (quake_valid));

endmodule
