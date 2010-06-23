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
	output reg busy,

	input pipe_stb_i,
	output reg pipe_ack_o,
	input [fml_depth-1-1:0] dadr, /* in 16-bit words */
	input [fml_depth-1-1:0] tadra,
	input [fml_depth-1-1:0] tadrb,
	input [fml_depth-1-1:0] tadrc,
	input [fml_depth-1-1:0] tadrd,
	input [5:0] x_frac,
	input [5:0] y_frac,

	output reg pipe_stb_o,
	input pipe_ack_i,
	output [fml_depth-1-1:0] dadr_f, /* in 16-bit words */
	output [15:0] tcolora,
	output [15:0] tcolorb,
	output [15:0] tcolorc,
	output [15:0] tcolord,
	output [5:0] x_frac_f,
	output [5:0] y_frac_f
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

/* MEMORIES */
wire [fml_depth-1:0] indexa;
wire [fml_depth-1:0] indexb;
wire [fml_depth-1:0] indexc;
wire [fml_depth-1:0] indexd;

reg ram_ce;

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
	.ce(ram_ce),
	
	.a1(indexa[cache_depth-1:2]),
	.d1(datamem_d1),
	.a2(indexb[cache_depth-1:2]),
	.d2(datamem_d2),
	.a3(indexc[cache_depth-1:2]),
	.d3(datamem_d3),
	.a4(indexd[cache_depth-1:2]),
	.d4(datamem_d4),

	.we(datamem_we),
	.aw(datamem_aw),
	.dw(fml_di)
);

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
	.ce(ram_ce),

	.a1(indexa[cache_depth-1:5]),
	.d1(tagmem_d1),
	.a2(indexb[cache_depth-1:5]),
	.d2(tagmem_d2),
	.a3(indexc[cache_depth-1:5]),
	.d3(tagmem_d3),
	.a4(indexd[cache_depth-1:5]),
	.d4(tagmem_d4),

	.we(tagmem_we),
	.aw(tagmem_aw),
	.dw(tagmem_dw)
);

