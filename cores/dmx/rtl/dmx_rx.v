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

module dmx_rx #(
	parameter csr_addr = 4'h0,
	parameter clk_freq = 100000000
) (
	input sys_clk,
	input sys_rst,

	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output [31:0] csr_do,

	input rx
);

/* RAM and CSR interface */

wire csr_selected = csr_a[13:10] == csr_addr;

wire [7:0] csr_channel;
reg [8:0] channel_a;
reg channel_we;
reg [7:0] channel_d;
dmx_dpram channels(
	.clk(sys_clk),

	.a(csr_a[8:0]),
	.we(1'b0),
	.di(8'hxx),
	.do(csr_channel),

	.a2(channel_a),
	.we2(channel_we),
	.di2(channel_d),
	.do2()
);

always @(posedge sys_clk) begin
	if(channel_we)
		$display("Received value %x for channel %x", channel_d, channel_a);
end

reg csr_selected_r;
always @(posedge sys_clk)
	csr_selected_r <= csr_selected;

assign csr_do = {24'h000000, csr_selected_r ? csr_channel : 8'h00};

/* Synchronizer */

reg rx_r0;
reg rx_r;
always @(posedge sys_clk) begin
	rx_r0 <= rx;
	rx_r <= rx_r0;
end

/* Signal decoder */

parameter divisor = clk_freq/250000;
parameter halfbit = clk_freq/500000;

reg ce_load;
reg ce;
reg [8:0] ce_counter;
always @(posedge sys_clk) begin
	if(ce_load) begin
		ce <= 1'b0;
		ce_counter <= halfbit-1;
	end else begin
		if(ce_counter == 9'd0) begin
			ce <= 1'b1;
			ce_counter <= divisor-1;
		end else begin
			ce <= 1'b0;
			ce_counter <= ce_counter - 9'd1;
		end
	end
end

reg channel_a_reset;
reg channel_a_ce;
always @(posedge sys_clk) begin
	if(channel_a_reset)
		channel_a <= 9'd0;
	else if(channel_a_ce)
		channel_a <= channel_a + 9'd1;
end

reg channel_d_load_en;
reg [2:0] channel_d_load;
always @(posedge sys_clk) begin
	if(channel_d_load_en)
		channel_d[channel_d_load] <= rx_r;
end

parameter break_threshold = clk_freq/11364;
reg [12:0] break_counter;
wire break = break_counter == 13'd0;
always @(posedge sys_clk) begin
	if(sys_rst|rx_r)
		break_counter <= break_threshold;
	else if(~break)
		break_counter <= break_counter - 13'd1;
end

reg [3:0] state;
reg [3:0] next_state;

parameter WAIT_BREAK =		4'd0;
parameter WAIT_MAB =		4'd1;
parameter WAIT_START =		4'd2;
parameter SAMPLE_START =	4'd3;
parameter SAMPLE0 =		4'd4;
parameter SAMPLE1 =		4'd5;
parameter SAMPLE2 =		4'd6;
parameter SAMPLE3 =		4'd7;
parameter SAMPLE4 =		4'd8;
parameter SAMPLE5 =		4'd9;
parameter SAMPLE6 =		4'd10;
parameter SAMPLE7 =		4'd11;
parameter SAMPLE_STOP1 =	4'd12;
parameter SAMPLE_STOP2 =	4'd13;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= WAIT_BREAK;
	else
		state <= next_state;
end

/* skip 1st byte (start code) */
reg skip;
reg next_skip;
always @(posedge sys_clk)
	skip <= next_skip;

always @(*) begin
	ce_load = 1'b0;
	channel_a_reset = 1'b0;
	channel_a_ce = 1'b0;
	channel_we = 1'b0;
	channel_d_load_en = 1'b0;
	channel_d_load = 3'bxxx;

	next_state = state;
	next_skip = skip;

	case(state)
		WAIT_BREAK: begin
			ce_load = 1'b1;
			channel_a_reset = 1'b1;
			next_skip = 1'b1;
			if(break)
				next_state = WAIT_MAB;
		end
		WAIT_MAB: begin
			ce_load = 1'b1;
			channel_a_reset = 1'b1;
			if(rx_r)
				next_state = WAIT_START;
		end

		WAIT_START: begin
			ce_load = 1'b1;
			if(~rx_r)
				next_state = SAMPLE_START;
		end
		SAMPLE_START: begin
			if(ce) begin
				if(rx_r) /* confirm start bit */
					next_state = WAIT_BREAK;
				else
					next_state = SAMPLE0;
			end
		end
		SAMPLE0: begin
			channel_d_load_en = 1'b1;
			channel_d_load = 3'd0;
			if(ce)
				next_state = SAMPLE1;
		end
		SAMPLE1: begin
			channel_d_load_en = 1'b1;
			channel_d_load = 3'd1;
			if(ce)
				next_state = SAMPLE2;
		end
		SAMPLE2: begin
			channel_d_load_en = 1'b1;
			channel_d_load = 3'd2;
			if(ce)
				next_state = SAMPLE3;
		end
		SAMPLE3: begin
			channel_d_load_en = 1'b1;
			channel_d_load = 3'd3;
			if(ce)
				next_state = SAMPLE4;
		end
		SAMPLE4: begin
			channel_d_load_en = 1'b1;
			channel_d_load = 3'd4;
			if(ce)
				next_state = SAMPLE5;
		end
		SAMPLE5: begin
			channel_d_load_en = 1'b1;
			channel_d_load = 3'd5;
			if(ce)
				next_state = SAMPLE6;
		end
		SAMPLE6: begin
			channel_d_load_en = 1'b1;
			channel_d_load = 3'd6;
			if(ce)
				next_state = SAMPLE7;
		end
		SAMPLE7: begin
			channel_d_load_en = 1'b1;
			channel_d_load = 3'd7;
			if(ce)
				next_state = SAMPLE_STOP1;
		end
		SAMPLE_STOP1: begin
			if(ce) begin
				if(rx_r) /* verify 1st stop bit */
					next_state = SAMPLE_STOP2;
				else
					next_state = WAIT_BREAK;
			end
		end
		SAMPLE_STOP2: begin
			if(ce) begin
				if(rx_r) begin /* verify 2nd stop bit */
					next_skip = 1'b0;
					if(~skip) begin
						channel_we = 1'b1;
						channel_a_ce = 1'b1;
					end
					next_state = WAIT_START;
				end else
					next_state = WAIT_BREAK;
			end
		end
	endcase
end

endmodule
