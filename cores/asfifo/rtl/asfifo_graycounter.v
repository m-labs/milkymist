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

/*
 * This file is based on "Asynchronous FIFO" by Alex Claros F.,
 * itself based on the article "Asynchronous FIFO in Virtex-II FPGAs"
 * by Peter Alfke.
 */

module asfifo_graycounter #(
	parameter width = 2
) (
	output reg [width-1:0] gray_count,
	input ce,
	input rst,
	input clk
);

reg [width-1:0] binary_count;

always @(posedge clk, posedge rst) begin
	if(rst) begin
		binary_count <= {width{1'b0}} + 1;
		gray_count <= {width{1'b0}};
	end else if(ce) begin
		binary_count <= binary_count + 1;
		gray_count <= {binary_count[width-1],
				binary_count[width-2:0] ^ binary_count[width-1:1]};
	end
end

endmodule
