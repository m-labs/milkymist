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

module vgafb_fifo64to16(
	input sys_clk,
	input vga_rst,
	
	input stb,
	input [63:0] di,
	
	output do_valid,
	output reg [15:0] do,
	input next /* should only be asserted when do_valid = 1 */
);

/*
 * FIFO can hold 4 64-bit words
 * that is 16 16-bit words.
 */

reg [63:0] storage[0:3];
reg [1:0] produce; /* in 64-bit words */
reg [3:0] consume; /* in 16-bit words */
/*
 * 16-bit words stored in the FIFO, 0-16 (17 possible values)
 */
reg [4:0] level;

wire [63:0] do64;
assign do64 = storage[consume[3:2]];

always @(*) begin
	case(consume[1:0])
		2'd0: do <= do64[63:48];
		2'd1: do <= do64[47:32];
		2'd2: do <= do64[31:16];
		2'd3: do <= do64[15:0];
	endcase
end

always @(posedge sys_clk) begin
	if(vga_rst) begin
		produce = 2'd0;
		consume = 4'd0;
		level = 5'd0;
	end else begin
		if(stb) begin
			storage[produce] = di;
			produce = produce + 2'd1;
			level = level + 5'd4;
		end
		if(next) begin /* next should only be asserted when do_valid = 1 */
			consume = consume + 4'd1;
			level = level - 5'd1;
		end
	end
end

assign do_valid = ~(level == 5'd0);

endmodule
