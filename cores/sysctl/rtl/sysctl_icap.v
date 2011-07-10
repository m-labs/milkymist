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

module sysctl_icap(
	input sys_clk,
	input sys_rst,

	output reg ready,
	input we,
	input [15:0] d,
	input ce,
	input write
);

reg icap_clk;
reg icap_clk_r;
reg d_ce;
reg [15:0] d_r;
reg ce_r;
reg write_r;
always @(posedge sys_clk) begin
	if(d_ce) begin
		d_r[0] <= d[7];
		d_r[1] <= d[6];
		d_r[2] <= d[5];
		d_r[3] <= d[4];
		d_r[4] <= d[3];
		d_r[5] <= d[2];
		d_r[6] <= d[1];
		d_r[7] <= d[0];
		d_r[8] <= d[15];
		d_r[9] <= d[14];
		d_r[10] <= d[13];
		d_r[11] <= d[12];
		d_r[12] <= d[11];
		d_r[13] <= d[10];
		d_r[14] <= d[9];
		d_r[15] <= d[8];

		ce_r <= ce;
		write_r <= write;
	end
	icap_clk_r <= icap_clk;
end

ICAP_SPARTAN6 icap(
	.BUSY(),
	.O(),
	.CE(ce_r),
	.CLK(icap_clk_r),
	.I(d_r),
	.WRITE(write_r)
);

parameter IDLE =	3'd0;
parameter C1 =		3'd1;
parameter C2 =		3'd2;
parameter C3 =		3'd3;
parameter C4 =		3'd4;
parameter C5 =		3'd5;

reg [2:0] state;
reg [2:0] next_state;

initial state = IDLE;

always @(posedge sys_clk)
	state <= next_state;

always @(*) begin
	ready = 1'b0;
	icap_clk = 1'b0;
	d_ce = 1'b0;

	next_state = state;

	case(state)
		IDLE: begin
			ready = 1'b1;
			if(we & ~sys_rst) begin
				d_ce = 1'b1;
				next_state = C1;
			end
		end
		C1: begin
			next_state = C2;
		end
		C2: begin
			icap_clk = 1'b1;
			next_state = C3;
		end
		C3: begin
			icap_clk = 1'b1;
			next_state = C4;
		end
		C4: begin
			icap_clk = 1'b1;
			next_state = C5;
		end
		C5: begin
			next_state = IDLE;
		end
	endcase
end

endmodule
