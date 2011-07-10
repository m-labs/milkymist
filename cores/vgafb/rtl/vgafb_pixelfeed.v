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

module vgafb_pixelfeed #(
	parameter fml_depth = 26
) (
	input sys_clk,
	/* We must take into account both resets :
	 * VGA reset should not interrupt a pending FML request
	 * but system reset should.
	 */
	input sys_rst,
	input vga_rst,
	
	input [17:0] nbursts,
	input [fml_depth-1:0] baseaddress,
	output baseaddress_ack,
	
	output reg [fml_depth-1:0] fml_adr,
	output reg fml_stb,
	input fml_ack,
	input [63:0] fml_di,

	output reg dcb_stb,
	output [fml_depth-1:0] dcb_adr,
	input [63:0] dcb_dat,
	input dcb_hit,
	
	output pixel_valid,
	output [15:0] pixel,
	input pixel_ack
);

/* FIFO that stores the 64-bit bursts and slices it in 16-bit words */

reg fifo_source_cache;
reg fifo_stb;
wire can_burst;
wire fifo_valid;

vgafb_fifo64to16 fifo64to16(
	.sys_clk(sys_clk),
	.vga_rst(vga_rst),
	
	.stb(fifo_stb),
	.di(fifo_source_cache ? dcb_dat : fml_di),
	
	.can_burst(can_burst),
	.do_valid(fifo_valid),
	.do(pixel),
	.next(pixel_ack)
);

assign pixel_valid = fifo_valid;

/* BURST COUNTER */
reg sof;
wire counter_en;

reg [17:0] bcounter;

always @(posedge sys_clk) begin
	if(vga_rst) begin
		bcounter <= 18'd1;
		sof <= 1'b1;
	end else begin
		if(counter_en) begin
			if(bcounter == nbursts) begin
				bcounter <= 18'd1;
				sof <= 1'b1;
			end else begin
				bcounter <= bcounter + 18'd1;
				sof <= 1'b0;
			end
		end
	end
end

/* FML ADDRESS GENERATOR */
wire next_address;

assign baseaddress_ack = sof & next_address;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		fml_adr <= {fml_depth{1'b0}};
	end else begin
		if(next_address) begin
			if(sof)
				fml_adr <= baseaddress;
			else
				fml_adr <= fml_adr + {{fml_depth-6{1'b0}}, 6'd32};
		end
	end
end

/* DCB ADDRESS GENERATOR */
reg [1:0] dcb_index;

always @(posedge sys_clk) begin
	if(dcb_stb)
		dcb_index <= dcb_index + 2'd1;
	else
		dcb_index <= 2'd0;
end

assign dcb_adr = {fml_adr[fml_depth-1:5], dcb_index, 3'b000};

/* CONTROLLER */
reg [3:0] state;
reg [3:0] next_state;

parameter IDLE		= 4'd0;
parameter TRYCACHE	= 4'd1;
parameter CACHE1	= 4'd2;
parameter CACHE2	= 4'd3;
parameter CACHE3	= 4'd4;
parameter CACHE4	= 4'd5;
parameter FML1		= 4'd6;
parameter FML2		= 4'd7;
parameter FML3		= 4'd8;
parameter FML4		= 4'd9;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= IDLE;
	else
		state <= next_state;
end

/*
 * Do not put spurious data into the FIFO if the VGA reset
 * is asserted and released during the FML access. Getting
 * the FIFO out of sync would result in distorted pictures
 * we really want to avoid.
 */

reg ignore;
reg ignore_clear;

always @(posedge sys_clk) begin
	if(vga_rst)
		ignore <= 1'b1;
	else if(ignore_clear)
		ignore <= 1'b0;
end

reg next_burst;

assign counter_en = next_burst;
assign next_address = next_burst;

always @(*) begin
	next_state = state;
	
	fifo_stb = 1'b0;
	next_burst = 1'b0;
	
	fml_stb = 1'b0;
	ignore_clear = 1'b0;

	dcb_stb = 1'b0;
	fifo_source_cache = 1'b0;
	
	case(state)
		IDLE: begin
			if(can_burst & ~vga_rst) begin
				/* We're in need of pixels ! */
				next_burst = 1'b1;
				ignore_clear = 1'b1;
				next_state = TRYCACHE;
			end
		end
		/* Try to fetch from L2 first */
		TRYCACHE: begin
			dcb_stb = 1'b1;
			next_state = CACHE1;
		end
		CACHE1: begin
			fifo_source_cache = 1'b1;
			if(dcb_hit) begin
				dcb_stb = 1'b1;
				if(~ignore) fifo_stb = 1'b1;
				next_state = CACHE2;
			end else
				next_state = FML1; /* Not in L2 cache, fetch from DRAM */
		end
		/* No need to check for cache hits anymore:
		 * - we fetched from the beginning of a line
		 * - we fetch exactly a line
		 * - we do not release dcb_stb so the cache controller locks the line
		 * Therefore, next 3 fetchs always are cache hits.
		 */
		CACHE2: begin
			dcb_stb = 1'b1;
			fifo_source_cache = 1'b1;
			if(~ignore) fifo_stb = 1'b1;
			next_state = CACHE3;
		end
		CACHE3: begin
			dcb_stb = 1'b1;
			fifo_source_cache = 1'b1;
			if(~ignore) fifo_stb = 1'b1;
			next_state = CACHE4;
		end
		CACHE4: begin
			fifo_source_cache = 1'b1;
			if(~ignore) fifo_stb = 1'b1;
			next_state = IDLE;
		end
		FML1: begin
			fml_stb = 1'b1;
			if(fml_ack) begin
				if(~ignore) fifo_stb = 1'b1;
				next_state = FML2;
 			end
		end
		FML2: begin
			if(~ignore) fifo_stb = 1'b1;
			next_state = FML3;
		end
		FML3: begin
			if(~ignore) fifo_stb = 1'b1;
			next_state = FML4;
		end
		FML4: begin
			if(~ignore) fifo_stb = 1'b1;
			next_state = IDLE;
		end
	endcase
end

endmodule
