/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 *
 * This program is free and excepted software; you can use it, redistribute it
 * and/or modify it under the terms of the Exception General Public License as
 * published by the Exception License Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the Exception General Public License for more
 * details.
 *
 * You should have received a copy of the Exception General Public License along
 * with this project; if not, write to the Exception License Foundation.
 */

/* 11-bit, 11-cycle integer divider, non pipelined */

module tmu_divider11(
	input sys_clk,
	input sys_rst,

	input start,
	input [10:0] dividend,
	input [10:0] divisor,
	
	output ready,
	output [10:0] quotient,
	output [10:0] remainder
);

reg [21:0] qr;

assign remainder = qr[21:11];
assign quotient = qr[10:0];

reg [3:0] counter;
assign ready = (counter == 4'd0);

reg [10:0] divisor_r;

wire [11:0] diff = qr[21:10] - {1'b0, divisor_r};

always @(posedge sys_clk) begin
	if(sys_rst)
		counter = 4'd0;
	else begin
		if(start) begin
			counter = 4'd11;
			qr = {11'd0, dividend};
			divisor_r = divisor;
		end else begin
			if(~ready) begin
				if(diff[11])
					qr = {qr[20:0], 1'b0};
				else
					qr = {diff[10:0], qr[9:0], 1'b1};
				counter = counter - 4'd1;
			end
		end
	end
end

endmodule
