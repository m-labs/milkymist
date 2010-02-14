/*
 * Milkymist VJ SoC
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

module tmu2_wb_tagmem #(
	parameter width = 3
) (
	input sys_clk,
	input sys_rst,
	
	input [1:0] a,
	input we,
	input [width-1:0] di,
	output reg [width-1:0] do,

	input [1:0] a2,
	output reg [width-1:0] do2
);

reg [width-1:0] reg0;
reg [width-1:0] reg1;
reg [width-1:0] reg2;
reg [width-1:0] reg3;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		reg0 <= {width{1'b0}};
		reg1 <= {width{1'b0}};
		reg2 <= {width{1'b0}};
		reg3 <= {width{1'b0}};
	end else begin
		if(we) begin
			case(a)
				2'd0: reg0 <= di;
				2'd1: reg1 <= di;
				2'd2: reg2 <= di;
				2'd3: reg3 <= di;
			endcase
		end
	end
end

reg [1:0] a_r;
reg [1:0] a2_r;

always @(posedge sys_clk) begin
	a_r <= a;
	a2_r <= a2;
end

always @(*) begin
	case(a_r)
		2'd0: do = reg0;
		2'd1: do = reg1;
		2'd2: do = reg2;
		default: do = reg3;
	endcase
end

always @(*) begin
	case(a2_r)
		2'd0: do2 = reg0;
		2'd1: do2 = reg1;
		2'd2: do2 = reg2;
		default: do2 = reg3;
	endcase
end

endmodule
