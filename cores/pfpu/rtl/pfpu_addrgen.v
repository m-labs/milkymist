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

module pfpu_counters(
	input sys_clk,
	
	input first,
	input next,

	input [6:0] hmesh_last,
	input [6:0] vmesh_last,
	
	output [31:0] r0,
	output [31:0] r1,
	output reg last
);

reg [6:0] r0r;
assign r0 = {25'd0, r0r};
reg [6:0] r1r;
assign r1 = {25'd0, r1r};

always @(posedge sys_clk) begin
	if(first) begin
		r0r <= 7'd0;
		r1r <= 7'd0;
	end else if(next) begin
		if(r0r == hmesh_last) begin
			r0r <= 7'd0;
			r1r <= r1r + 7'd1;
		end else
			r0r <= r0r + 7'd1;
	end
end

/* Having some latency in the generation of "last"
 * is not a problem, because DMA is never immediately
 * triggered after "first" or "next" has been
 * asserted.
 */
always @(posedge sys_clk)
	last <= (r0r == hmesh_last) & (r1r == vmesh_last);

endmodule
