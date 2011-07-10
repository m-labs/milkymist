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

/* 17-bit, 17-cycle unsigned integer divider, non pipelined */

module tmu2_divider17(
	input sys_clk,
	input sys_rst,

	input start,
	input [16:0] dividend,
	input [16:0] divisor,
	
	output ready,
	output [16:0] quotient,
	output [16:0] remainder
);

reg [33:0] qr;

assign remainder = qr[33:17];
assign quotient = qr[16:0];

reg [4:0] counter;
assign ready = (counter == 5'd0);

reg [16:0] divisor_r;

wire [17:0] diff = qr[33:16] - {1'b0, divisor_r};

always @(posedge sys_clk) begin
	if(sys_rst)
		counter = 5'd0;
	else begin
		if(start) begin
			counter = 5'd17;
			qr = {17'd0, dividend};
			divisor_r = divisor;
		end else begin
			if(~ready) begin
				if(diff[17])
					qr = {qr[32:0], 1'b0};
				else
					qr = {diff[16:0], qr[15:0], 1'b1};
				counter = counter - 5'd1;
			end
		end
	end
end

endmodule
