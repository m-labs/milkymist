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

module tmu2_texcache #(
	parameter cache_depth = 13, /* < log2 of the capacity in 8-bit words */
	parameter fml_depth = 26
) (
	input sys_clk,
	input sys_rst,

	output [fml_depth-1:0] fml_adr,
	output reg fml_stb,
	input fml_ack,
	input [63:0] fml_di,

	input flush,
	output busy,

	input pipe_stb_i,
	output pipe_ack_o,
	input [fml_depth-1-1:0] dadr, /* in 16-bit words */
	input [fml_depth-1-1:0] tadra,
	input [fml_depth-1-1:0] tadrb,
	input [fml_depth-1-1:0] tadrc,
	input [fml_depth-1-1:0] tadrd,
	input [5:0] x_frac,
	input [5:0] y_frac,

	output pipe_stb_o,
	input pipe_ack_i,
	output reg [fml_depth-1-1:0] dadr_f, /* in 16-bit words */
	output [15:0] tcolora,
	output [15:0] tcolorb,
	output [15:0] tcolorc,
	output [15:0] tcolord,
	output reg [5:0] x_frac_f,
	output reg [5:0] y_frac_f
);

/*
 * To make bit index calculations easier,
 * we work with 8-bit granularity EVERYWHERE, unless otherwise noted.
 */

/*
 * Line length is the burst length, that is 4*64 bits, or 32 bytes
 * Addresses are split as follows:
 *
 * |             TAG            |         INDEX          |   OFFSET   |
 * |fml_depth-1      cache_depth|cache_depth-1          5|4          0|
 *
 */

/* MEMORIES & HIT HANDLING */

