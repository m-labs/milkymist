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

module memtest_prng64(
	input clk,
	input rst,
	input ce,
	output reg [63:0] rand
);

reg [30:0] state;

reg o;
integer i;
always @(posedge clk) begin
	if(rst) begin
		state = 31'd0;
		rand = 64'd0;
	end else if(ce) begin
		for(i=0;i<64;i=i+1) begin
			o = ~(state[30] ^ state[27]);
			rand[i] = o;
			state = {state[29:0], o};
		end
	end
end

endmodule
