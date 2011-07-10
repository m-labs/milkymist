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

module tmu2_geninterp18(
	input sys_clk,

	input load,
	input next_point,
	input signed [17:0] init,
	input positive,
	input [16:0] q,
	input [16:0] r,
	input [16:0] divisor,

	output signed [17:0] o
);

reg positive_r;
reg [16:0] q_r;
reg [16:0] r_r;
reg [16:0] divisor_r;

always @(posedge sys_clk) begin
	if(load) begin
		positive_r <= positive;
		q_r <= q;
		r_r <= r;
		divisor_r <= divisor;
	end
end

reg [17:0] err;
reg correct;
reg signed [17:0] o_r;
assign o = o_r;

always @(posedge sys_clk) begin
	if(load) begin
		err = 18'd0;
		o_r = init;
	end else if(next_point) begin
		err = err + r_r;
		correct = (err[16:0] > {1'b0, divisor_r[16:1]}) & ~err[17];
		if(positive_r) begin
			o_r = o_r + {1'b0, q_r};
			if(correct)
				o_r = o_r + 18'd1;
		end else begin
			o_r = o_r - {1'b0, q_r};
			if(correct)
				o_r = o_r - 18'd1;
		end
		if(correct)
			err = err - {1'b0, divisor_r};
	end
end

endmodule
