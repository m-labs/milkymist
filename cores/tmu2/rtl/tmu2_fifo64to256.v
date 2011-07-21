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

module tmu2_fifo64to256(
	input sys_clk,
	input sys_rst,
	
	output w8avail,
	input we,
	input [63:0] wd,
	
	output ravail,
	input re,
	output [255:0] rd
);

reg [63:0] storage1[0:3];
reg [63:0] storage2[0:3];
reg [63:0] storage3[0:3];
reg [63:0] storage4[0:3];

reg [4:0] level;
reg [3:0] produce;
reg [1:0] consume;

wire wavail = ~level[4];
wire w8avail = ~level[4] & ~level[3];
wire ravail = |(level[4:2]);

wire read = re & ravail;
wire write = we & wavail;

always @(posedge sys_clk) begin
	if(read)
		consume <= consume + 2'd1;
	if(write) begin
		produce <= produce + 4'd1;
		case(produce[1:0])
			2'd0: storage1[produce[3:2]] <= wd;
			2'd1: storage2[produce[3:2]] <= wd;
			2'd2: storage3[produce[3:2]] <= wd;
			2'd3: storage4[produce[3:2]] <= wd;
		endcase
	end
	case({read, write})
		2'b10: level <= level - 5'd4;
		2'b01: level <= level + 5'd1;
		2'b11: level <= level - 5'd3;
	endcase
end

assign rd = {storage1[consume], storage2[consume], storage3[consume], storage4[consume]};

endmodule
