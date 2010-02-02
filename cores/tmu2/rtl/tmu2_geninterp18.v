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

module tmu2_geninterp18(
	input sys_clk,

	input load,
	input next_point,
	input signed [17:0] init,
	input positive,
	input [16:0] q,
	input [16:0] r,
	input [16:0] divisor,

	output [17:0] o
);

/* VCOMP doesn't like "output reg signed", work around */
reg signed [17:0] o;

reg [17:0] err;
reg correct;

always @(posedge sys_clk) begin
	if(load) begin
		err <= 18'd0;
		o <= init;
	end else if(next_point) begin
		err = err + r;
		correct = (err[16:0] > {1'b0, divisor[16:1]}) & ~err[17];
		if(positive) begin
			o = o + {1'b0, q};
			if(correct)
				o = o + 18'd1;
		end else begin
			o = o - {1'b0, q};
			if(correct)
				o = o - 18'd1;
		end
		if(correct)
			err = err - {1'b0, divisor};
	end
end

endmodule
