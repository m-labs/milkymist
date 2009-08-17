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

/*
 * Triple-port synchronous 128x32 RAM
 * Port 1, read-only
 * Port 2, read-only
 * Port 3, write-only
 */

module pfpu_tpram(
	input sys_clk,
	
	input [6:0] p1_a,
	output reg [31:0] p1_d,
	
	input [6:0] p2_a,
	output reg [31:0] p2_d,
	
	input p3_en,
	input [6:0] p3_a,
	input [31:0] p3_d
);

/*
 * Duplicate the contents over two dual-port BRAMs
 *       Port A(WO)   Port B(RO)
 * Mem1     P3           P1
 * Mem2     P3           P2
 */

reg [31:0] mem1[0:127];
always @(posedge sys_clk) begin
	if(p3_en)
		mem1[p3_a] <= p3_d;
	p1_d <= mem1[p1_a];
end

reg [31:0] mem2[0:127];
always @(posedge sys_clk) begin
	if(p3_en)
		mem2[p3_a] <= p3_d;
	p2_d <= mem2[p2_a];
end

endmodule

