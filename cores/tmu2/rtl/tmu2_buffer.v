/*
 * Milkymist SoC
 * Copyright (C) 2007, 2008, 2009, 2010 Sebastien Bourdeauducq
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
	parameter width = 8
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

reg [width-1:0] storage1;
reg [width-1:0] storage2;

reg produce;
reg consume;
reg [1:0] level;

wire inc = pipe_stb_i & pipe_ack_o;
wire dec = pipe_stb_o & pipe_ack_i;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		produce <= 1'b0;
		consume <= 1'b0;
	end else begin
		if(inc)
			produce <= ~produce;
		if(dec)
			consume <= ~consume;
	end
end

always @(posedge sys_clk) begin
	if(sys_rst)
		level <= 2'd0;
	else begin
		case({inc, dec})
			2'b10: level <= level + 2'd1;
			2'b01: level <= level - 2'd1;
			default:;
		endcase
	end
end

always @(posedge sys_clk) begin
	if(inc) begin
		if(produce)
			storage2 <= dat_i;
		else
			storage1 <= dat_i;
	end
end

assign dat_o = consume ? storage2 : storage1;

assign busy = |level;
assign pipe_ack_o = ~level[1];
assign pipe_stb_o = |level;

endmodule
