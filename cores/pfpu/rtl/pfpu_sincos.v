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

module pfpu_sincos(
	input sys_clk,
	input alu_rst,
	
	input [31:0] a,
	input cos,
	input valid_i,
	
	output [31:0] r,
	output valid_o
);

/* Stage 1 */

/* Take care of negative input
 * cos(-x) = cos(x) : turn the number into its opposite
 * sin(-x) = sin(x+pi) : turn the number into its opposite, and add 4096
 */

reg s1_valid;
reg s1_cos;
reg [12:0] s1_a;

wire [12:0] neg_a = 13'd0 - a[12:0]; /* take two's complement to a */
always @(posedge sys_clk) begin
	if(alu_rst)
		s1_valid <= 1'b0;
	else
		s1_valid <= valid_i;
	s1_cos <= cos;
	if(a[31]) begin /* negative input */
		if(~cos)
			s1_a <= neg_a + 13'd4096;
		else
			s1_a <= neg_a;
	end else
		s1_a <= a[12:0];
end

/* Stage 2 */

/* Compute sign and ROM address */

reg s2_sign;
reg s2_valid;
reg [10:0] s2_rom_a;
reg s2_isone;

always @(posedge sys_clk) begin
	if(alu_rst)
		s2_valid <= 1'b0;
	else
		s2_valid <= s1_valid;
	s2_isone <= 1'b0;
	if(s1_cos) begin
		s2_sign <= s1_a[12] ^ s1_a[11];
		if(s1_a[11])
			s2_rom_a <= s1_a[10:0];
		else begin
			s2_rom_a <= 11'd0 - s1_a[10:0];
			s2_isone <= s1_a[10:0] == 11'd0;
		end
	end else begin
		s2_sign <= s1_a[12];
		if(s1_a[11]) begin
			s2_rom_a <= 11'd0 - s1_a[10:0];
			s2_isone <= s1_a[10:0] == 11'd0;
		end else
			s2_rom_a <= s1_a[10:0];
	end
end

/* Stage 3 */

/* ROM lookup */

reg [30:0] rom[0:2047];
reg [30:0] s3_rom_do;

always @(posedge sys_clk)
	s3_rom_do <= rom[s2_rom_a];

initial $readmemh("../roms/sin.rom", rom);

reg s3_valid;
reg s3_sign;
reg s3_isone;

always @(posedge sys_clk) begin
	if(alu_rst)
		s3_valid <= 1'b0;
	else
		s3_valid <= s2_valid;
	s3_sign <= s2_sign;
	s3_isone <= s2_isone;
end

assign r = {
		s3_sign,
		s3_isone ? 31'h3f800000 /* 1.0f */ : s3_rom_do
	};
assign valid_o = s3_valid;

endmodule
