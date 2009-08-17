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

module tmu_decay #(
	parameter fml_depth = 26
) (
	input sys_clk,
	input sys_rst,
	
	output busy,
	
	input [5:0] brightness,
	
	input pipe_stb_i,
	output pipe_ack_o,
	input [15:0] src_pixel,
	input [fml_depth-1-1:0] dst_addr,
	
	output pipe_stb_o,
	input pipe_ack_i,
	output [15:0] src_pixel_d,
	output reg [fml_depth-1-1:0] dst_addr1
);

wire en;
wire s0_valid;
reg s1_valid;
reg s2_valid;
reg s3_valid;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		s1_valid <= 1'b0;
		s2_valid <= 1'b0;
		s3_valid <= 1'b0;
	end else if(en) begin
		s1_valid <= s0_valid;
		s2_valid <= s1_valid;
		s3_valid <= s2_valid;
	end
end

/* Pipeline operation on three stages. */

reg [fml_depth-1-1:0] s1_dst_addr;
reg [fml_depth-1-1:0] s2_dst_addr;
/* third stage register is output */

reg s1_full_brightness;
reg s2_full_brightness;
reg s3_full_brightness;

reg [15:0] s1_pixel_full;
reg [15:0] s2_pixel_full;
reg [15:0] s3_pixel_full;

wire [5:0] brightness1 = brightness + 6'd1;
reg [5:0] s1_brightness1;

wire [4:0] r = src_pixel[15:11];
wire [5:0] g = src_pixel[10:5];
wire [4:0] b = src_pixel[4:0];

reg [4:0] s1_r;
reg [5:0] s1_g;
reg [4:0] s1_b;

reg [10:0] s2_r;
reg [11:0] s2_g;
reg [10:0] s2_b;

reg [10:0] s3_r;
reg [11:0] s3_g;
reg [10:0] s3_b;

always @(posedge sys_clk) begin
	if(en) begin
		s1_dst_addr <= dst_addr;
		s2_dst_addr <= s1_dst_addr;
		dst_addr1 <= s2_dst_addr;
		
		s1_full_brightness <= brightness == 6'b111111;
		s2_full_brightness <= s1_full_brightness;
		s3_full_brightness <= s2_full_brightness;
		
		s1_pixel_full <= src_pixel;
		s2_pixel_full <= s1_pixel_full;
		s3_pixel_full <= s2_pixel_full;
		
		s1_r <= r;
		s1_g <= g;
		s1_b <= b;
		s1_brightness1 <= brightness1;
		
		s2_r <= s1_brightness1*s1_r;
		s2_g <= s1_brightness1*s1_g;
		s2_b <= s1_brightness1*s1_b;
		
		s3_r <= s2_r;
		s3_g <= s2_g;
		s3_b <= s2_b;
	end
end

assign src_pixel_d = s3_full_brightness ? s3_pixel_full : {s3_r[10:6], s3_g[11:6], s3_b[10:6]};

/* Pipeline management */

assign busy = s1_valid|s2_valid|s3_valid;

assign s0_valid = pipe_stb_i;
assign pipe_ack_o = pipe_ack_i;

assign en = pipe_ack_i;
assign pipe_stb_o = s3_valid;

endmodule
