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

module sysctl_icap(
	input sys_clk,

	output reg ready,
	input we,
	input [15:0] d
);

reg icap_clk;
reg icap_clk_r;
reg d_ce;
reg [15:0] d_r;
always @(posedge sys_clk) begin
	if(d_ce)
		d_r <= d;
	icap_clk_r <= icap_clk;
end

ICAP_SPARTAN6 icap(
	.BUSY(),
	.O(),
	.CE(1'b0),
	.CLK(icap_clk_r),
	.I(d_r),
	.WRITE(1'b0)
);

parameter IDLE =	2'd0;
parameter C1 =		2'd1;
parameter C2 =		2'd2;
parameter C3 =		2'd3;

reg [1:0] state;
reg [1:0] next_state;

initial state = IDLE;

always @(posedge sys_clk)
	state <= next_state;

always @(*) begin
	ready = 1'b0;
	icap_clk = 1'b0;
	d_ce = 1'b0;

	case(state)
		IDLE: begin
			ready = 1'b1;
			d_ce = 1'b1;
			if(we)
				next_state = C1;
		end
		C1: begin
			next_state = C2;
			icap_clk = 1'b1;
		end
		C2: begin
			next_state = C3;
			icap_clk = 1'b1;
		end
		C3: next_state = IDLE;
	endcase
end

endmodule
