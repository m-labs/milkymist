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

module conbus_arb(
	input sys_clk,
	input sys_rst,
	
	input [4:0] req,
	output [4:0] gnt
);

parameter [4:0] grant0 = 5'b00001,
                grant1 = 5'b00010,
                grant2 = 5'b00100,
                grant3 = 5'b01000,
                grant4 = 5'b10000;

reg [4:0] state;
reg [4:0] next_state;

assign gnt = state;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= grant0;
	else
		state <= next_state;
end

always @(*) begin
	next_state = state;
	case(state)
		grant0: begin
			if(~req[0]) begin
				     if(req[1]) next_state = grant1;
				else if(req[2]) next_state = grant2;
				else if(req[3]) next_state = grant3;
				else if(req[4]) next_state = grant4;
			end
		end
		grant1: begin
			if(~req[1]) begin
				     if(req[2]) next_state = grant2;
				else if(req[3]) next_state = grant3;
				else if(req[4]) next_state = grant4;
				else if(req[0]) next_state = grant0;
			end
		end
		grant2: begin
			if(~req[2]) begin
				     if(req[3]) next_state = grant3;
				else if(req[4]) next_state = grant4;
				else if(req[0]) next_state = grant0;
				else if(req[1]) next_state = grant1;
			end
		end
		grant3: begin
			if(~req[3]) begin
				     if(req[4]) next_state = grant4;
				else if(req[0]) next_state = grant0;
				else if(req[1]) next_state = grant1;
				else if(req[2]) next_state = grant2;
			end
		end
		grant4: begin
			if(~req[4]) begin
				     if(req[0]) next_state = grant0;
				else if(req[1]) next_state = grant1;
				else if(req[2]) next_state = grant2;
				else if(req[3]) next_state = grant3;
			end
		end
	endcase
end

endmodule
