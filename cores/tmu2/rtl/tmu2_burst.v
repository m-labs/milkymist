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

module tmu2_burst #(
	parameter fml_depth = 26
) (
	input sys_clk,
	input sys_rst,
	
	input flush,
	output reg busy,
	
	input pipe_stb_i,
	output pipe_ack_o,
	input [15:0] color,
	input [fml_depth-1-1:0] dadr, /* in 16-bit words */
	
	output reg pipe_stb_o,
	input pipe_ack_i,
	output reg [fml_depth-5-1:0] burst_addr, /* in 256-bit words */
	/* 16-bit granularity selection that needs to be expanded
	 * to 8-bit granularity selection to drive the FML lines.
	 */
	output reg [15:0] burst_sel,
	output reg [255:0] burst_do
);

wire burst_hit = dadr[fml_depth-1-1:4] == burst_addr;

/* Always memorize input in case we have to ack a cycle we cannot immediately handle */
reg [15:0] color_r;
reg [fml_depth-1-1:0] dadr_r;
always @(posedge sys_clk) begin
	if(pipe_stb_i & pipe_ack_o) begin
		color_r <= color;
		dadr_r <= dadr;
	end
end

/* Write to the burst storage registers */
reg clear_en;
reg write_en;
reg use_memorized;
wire [15:0] color_mux = use_memorized ? color_r : color;
wire [fml_depth-1-1:0] dadr_mux = use_memorized ? dadr_r : dadr;
always @(posedge sys_clk) begin
	if(sys_rst)
		burst_sel = 16'd0;
	else begin
		if(clear_en)
			burst_sel = 16'd0;
		if(write_en) begin
			burst_addr = dadr_mux[fml_depth-1-1:4]; /* update tag */
			case(dadr_mux[3:0]) /* unmask */
				4'd00: burst_sel = burst_sel | 16'h8000;
				4'd01: burst_sel = burst_sel | 16'h4000;
				4'd02: burst_sel = burst_sel | 16'h2000;
				4'd03: burst_sel = burst_sel | 16'h1000;
				4'd04: burst_sel = burst_sel | 16'h0800;
				4'd05: burst_sel = burst_sel | 16'h0400;
				4'd06: burst_sel = burst_sel | 16'h0200;
				4'd07: burst_sel = burst_sel | 16'h0100;
				4'd08: burst_sel = burst_sel | 16'h0080;
				4'd09: burst_sel = burst_sel | 16'h0040;
				4'd10: burst_sel = burst_sel | 16'h0020;
				4'd11: burst_sel = burst_sel | 16'h0010;
				4'd12: burst_sel = burst_sel | 16'h0008;
				4'd13: burst_sel = burst_sel | 16'h0004;
				4'd14: burst_sel = burst_sel | 16'h0002;
				4'd15: burst_sel = burst_sel | 16'h0001;
			endcase
			case(dadr_mux[3:0]) /* register data */
				4'd00: burst_do[255:240] = color_mux;
				4'd01: burst_do[239:224] = color_mux;
				4'd02: burst_do[223:208] = color_mux;
				4'd03: burst_do[207:192] = color_mux;
				4'd04: burst_do[191:176] = color_mux;
				4'd05: burst_do[175:160] = color_mux;
				4'd06: burst_do[159:144] = color_mux;
				4'd07: burst_do[143:128] = color_mux;
				4'd08: burst_do[127:112] = color_mux;
				4'd09: burst_do[111: 96] = color_mux;
				4'd10: burst_do[ 95: 80] = color_mux;
				4'd11: burst_do[ 79: 64] = color_mux;
				4'd12: burst_do[ 63: 48] = color_mux;
				4'd13: burst_do[ 47: 32] = color_mux;
				4'd14: burst_do[ 31: 16] = color_mux;
				4'd15: burst_do[ 15:  0] = color_mux;
			endcase
		end
	end
end

wire empty = (burst_sel == 16'd0);

reg state;
reg next_state;

parameter RUNNING	= 1'b0;
parameter DOWNSTREAM	= 1'b1;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= RUNNING;
	else
		state <= next_state;
end

/*
 * generate pipe_ack_o using an assign statement to work around a bug in CVER
 */

assign pipe_ack_o = (state == RUNNING) & (~flush | empty);

always @(*) begin
	next_state = state;
	busy = 1'b1;
	// CVER WA (see above) pipe_ack_o = 1'b0;
	pipe_stb_o = 1'b0;
	write_en = 1'b0;
	clear_en = 1'b0;
	use_memorized = 1'b0;
	
	case(state)
		RUNNING: begin
			busy = 1'b0;
			if(flush & ~empty)
				next_state = DOWNSTREAM;
			else begin
				// CVER WA (see above) pipe_ack_o = 1'b1;
				if(pipe_stb_i) begin
					if(burst_hit | empty)
						write_en = 1'b1;
					else
						next_state = DOWNSTREAM;
				end
			end
		end
		DOWNSTREAM: begin
			pipe_stb_o = 1'b1;
			use_memorized = 1'b1;
			if(pipe_ack_i) begin
				clear_en = 1'b1;
				write_en = 1'b1;
				next_state = RUNNING;
			end
		end
	endcase
end

endmodule
