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

module pfpu_alu(
	input sys_clk,
	input alu_rst,
	
	input [31:0] a,
	input [31:0] b,
	input [1:0] flags,
	
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
pfpu_faddsub faddsub(
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
pfpu_fmul fmul(
	.sys_clk(sys_clk),
	.alu_rst(alu_rst),
	
	.a(a),
	.b(b),
	.valid_i(opcode_r == 4'h3),
	
	.r(r_fmul),
	.valid_o(fmul_valid)
);

wire fdiv_valid;
wire [31:0] r_fdiv;
pfpu_fdiv fdiv(
	.sys_clk(sys_clk),
	.alu_rst(alu_rst),
	
	.a(a),
	.b(b),
	.valid_i(opcode_r == 4'h4),
	
	.r(r_fdiv),
	.valid_o(fdiv_valid)
);

wire f2i_valid;
wire [31:0] r_f2i;
pfpu_f2i f2i(
	.sys_clk(sys_clk),
	.alu_rst(alu_rst),
	
	.a(a),
	.valid_i(opcode_r == 4'h5),
	
	.r(r_f2i),
	.valid_o(f2i_valid)
);

wire i2f_valid;
wire [31:0] r_i2f;
pfpu_i2f i2f(
	.sys_clk(sys_clk),
	.alu_rst(alu_rst),
	
	.a(a),
	.valid_i(opcode_r == 4'h6),
	
	.r(r_i2f),
	.valid_o(i2f_valid)
);

wire sincos_valid;
wire [31:0] r_sincos;
pfpu_sincos sincos(
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
pfpu_above above(
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
pfpu_equal equal(
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
pfpu_copy copy(
	.sys_clk(sys_clk),
	.alu_rst(alu_rst),

	.a(a),
	.valid_i(opcode_r == 4'hc),

	.r(r_copy),
	.valid_o(copy_valid)
);

/* Generate output */
assign r =
	 ({32{faddsub_valid}}	& r_faddsub)
	|({32{fmul_valid}}	& r_fmul)
	|({32{fdiv_valid}}	& r_fdiv)
	|({32{f2i_valid}}	& r_f2i)
	|({32{i2f_valid}}	& r_i2f)
	|({32{sincos_valid}}	& r_sincos)
	|({32{above_valid}}	& r_above)
	|({32{equal_valid}}	& r_equal)
	|({32{copy_valid}}	& r_copy);

assign r_valid =
	 faddsub_valid
	|fmul_valid
	|fdiv_valid
	|f2i_valid
	|i2f_valid
	|sincos_valid
	|above_valid
	|equal_valid
	|copy_valid;

assign err_collision =
	 (faddsub_valid & (fmul_valid|fdiv_valid|f2i_valid|i2f_valid|sincos_valid|above_valid|equal_valid|copy_valid))
	|(fmul_valid    & (fdiv_valid|f2i_valid|i2f_valid|sincos_valid|above_valid|equal_valid|copy_valid))
	|(fdiv_valid    & (f2i_valid|i2f_valid|sincos_valid|above_valid|equal_valid|copy_valid))
	|(f2i_valid     & (i2f_valid|sincos_valid|above_valid|equal_valid|copy_valid))
	|(i2f_valid     & (sincos_valid|above_valid|equal_valid|copy_valid))
	|(sincos_valid  & (above_valid|equal_valid|copy_valid))
	|(above_valid   & (equal_valid|copy_valid))
	|(equal_valid   & (copy_valid));

endmodule
