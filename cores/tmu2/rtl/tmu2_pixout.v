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

module tmu2_pixout #(
	parameter fml_depth = 26
) (
	input sys_clk,
	input sys_rst,
	
	output reg busy,
	
	input pipe_stb_i,
	output reg pipe_ack_o,
	input [fml_depth-5-1:0] burst_addr,
	input [15:0] burst_sel,
	input [255:0] burst_do,
	
	output reg [fml_depth-1:0] fml_adr,
	output reg fml_stb,
	input fml_ack,
	output reg [7:0] fml_sel,
	output reg [63:0] fml_do
);

reg [15:0] burst_sel_r;
reg [255:0] burst_do_r;

reg load;
always @(posedge sys_clk) begin
	if(load) begin
		fml_adr = {burst_addr, 5'd0};
		burst_sel_r = burst_sel;
		burst_do_r = burst_do;
	end
end

reg [1:0] bcounter;
always @(posedge sys_clk) begin
	case(bcounter)
		2'd0: begin
			fml_sel <= {
				burst_sel_r[15], burst_sel_r[15],
				burst_sel_r[14], burst_sel_r[14],
				burst_sel_r[13], burst_sel_r[13],
				burst_sel_r[12], burst_sel_r[12]
				};
			fml_do <= burst_do_r[255:192];
		end
		2'd1: begin
			fml_sel <= {
				burst_sel_r[11], burst_sel_r[11],
				burst_sel_r[10], burst_sel_r[10],
				burst_sel_r[ 9], burst_sel_r[ 9],
				burst_sel_r[ 8], burst_sel_r[ 8]
				};
			fml_do <= burst_do_r[191:128];
		end
		2'd2: begin
			fml_sel <= {
				burst_sel_r[ 7], burst_sel_r[ 7],
				burst_sel_r[ 6], burst_sel_r[ 6],
				burst_sel_r[ 5], burst_sel_r[ 5],
				burst_sel_r[ 4], burst_sel_r[ 4]
				};
			fml_do <= burst_do_r[127: 64];
		end
		2'd3: begin
			fml_sel <= {
				burst_sel_r[ 3], burst_sel_r[ 3],
				burst_sel_r[ 2], burst_sel_r[ 2],
				burst_sel_r[ 1], burst_sel_r[ 1],
				burst_sel_r[ 0], burst_sel_r[ 0]
				};
			fml_do <= burst_do_r[ 63:  0];
		end
	endcase
end

reg [1:0] state;
reg [1:0] next_state;

parameter IDLE	= 2'd0;
parameter WAIT	= 2'd1;
parameter XFER2	= 2'd2;
parameter XFER3	= 2'd3;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= IDLE;
	else
		state <= next_state;
end

always @(*) begin
	next_state = state;
	
	busy = 1'b1;
	pipe_ack_o = 1'b0;
	fml_stb = 1'b0;
	
	load = 1'b0;
	bcounter = 2'bxx;
	
	case(state)
		IDLE: begin
			busy = 1'b0;
			pipe_ack_o = 1'b1;
			bcounter = 2'd0;
			if(pipe_stb_i) begin
				load = 1'b1;
				next_state = WAIT;
			end
		end
		WAIT: begin
			fml_stb = 1'b1;
			bcounter = 2'd0;
			if(fml_ack) begin
				bcounter = 2'd1;
				next_state = XFER2;
			end
		end
		XFER2: begin
			bcounter = 2'd2;
			next_state = XFER3;
		end
		XFER3: begin
			bcounter = 2'd3;
			next_state = IDLE;
		end
	endcase
end

endmodule
