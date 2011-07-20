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

module tmu2_buffer #(
	parameter width = 8,
	parameter depth = 1 /* < log2 of the storage size, in words */
) (
	input sys_clk,
	input sys_rst,

	output busy,

	input pipe_stb_i,
	output pipe_ack_o,
	input [width-1:0] dat_i,

	output pipe_stb_o,
	input pipe_ack_i,
	output [width-1:0] dat_o
);

reg [width-1:0] storage[0:(1 << depth)-1];

reg [depth-1:0] produce;
reg [depth-1:0] consume;
reg [depth:0] level;

wire inc = pipe_stb_i & pipe_ack_o;
wire dec = pipe_stb_o & pipe_ack_i;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		produce <= 0;
		consume <= 0;
	end else begin
		if(inc)
			produce <= produce + 1;
		if(dec)
			consume <= consume + 1;
	end
end

always @(posedge sys_clk) begin
	if(sys_rst)
		level <= 0;
	else begin
		case({inc, dec})
			2'b10: level <= level + 1;
			2'b01: level <= level - 1;
			default:;
		endcase
	end
end

always @(posedge sys_clk) begin
	if(inc)
		storage[produce] <= dat_i;
end

assign dat_o = storage[consume];

assign busy = |level;
assign pipe_ack_o = ~level[depth];
assign pipe_stb_o = |level;

endmodule