wire [fml_depth-1:0] tadra8 = {tadra, 1'b0};
wire [fml_depth-1:0] tadrb8 = {tadrb, 1'b0};
wire [fml_depth-1:0] tadrc8 = {tadrc, 1'b0};
wire [fml_depth-1:0] tadrd8 = {tadrd, 1'b0};

reg [fml_depth-1:0] tadra8_r;
reg [fml_depth-1:0] tadrb8_r;
reg [fml_depth-1:0] tadrc8_r;
reg [fml_depth-1:0] tadrd8_r;

always @(posedge sys_clk) begin
	if(pipe_ack_o) begin
		tadra8_r <= tadra8;
		tadrb8_r <= tadrb8;
		tadrc8_r <= tadrc8;
		tadrd8_r <= tadrd8;
	end
end

wire retry; /* < retry the old address after a miss */

wire [31:0] datamem_d1;
wire [31:0] datamem_d2;
wire [31:0] datamem_d3;
wire [31:0] datamem_d4;

reg datamem_we;
wire [cache_depth-3-1:0] datamem_aw;

tmu2_qpram32 #(
	.depth(cache_depth-2)
) datamem (
	.sys_clk(sys_clk),

	.a1(retry ? tadra8_r[cache_depth-1:2] : tadra8[cache_depth-1:2]),
	.d1(datamem_d1),
	.a2(retry ? tadrb8_r[cache_depth-1:2] : tadrb8[cache_depth-1:2]),
	.d2(datamem_d2),
	.a3(retry ? tadrc8_r[cache_depth-1:2] : tadrc8[cache_depth-1:2]),
	.d3(datamem_d3),
	.a4(retry ? tadrc8_r[cache_depth-1:2] : tadrc8[cache_depth-1:2]),
	.d4(datamem_d4),

	.we(datamem_we),
	.aw(datamem_aw),
	.dw(fml_di)
);
assign tcolora = tadra8_r[1] ? datamem_d1[15:0] : datamem_d1[31:16];
assign tcolorb = tadrb8_r[1] ? datamem_d2[15:0] : datamem_d2[31:16];
assign tcolorc = tadrc8_r[1] ? datamem_d3[15:0] : datamem_d3[31:16];
assign tcolord = tadrd8_r[1] ? datamem_d4[15:0] : datamem_d4[31:16];

reg [cache_depth-2-1:0] datamem_lastreg;
reg datamem_retry;
always @(posedge sys_clk) begin
	datamem_lastreg <= retry ? tadra8_r[cache_depth-1:2] : tadra8[cache_depth-1:2];
	datamem_retry <= retry;
end

wire [1+fml_depth-cache_depth-1:0] tagmem_d1; /* < valid bit + tag */
wire [1+fml_depth-cache_depth-1:0] tagmem_d2;
wire [1+fml_depth-cache_depth-1:0] tagmem_d3;
wire [1+fml_depth-cache_depth-1:0] tagmem_d4;

reg tagmem_we;
wire [cache_depth-1-5:0] tagmem_aw;
wire [1+fml_depth-cache_depth-1:0] tagmem_dw;

tmu2_qpram #(
	.depth(cache_depth-5),
	.width(1+fml_depth-cache_depth)
) tagmem (
	.sys_clk(sys_clk),

	.a1(retry ? tadra8_r[cache_depth-1:5] : tadra8[cache_depth-1:5]),
	.d1(tagmem_d1),
	.a2(retry ? tadrb8_r[cache_depth-1:5] : tadrb8[cache_depth-1:5]),
	.d2(tagmem_d2),
	.a3(retry ? tadrc8_r[cache_depth-1:5] : tadrc8[cache_depth-1:5]),
	.d3(tagmem_d3),
	.a4(retry ? tadrd8_r[cache_depth-1:5] : tadrd8[cache_depth-1:5]),
	.d4(tagmem_d4),

	.we(tagmem_we),
	.aw(tagmem_aw),
	.dw(tagmem_dw)
);

/*always @(posedge sys_clk) begin
	if(tagmem_we)
		$display("write TAGMEM index:%x valid:%b tag:%x", tagmem_aw, tagmem_dw[1+fml_depth-cache_depth-1], tagmem_dw[fml_depth-cache_depth-1:0]);
end*/

/* HIT HANDLING */

reg access_requested;
always @(posedge sys_clk) begin
	if(sys_rst)
		access_requested <= 1'b0;
	else if(pipe_ack_o)
		access_requested <= pipe_stb_i;
end

/* The cycle after the tag memory has been written, data is invalid */
reg tagmem_we_r;
always @(posedge sys_clk) tagmem_we_r <= tagmem_we;

/* If some coordinates are integer, B, C or D can be ignored
 * and safely assumed to be cache hits.
 */
reg ignore_b;
reg ignore_c;
reg ignore_d;
always @(posedge sys_clk) begin
	if(pipe_ack_o) begin
		ignore_b <= x_frac == 6'd0;
		ignore_c <= y_frac == 6'd0;
		ignore_d <= (x_frac == 6'd0) && (y_frac == 6'd0);
	end
end

wire valid_a = tagmem_d1[1+fml_depth-cache_depth-1];
wire [fml_depth-1-cache_depth:0] tag_a = tagmem_d1[fml_depth-cache_depth-1:0];
wire valid_b = tagmem_d2[1+fml_depth-cache_depth-1];
wire [fml_depth-1-cache_depth:0] tag_b = tagmem_d2[fml_depth-cache_depth-1:0];
wire valid_c = tagmem_d3[1+fml_depth-cache_depth-1];
wire [fml_depth-1-cache_depth:0] tag_c = tagmem_d3[fml_depth-cache_depth-1:0];
wire valid_d = tagmem_d4[1+fml_depth-cache_depth-1];
wire [fml_depth-1-cache_depth:0] tag_d = tagmem_d4[fml_depth-cache_depth-1:0];

wire hit_a = ~tagmem_we_r & valid_a & (tag_a == tadra8_r[fml_depth-1:cache_depth]);
wire hit_b = ignore_b | (~tagmem_we_r & valid_b & (tag_b == tadrb8_r[fml_depth-1:cache_depth]));
wire hit_c = ignore_c | (~tagmem_we_r & valid_c & (tag_c == tadrc8_r[fml_depth-1:cache_depth]));
wire hit_d = ignore_d | (~tagmem_we_r & valid_d & (tag_d == tadrd8_r[fml_depth-1:cache_depth]));

assign pipe_stb_o = access_requested & hit_a & hit_b & hit_c & hit_d;
assign pipe_ack_o = (pipe_ack_i & pipe_stb_o) | ~access_requested;

assign retry = ~pipe_ack_o;

/*integer x, y;
reg [15:0] expected;
always @(posedge sys_clk) begin
	if(pipe_stb_o & pipe_ack_i) begin
		$display("%t a:%x d:%x [tag: %x %x] index:%x (datamem_lastreg:%x datamem_retry:%b)", $time, tadra8_r, tcolora, tag_a, tadra8_r[fml_depth-1:cache_depth], tadra8_r[cache_depth-1:5], datamem_lastreg, datamem_retry);
		x = (tadra8_r/2) % 512;
		y = (tadra8_r/2) / 512;
		$image_get(x, y, expected);
		if(tcolora != expected) begin
			$display("CACHE TEST FAILED! (%d, %d): expected %x, got %x", x, y, expected, tcolora);
			$finish;
		end
	end
end*/

/* FORWARDING */

always @(posedge sys_clk) begin
	if(pipe_ack_o & pipe_stb_i) begin
		dadr_f <= dadr;
		x_frac_f <= x_frac;
		y_frac_f <= y_frac;
	end
end

/* MISS HANDLING */

reg fetch_needed;
reg [fml_depth-1:0] fetch_adr;

always @(posedge sys_clk) begin
	if(sys_rst)
		fetch_needed <= 1'b0;
	else begin
		if(access_requested) begin
			fetch_needed <= ~(hit_a & hit_b & hit_c & hit_d);
			if(~hit_a)
				fetch_adr <= tadra8_r;
			else if(~hit_b)
				fetch_adr <= tadrb8_r;
			else if(~hit_c)
				fetch_adr <= tadrc8_r;
			else if(~hit_d)
				fetch_adr <= tadrd8_r;
		end
	end
end

wire flush_done;
reg flush_mode;
reg [cache_depth-1-5:0] flush_counter;
always @(posedge sys_clk) begin
	if(flush_mode)
		flush_counter <= flush_counter + 1'd1;
	else
		flush_counter <= {cache_depth-5{1'b0}};
end
assign flush_done = &flush_counter;

reg write_valid;
assign tagmem_aw = flush_mode ? flush_counter : fetch_adr[cache_depth-1:5];
assign tagmem_dw = {write_valid, fetch_adr[fml_depth-1:cache_depth]};

reg burst_count;
reg [1:0] burst_counter;
always @(posedge sys_clk) begin
	if(burst_count)
		burst_counter <= burst_counter + 2'd1;
	else
		burst_counter <= 2'd0;
end
assign datamem_aw = {fetch_adr[cache_depth-1:5], burst_counter};

assign fml_adr = {fetch_adr[fml_depth-1:5], 5'd0};

/* FSM controller */

reg [2:0] state;
reg [2:0] next_state;

parameter IDLE		= 3'd0;
parameter DATA1		= 3'd1;
parameter DATA2		= 3'd2;
parameter DATA3		= 3'd3;
parameter DATA4		= 3'd4;
parameter WAIT		= 3'd5;
parameter WAIT2		= 3'd6;
parameter FLUSH		= 3'd7;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= IDLE;
	else
		state <= next_state;
end

reg fsm_busy;

always @(*) begin
	next_state = state;

	tagmem_we = 1'b0;
	write_valid = 1'b1;

	datamem_we = 1'b0;
	burst_count = 1'b0;

	flush_mode = 1'b0;

	fml_stb = 1'b0;

	fsm_busy = 1'b1;

	case(state)
		IDLE: begin
			fsm_busy = 1'b0;
			if(fetch_needed)
				next_state = DATA1;
			if(flush)
				next_state = FLUSH;
		end
		DATA1: begin
			fml_stb = 1'b1;
			datamem_we = 1'b1;
			if(fml_ack) begin
				burst_count = 1'b1;
				next_state = DATA2;
			end
		end
		DATA2: begin
			datamem_we = 1'b1;
			burst_count = 1'b1;
			next_state = DATA3;
		end
		DATA3: begin
			datamem_we = 1'b1;
			burst_count = 1'b1;
			next_state = DATA4;
		end
		DATA4: begin
			datamem_we = 1'b1;
			tagmem_we = 1'b1; /* write tag last as it may unlock the pipeline */
			next_state = WAIT;
		end
		WAIT: next_state = WAIT2; /* wait for fetch_needed to reflect the updated tag */
		WAIT2: next_state = IDLE;
		FLUSH: begin
			tagmem_we = 1'b1;
			write_valid = 1'b0;
			flush_mode = 1'b1;
			if(flush_done)
				next_state = IDLE;
		end
	endcase
end

assign busy = fsm_busy | access_requested;

endmodule