/* REQUEST TRACKER */
reg invalidate_req;
wire rqvalid_0 = pipe_stb_i & ~invalidate_req;
wire [fml_depth-1-1:0] dadr_0 = dadr;
wire [5:0] x_frac_0 = x_frac;
wire [5:0] y_frac_0 = y_frac;
wire [fml_depth-1:0] tadra8_0 = {tadra, 1'b0};
wire [fml_depth-1:0] tadrb8_0 = {tadrb, 1'b0};
wire [fml_depth-1:0] tadrc8_0 = {tadrc, 1'b0};
wire [fml_depth-1:0] tadrd8_0 = {tadrd, 1'b0};

reg rqvalid_1;
reg [fml_depth-1-1:0] dadr_1;
reg [5:0] x_frac_1;
reg [5:0] y_frac_1;
reg [fml_depth-1:0] tadra8_1;
reg [fml_depth-1:0] tadrb8_1;
reg [fml_depth-1:0] tadrc8_1;
reg [fml_depth-1:0] tadrd8_1;

reg rqvalid_2;
reg [fml_depth-1-1:0] dadr_2;
reg [5:0] x_frac_2;
reg [5:0] y_frac_2;
reg ignore_b_2;
reg ignore_c_2;
reg ignore_d_2;
reg [fml_depth-1:0] tadra8_2;
reg [fml_depth-1:0] tadrb8_2;
reg [fml_depth-1:0] tadrc8_2;
reg [fml_depth-1:0] tadrd8_2;

wire rqt_ce;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		rqvalid_1 <= 1'b0;
		rqvalid_2 <= 1'b0;
	end else begin
		if(rqt_ce) begin
			rqvalid_1 <= rqvalid_0;
			dadr_1 <= dadr_0;
			x_frac_1 <= x_frac_0;
			y_frac_1 <= y_frac_0;
			tadra8_1 <= tadra8_0;
			tadrb8_1 <= tadrb8_0;
			tadrc8_1 <= tadrc8_0;
			tadrd8_1 <= tadrd8_0;

			rqvalid_2 <= rqvalid_1;
			dadr_2 <= dadr_1;
			x_frac_2 <= x_frac_1;
			y_frac_2 <= y_frac_1;
			ignore_b_2 <= x_frac_1 == 6'd0;
			ignore_c_2 <= y_frac_1 == 6'd0;
			ignore_d_2 <= (x_frac_1 == 6'd0) | (y_frac_1 == 6'd0);
			tadra8_2 <= tadra8_1;
			tadrb8_2 <= tadrb8_1;
			tadrc8_2 <= tadrc8_1;
			tadrd8_2 <= tadrd8_1;
		end
	end
end

/* OUTPUT DATA GENERATOR */
assign dadr_f = dadr_2;
assign x_frac_f = x_frac_2;
assign y_frac_f = y_frac_2;

assign tcolora = tadra8_2[1] ? datamem_d1[15:0] : datamem_d1[31:16];
assign tcolorb = tadrb8_2[1] ? datamem_d2[15:0] : datamem_d2[31:16];
assign tcolorc = tadrc8_2[1] ? datamem_d3[15:0] : datamem_d3[31:16];
assign tcolord = tadrd8_2[1] ? datamem_d4[15:0] : datamem_d4[31:16];

/* INDEX GENERATOR */
reg index_sel;

assign indexa = index_sel ? tadra8_2 : tadra8_0;
assign indexb = index_sel ? tadrb8_2 : tadrb8_0;
assign indexc = index_sel ? tadrc8_2 : tadrc8_0;
assign indexd = index_sel ? tadrd8_2 : tadrd8_0;

/* HIT DETECTION */
wire valid_a = tagmem_d1[1+fml_depth-cache_depth-1];
wire [fml_depth-1-cache_depth:0] tag_a = tagmem_d1[fml_depth-cache_depth-1:0];
wire valid_b = tagmem_d2[1+fml_depth-cache_depth-1];
wire [fml_depth-1-cache_depth:0] tag_b = tagmem_d2[fml_depth-cache_depth-1:0];
wire valid_c = tagmem_d3[1+fml_depth-cache_depth-1];
wire [fml_depth-1-cache_depth:0] tag_c = tagmem_d3[fml_depth-cache_depth-1:0];
wire valid_d = tagmem_d4[1+fml_depth-cache_depth-1];
wire [fml_depth-1-cache_depth:0] tag_d = tagmem_d4[fml_depth-cache_depth-1:0];

wire hit_a = valid_a & (tag_a == tadra8_2[fml_depth-1:cache_depth]);
wire hit_b = ignore_b_2 | (valid_b & (tag_b == tadrb8_2[fml_depth-1:cache_depth]));
wire hit_c = ignore_c_2 | (valid_c & (tag_c == tadrc8_2[fml_depth-1:cache_depth]));
wire hit_d = ignore_d_2 | (valid_d & (tag_d == tadrd8_2[fml_depth-1:cache_depth]));

`define VERIFY_TEXCACHE
`ifdef VERIFY_TEXCACHE
integer x, y;
reg [15:0] expected;
always @(posedge sys_clk) begin
	if(pipe_stb_o & pipe_ack_i) begin
		x = (tadra8_2/2) % 512;
		y = (tadra8_2/2) / 512;
		$image_get(0, x, y, expected);
		if(tcolora !== expected) begin
			$display("CACHE TEST FAILED [A]! (%d, %d): expected %x, got %x", x, y, expected, tcolora);
			$finish;
		end
		if(~ignore_b_2) begin
			x = (tadrb8_2/2) % 512;
			y = (tadrb8_2/2) / 512;
			$image_get(0, x, y, expected);
			if(tcolorb !== expected) begin
				$display("CACHE TEST FAILED [B]! (%d, %d): expected %x, got %x", x, y, expected, tcolorb);
				$finish;
			end
		end
		if(~ignore_c_2) begin
			x = (tadrc8_2/2) % 512;
			y = (tadrc8_2/2) / 512;
			$image_get(0, x, y, expected);
			if(tcolorc !== expected) begin
				$display("CACHE TEST FAILED [C]! (%d, %d): expected %x, got %x", x, y, expected, tcolorc);
				$finish;
			end
		end
		if(~ignore_d_2) begin
			x = (tadrd8_2/2) % 512;
			y = (tadrd8_2/2) / 512;
			$image_get(0, x, y, expected);
			if(tcolord !== expected) begin
				$display("CACHE TEST FAILED [D]! (%d, %d): expected %x, got %x", x, y, expected, tcolord);
				$finish;
			end
		end
	end
end
`endif

/* FLUSH & MISS HANDLING */
reg [fml_depth-1:0] fetch_adr;
reg fetch_adr_ce;

always @(posedge sys_clk) begin
	if(fetch_adr_ce) begin
		if(~hit_a)
			fetch_adr <= tadra8_2;
		else if(~hit_b)
			fetch_adr <= tadrb8_2;
		else if(~hit_c)
			fetch_adr <= tadrc8_2;
		else if(~hit_d)
			fetch_adr <= tadrd8_2;
	end
end

reg flush_mode;
wire flush_done;
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

reg [1:0] burst_counter;
assign datamem_aw = {fetch_adr[cache_depth-1:5], burst_counter};

assign fml_adr = {fetch_adr[fml_depth-1:5], 5'd0};

/* FSM-BASED CONTROLLER */
reg [3:0] state;
reg [3:0] next_state;

parameter IDLE		= 4'd0;
parameter DATA1		= 4'd1;
parameter DATA2		= 4'd2;
parameter DATA3		= 4'd3;
parameter DATA4		= 4'd4;
parameter HANDLED_MISS0	= 4'd5;
parameter HANDLED_MISS1	= 4'd6;
parameter HANDLED_MISS	= 4'd7;
parameter FLUSHPIPE1	= 4'd8;
parameter FLUSHPIPE2	= 4'd9;
parameter FLUSH		= 4'd10;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= IDLE;
	else
		state <= next_state;
end

assign rqt_ce = pipe_ack_o | invalidate_req;

always @(*) begin
	next_state = state;

	tagmem_we = 1'b0;
	write_valid = 1'b1;

	datamem_we = 1'b0;
	burst_counter = 2'bx;

	flush_mode = 1'b0;

	fml_stb = 1'b0;

	busy = 1'b1;
	pipe_stb_o = 1'b0;
	pipe_ack_o = 1'b0;

	invalidate_req = 1'b0;
	fetch_adr_ce = 1'b0;

	index_sel = 1'b0;

	ram_ce = 1'b1;

	case(state)
		IDLE: begin
			busy = rqvalid_1|rqvalid_2;
			pipe_stb_o = rqvalid_2 & hit_a & hit_b & hit_c & hit_d;
			pipe_ack_o = ~rqvalid_2 | ((hit_a & hit_b & hit_c & hit_d) & pipe_ack_i);
			ram_ce = ~rqvalid_2 | ((hit_a & hit_b & hit_c & hit_d) & pipe_ack_i);
			fetch_adr_ce = 1'b1;
			if(rqvalid_2 & (~hit_a | ~hit_b | ~hit_c | ~hit_d)) begin
				next_state = DATA1;
			end else if(flush)
				next_state = FLUSH;
		end
		DATA1: begin
			index_sel = 1'b1;
			fml_stb = 1'b1;
			burst_counter = 2'd0;
			datamem_we = 1'b1;
			tagmem_we = 1'b1;
			if(fml_ack)
				next_state = DATA2;
		end
		DATA2: begin
			index_sel = 1'b1;
			burst_counter = 2'd1;
			datamem_we = 1'b1;
			next_state = DATA3;
		end
		DATA3: begin
			index_sel = 1'b1;
			burst_counter = 2'd2;
			datamem_we = 1'b1;
			next_state = DATA4;
		end
		DATA4: begin
			index_sel = 1'b1;
			burst_counter = 2'd3;
			datamem_we = 1'b1;
			fetch_adr_ce = 1'b1;
			if(~hit_a | ~hit_b | ~hit_c | ~hit_d)
				next_state = DATA1;
			else
				next_state = HANDLED_MISS0;
		end
		/* wait for the written data to make its way through the pipelined RAM */
		HANDLED_MISS0: begin
			index_sel = 1'b1;
			next_state = HANDLED_MISS1;
		end
		HANDLED_MISS1: begin
			index_sel = 1'b1;
			next_state = HANDLED_MISS;
		end
		HANDLED_MISS: begin
			index_sel = 1'b1;
			pipe_stb_o = 1'b1;
			if(pipe_ack_i) begin
				invalidate_req = 1'b1;
				next_state = FLUSHPIPE1;
			end
		end
		FLUSHPIPE1: begin
			index_sel = 1'b1;
			next_state = FLUSHPIPE2;
		end
		FLUSHPIPE2: begin
			index_sel = 1'b1;
			next_state = IDLE;
		end
		FLUSH: begin
			tagmem_we = 1'b1;
			write_valid = 1'b0;
			flush_mode = 1'b1;
			if(flush_done)
				next_state = IDLE;
		end
	endcase
end

endmodule
