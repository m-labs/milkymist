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

module tmu_pixin #(
	parameter fml_depth = 26,
	parameter cache_depth = 12
) (
	input sys_clk,
	input sys_rst,
	
	output reg [fml_depth-1:0] fml_adr,
	output reg fml_stb,
	input fml_ack,
	input [63:0] fml_di,
	
	input flush,
	output reg busy,
	
	input pipe_stb_i,
	output reg pipe_ack_o,
	input [fml_depth-1-1:0] src_addr, /* in 16-bit words */
	input [fml_depth-1-1:0] dst_addr, /* in 16-bit words, pass-through */
	
	output reg pipe_stb_o,
	input pipe_ack_i,
	output reg [15:0] src_pixel,
	output reg [fml_depth-1-1:0] dst_addr1, /* in 16-bit words */
	
	output reg inc_misses
);

/* Work on 8-bit addresses to reduce the probability of
 * spending hours fixing typos in indices.
 * The synthesizer should optimize the trailing 0 away.
 */
wire [fml_depth-1:0] src_addr8 = {src_addr, 1'b0};

reg memorize_src_address;
reg [fml_depth-1:0] src_addr8_r;
always @(posedge sys_clk) begin
	if(memorize_src_address)
		src_addr8_r = src_addr8;
end

/*
 * Line length is the burst length, that is 4*64 bits, or 32 bytes
 * Address split up :
 *
 * |             TAG            |         INDEX          |   OFFSET   |
 * |fml_depth-1      cache_depth|cache_depth-1          5|4          0|
 *
 */

wire [4:0] offset = src_addr8[4:0];
wire [cache_depth-1-5:0] index = src_addr8[cache_depth-1:5];
wire [fml_depth-cache_depth-1:0] tag = src_addr8[fml_depth-1:cache_depth];

wire [4:0] offset_r = src_addr8_r[4:0];
wire [cache_depth-1-5:0] index_r = src_addr8_r[cache_depth-1:5];
wire [fml_depth-cache_depth-1:0] tag_r = src_addr8_r[fml_depth-1:cache_depth];

/* When we access FML, it's always because of a cache miss, and
 * therefore using the memorized address. Connect the address lines
 * straight to the output of the register to improve timing.
 * And add another register since that was not enough.
 */
always @(posedge sys_clk)
	fml_adr <= {tag_r, index_r, 5'd0};

/* Use the memorized address as the index for the tag and data memories */
reg use_memorized;

/*
 * TAG MEMORY
 *
 * Addressed by index (length cache_depth-5)
 * Contains valid bit + tag
 */

wire [cache_depth-1-5:0] tagmem_a;
reg tagmem_we;
wire [fml_depth-cache_depth-1+1:0] tagmem_di;
reg [fml_depth-cache_depth-1+1:0] tagmem_do;

reg [fml_depth-cache_depth-1+1:0] tags[0:(1 << (cache_depth-5))-1];

always @(posedge sys_clk) begin
	if(tagmem_we)
		tags[tagmem_a] <= tagmem_di;
	tagmem_do <= tags[tagmem_a];
end

reg flushmode;
reg flush_a_reset;

reg [cache_depth-1-5:0] flush_a;
always @(posedge sys_clk) begin
	if(flush_a_reset)
		flush_a <= {cache_depth-5{1'b0}};
	else
		flush_a <= flush_a + {{cache_depth-5-1{1'b0}}, 1'b1};
end

wire flush_last = (flush_a == {cache_depth-5{1'b1}});

assign tagmem_a = flushmode ? flush_a : (use_memorized ? index_r : index);

wire di_valid;
/* we always write tags from addresses missing the cache,
 * therefore with the memorized address.
 */
assign tagmem_di = {di_valid, tag_r};

assign di_valid = ~flushmode;

wire do_valid;
wire [fml_depth-cache_depth-1:0] do_tag;
assign do_valid = tagmem_do[fml_depth-cache_depth-1+1];
assign do_tag = tagmem_do[fml_depth-cache_depth-1:0];

/*
 * DATA MEMORY
 *
 * Addressed by index+offset in 64-bit words (length cache_depth-3)
 */
wire [cache_depth-3-1:0] datamem_a;
reg datamem_we;
wire [63:0] datamem_di;
reg [63:0] datamem_do;

reg [63:0] data[0:(1 << (cache_depth-3))-1];

always @(posedge sys_clk) begin
	if(datamem_we)
		data[datamem_a] <= datamem_di;
	datamem_do <= data[datamem_a];
end

assign datamem_di = fml_di;
always @(*) begin
	case(offset_r[2:1])
		2'd0: src_pixel = datamem_do[63:48];
		2'd1: src_pixel = datamem_do[47:32];
		2'd2: src_pixel = datamem_do[31:16];
		2'd3: src_pixel = datamem_do[15:0];
	endcase
end

reg bcounter_reset;
reg [1:0] bcounter;
always @(posedge sys_clk) begin
	if(bcounter_reset)
		bcounter <= 2'd0;
	else
		bcounter <= bcounter + 2'd1;
end

reg datamem_aswitch;
assign datamem_a = {
	(use_memorized ? index_r : index),
	datamem_aswitch ? bcounter : (use_memorized ? offset_r[4:3] : offset[4:3])
	};

/* FSM */

wire cache_hit = do_valid & (do_tag == tag_r);

reg [3:0] state;
reg [3:0] next_state;

parameter IDLE			= 4'd0;
parameter RUNNING		= 4'd1;
parameter WAIT_DOWNSTREAM	= 4'd2;
parameter CACHEMISS		= 4'd3;
parameter BURST2		= 4'd4;
parameter BURST3		= 4'd5;
parameter BURST4		= 4'd6;
parameter READOFFSET		= 4'd7;
parameter FLUSH			= 4'd8;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= IDLE;
	else begin
		state <= next_state;
	end
end

always @(*) begin
	next_state = state;
	
	memorize_src_address = 1'b0;
	use_memorized = 1'b0;
	
	tagmem_we = 1'b0;
	datamem_we = 1'b0;
	flush_a_reset = 1'b0;
	flushmode = 1'b0;
	bcounter_reset = 1'b1;
	datamem_aswitch = 1'b0;
	
	busy = 1'b1;
	pipe_ack_o = 1'b0;
	pipe_stb_o = 1'b0;
	
	fml_stb = 1'b0;
	
	inc_misses = 1'b0;
	
	case(state)
		IDLE: begin
			memorize_src_address = 1'b1;
			busy = 1'b0;
			if(flush) begin
				flush_a_reset = 1'b1;
				next_state = FLUSH;
			end else begin
				pipe_ack_o = 1'b1;
				if(pipe_stb_i)
					next_state = RUNNING;
			end
		end
		RUNNING: begin
			if(cache_hit) begin
				pipe_stb_o = 1'b1;
				pipe_ack_o = 1'b1;
				memorize_src_address = 1'b1;
				
				if(~pipe_ack_i) begin
					pipe_ack_o = 1'b0;
					memorize_src_address = 1'b0;
					use_memorized = 1'b1;
					next_state = WAIT_DOWNSTREAM;
				end else if(pipe_stb_i)
					next_state = RUNNING;
				else
					next_state = IDLE;
			end else begin
				memorize_src_address = 1'b0;
				next_state = CACHEMISS;
			end
		end
		WAIT_DOWNSTREAM: begin
			pipe_stb_o = 1'b1;
			if(pipe_ack_i) begin
				memorize_src_address = 1'b1;
				use_memorized = 1'b0;

				pipe_ack_o = 1'b1;
				if(pipe_stb_i) begin
					next_state = RUNNING;
				end else
					next_state = IDLE;
			end else begin
				memorize_src_address = 1'b0;
				use_memorized = 1'b1;
			end
		end
		CACHEMISS: begin
			memorize_src_address = 1'b0;
			use_memorized = 1'b1;
			fml_stb = 1'b1;
			tagmem_we = 1'b1;
			datamem_aswitch = 1'b1;
			datamem_we = 1'b1;
			if(fml_ack) begin
				bcounter_reset = 1'b0;
				next_state = BURST2;
			end
		end
		BURST2: begin
			inc_misses = 1'b1;
			memorize_src_address = 1'b0;
			use_memorized = 1'b1;
			datamem_aswitch = 1'b1;
			datamem_we = 1'b1;
			bcounter_reset = 1'b0;
			next_state = BURST3;
		end
		BURST3: begin
			memorize_src_address = 1'b0;
			use_memorized = 1'b1;
			datamem_aswitch = 1'b1;
			datamem_we = 1'b1;
			bcounter_reset = 1'b0;
			next_state = BURST4;
		end
		BURST4: begin
			memorize_src_address = 1'b0;
			use_memorized = 1'b1;
			datamem_aswitch = 1'b1;
			datamem_we = 1'b1;
			
			next_state = READOFFSET;
		end
		READOFFSET: begin
			/* Before asserting the downstream data strobe,
			 * we need to read the Data Memory at the correct offset
			 * by deasserting datamem_aswitch.
			 */
			memorize_src_address = 1'b0;
			use_memorized = 1'b1;
			
			next_state = WAIT_DOWNSTREAM;
		end
		FLUSH: begin
			flushmode = 1'b1;
			tagmem_we = 1'b1;
			if(flush_last)
				next_state = IDLE;
		end
	endcase
end

/* Pass-through */

always @(posedge sys_clk) begin
	if(pipe_stb_i & pipe_ack_o)
		dst_addr1 = dst_addr;
end

endmodule
