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

module tmu2_fifo64to256 #(
	parameter depth = 2 /* < log2 of the capacity, in 256-bit words */
) (
	input sys_clk,
	input sys_rst,
	
	output w8avail,
	input we,
	input [63:0] wd,
	
	output ravail,
	input re,
	output [255:0] rd
);

reg [63:0] storage1[0:(1 << depth)-1];
reg [63:0] storage2[0:(1 << depth)-1];
reg [63:0] storage3[0:(1 << depth)-1];
reg [63:0] storage4[0:(1 << depth)-1];

reg [depth+2:0] level;
reg [depth+1:0] produce;
reg [depth-1:0] consume;

wire wavail = ~level[depth+2];
assign w8avail = level < ((1 << (depth + 2)) - 8);
assign ravail = |(level[depth+2:2]);

wire read = re & ravail;
wire write = we & wavail;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		level <= 0;
		produce <= 0;
		consume <= 0;
	end else begin
		if(read)
			consume <= consume + 1;
		if(write) begin
			produce <= produce + 1;
			case(produce[1:0])
				2'd0: storage1[produce[depth+1:2]] <= wd;
				2'd1: storage2[produce[depth+1:2]] <= wd;
				2'd2: storage3[produce[depth+1:2]] <= wd;
				2'd3: storage4[produce[depth+1:2]] <= wd;
			endcase
		end
		case({read, write})
			2'b10: level <= level - 4;
			2'b01: level <= level + 1;
			2'b11: level <= level - 3;
		endcase
	end
end

assign rd = {storage1[consume], storage2[consume], storage3[consume], storage4[consume]};

endmodule
