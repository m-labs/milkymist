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

module tmu_perfcounters(
	input sys_clk,
	input sys_rst,
	
	input start,
	input busy,
	
	input inc_pixels,
	
	input stb1,
	input ack1,
	
	input stb2,
	input ack2,
	
	input inc_misses,

	output reg [31:0] perf_pixels,
	output reg [31:0] perf_clocks,
	
	output reg [31:0] perf_stall1,
	output reg [31:0] perf_complete1,
	output reg [31:0] perf_stall2,
	output reg [31:0] perf_complete2,
	
	output reg [31:0] perf_misses
);

always @(posedge sys_clk) begin
	if(sys_rst|start) begin
		perf_pixels <= 32'd0;
		perf_clocks <= 32'd0;
	end else begin
		if(busy) perf_clocks <= perf_clocks + 32'd1;
		if(inc_pixels) perf_pixels <= perf_pixels + 32'd1;
	end
end

always @(posedge sys_clk) begin
	if(sys_rst|start) begin
		perf_stall1 <= 32'd0;
		perf_complete1 <= 32'd0;
	end else begin
		if(stb1) begin
			if(ack1)
				perf_complete1 <= perf_complete1 + 32'd1;
			else
				perf_stall1 <= perf_stall1 + 32'd1;
		end
	end
end

always @(posedge sys_clk) begin
	if(sys_rst|start) begin
		perf_stall2 <= 32'd0;
		perf_complete2 <= 32'd0;
	end else begin
		if(stb2) begin
			if(ack2)
				perf_complete2 <= perf_complete2 + 32'd1;
			else
				perf_stall2 <= perf_stall2 + 32'd1;
		end
	end
end

always @(posedge sys_clk) begin
	if(sys_rst|start)
		perf_misses <= 32'd0;
	else if(inc_misses)
		perf_misses <= perf_misses + 32'd1;
end

endmodule
