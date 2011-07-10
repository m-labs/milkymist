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

module fmlbrg #(
	parameter fml_depth = 26,
	parameter cache_depth = 14, /* 16kB cache */
	parameter invalidate_bit = fml_depth
) (
	input sys_clk,
	input sys_rst,
	
	input [31:0] wb_adr_i,
	input [2:0] wb_cti_i,
	input [31:0] wb_dat_i,
	output [31:0] wb_dat_o,
	input [3:0] wb_sel_i,
	input wb_cyc_i,
	input wb_stb_i,
	input wb_we_i,
	output reg wb_ack_o,
	
	output reg [fml_depth-1:0] fml_adr,
	output reg fml_stb,
	output reg fml_we,
	input fml_ack,
	output [7:0] fml_sel,
	output [63:0] fml_do,
	input [63:0] fml_di,

	/* Direct Cache Bus */
	input dcb_stb,
	input [fml_depth-1:0] dcb_adr,
	output [63:0] dcb_dat,
	output dcb_hit
);

/*
 * Line length is the burst length, that is 4*64 bits, or 32 bytes
 * Address split up :
 *
 * |             TAG            |         INDEX          |   OFFSET   |
 * |fml_depth-1      cache_depth|cache_depth-1          5|4          0|
 *
 */

wire [4:0] offset = wb_adr_i[4:0];
wire [cache_depth-1-5:0] index = wb_adr_i[cache_depth-1:5];
wire [fml_depth-cache_depth-1:0] tag = wb_adr_i[fml_depth-1:cache_depth];

wire [4:0] dcb_offset = dcb_adr[4:0];
wire [cache_depth-1-5:0] dcb_index = dcb_adr[cache_depth-1:5];
wire [fml_depth-cache_depth-1:0] dcb_tag = dcb_adr[fml_depth-1:cache_depth];

wire coincidence = index == dcb_index;

/*
 * TAG MEMORY
 *
 * Addressed by index (length cache_depth-5)
 * Contains valid bit + dirty bit + tag
 */

wire [cache_depth-1-5:0] tagmem_a;
reg tagmem_we;
wire [fml_depth-cache_depth-1+2:0] tagmem_di;
wire [fml_depth-cache_depth-1+2:0] tagmem_do;

wire [cache_depth-1-5:0] tagmem_a2;
wire [fml_depth-cache_depth-1+2:0] tagmem_do2;

fmlbrg_tagmem #(
	.depth(cache_depth-5),
	.width(fml_depth-cache_depth+2)
) tagmem (
	.sys_clk(sys_clk),

	.a(tagmem_a),
	.we(tagmem_we),
	.di(tagmem_di),
	.do(tagmem_do),

	.a2(tagmem_a2),
	.do2(tagmem_do2)
);

assign tagmem_a = index;

assign tagmem_a2 = dcb_index;

reg di_valid;
reg di_dirty;
assign tagmem_di = {di_valid, di_dirty, tag};

wire do_valid;
wire do_dirty;
wire [fml_depth-cache_depth-1:0] do_tag;
wire cache_hit;

wire do2_valid;
wire [fml_depth-cache_depth-1:0] do2_tag;

assign do_valid = tagmem_do[fml_depth-cache_depth-1+2];
assign do_dirty = tagmem_do[fml_depth-cache_depth-1+1];
assign do_tag = tagmem_do[fml_depth-cache_depth-1:0];

assign do2_valid = tagmem_do2[fml_depth-cache_depth-1+2];
assign do2_tag = tagmem_do2[fml_depth-cache_depth-1:0];

always @(posedge sys_clk)
	fml_adr <= {do_tag, index, 5'd0};

/*
 * DATA MEMORY
 *
 * Addressed by index+offset in 64-bit words (length cache_depth-3)
 * 64-bit memory with 8-bit write granularity
 */

wire [cache_depth-3-1:0] datamem_a;
reg [7:0] datamem_we;
wire [63:0] datamem_di;
wire [63:0] datamem_do;

wire [cache_depth-3-1:0] datamem_a2;
wire [63:0] datamem_do2;

fmlbrg_datamem #(
	.depth(cache_depth-3)
) datamem (
	.sys_clk(sys_clk),
	
	.a(datamem_a),
	.we(datamem_we),
	.di(datamem_di),
	.do(datamem_do),

	.a2(datamem_a2),
	.do2(datamem_do2)
);

reg [1:0] bcounter;
reg [1:0] bcounter_next;
always @(posedge sys_clk) begin
	if(sys_rst)
		bcounter <= 2'd0;
	else
		bcounter <= bcounter_next;
end

reg [1:0] bcounter_sel;

localparam BCOUNTER_RESET	= 2'd0;
localparam BCOUNTER_KEEP	= 2'd1;
localparam BCOUNTER_LOAD	= 2'd2;
localparam BCOUNTER_INC		= 2'd3;

always @(*) begin
	case(bcounter_sel)
		BCOUNTER_RESET: bcounter_next <= 2'd0;
		BCOUNTER_KEEP: bcounter_next <= bcounter;
		BCOUNTER_LOAD: bcounter_next <= offset[4:3];
		BCOUNTER_INC: bcounter_next <= bcounter + 2'd1;
		default: bcounter_next <= 2'bxx;
	endcase
end

assign datamem_a = {index, bcounter_next};

assign datamem_a2 = {dcb_index, dcb_offset[4:3]};

reg wordsel;
reg next_wordsel;
always @(posedge sys_clk)
	wordsel <= next_wordsel;

reg datamem_we_wb;
reg datamem_we_fml;

always @(*) begin
	if(datamem_we_fml)
		datamem_we = 8'hff;
	else if(datamem_we_wb) begin
		if(wordsel)
			datamem_we = {4'h0, wb_sel_i};
		else
			datamem_we = {wb_sel_i, 4'h0};
	end else
		datamem_we = 8'h00;
end

assign datamem_di = datamem_we_wb ? {wb_dat_i, wb_dat_i} : fml_di;

assign wb_dat_o = wordsel ? datamem_do[31:0] : datamem_do[63:32];
assign fml_do = datamem_do;
assign fml_sel = 8'hff;
assign dcb_dat = datamem_do2;

/* FSM */

reg [fml_depth-cache_depth-1:0] tag_r;
always @(posedge sys_clk)
	tag_r = tag;
assign cache_hit = do_valid & (do_tag == tag_r);

reg [3:0] state;
reg [3:0] next_state;

parameter IDLE			= 4'd0;
parameter TEST_HIT		= 4'd1;

parameter WB_BURST		= 4'd2;

parameter EVICT			= 4'd3;
parameter EVICT2		= 4'd4;
parameter EVICT3		= 4'd5;
parameter EVICT4		= 4'd6;

parameter REFILL		= 4'd7;
parameter REFILL_WAIT		= 4'd8;
parameter REFILL1		= 4'd9;
parameter REFILL2		= 4'd10;
parameter REFILL3		= 4'd11;
parameter REFILL4		= 4'd12;

parameter TEST_INVALIDATE	= 4'd13;
parameter INVALIDATE		= 4'd14;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= IDLE;
	else begin
		//$display("state: %d -> %d", state, next_state);
		state <= next_state;
	end
end

always @(*) begin
	tagmem_we = 1'b0;
	di_valid = 1'b0;
	di_dirty = 1'b0;
	
	bcounter_sel = BCOUNTER_KEEP;
	next_wordsel = 1'bx;
	
	datamem_we_wb = 1'b0;
	datamem_we_fml = 1'b0;
	
	wb_ack_o = 1'b0;
	
	fml_stb = 1'b0;
	fml_we = 1'b0;
	
	next_state = state;
	
	case(state)
		IDLE: begin
			bcounter_sel = BCOUNTER_LOAD;
			next_wordsel = wb_adr_i[2];
			if(wb_cyc_i & wb_stb_i) begin
				if(wb_adr_i[invalidate_bit])
					next_state = TEST_INVALIDATE;
				else
					next_state = TEST_HIT;
			end
		end
		TEST_HIT: begin
			next_wordsel = ~wordsel;
			if(cache_hit) begin
				wb_ack_o = 1'b1;
				if(wb_we_i) begin
					di_valid = 1'b1;
					di_dirty = 1'b1;
					tagmem_we = 1'b1;
					datamem_we_wb = 1'b1;
				end
				if(wb_cti_i == 3'b010)
					next_state = WB_BURST;
				else
					next_state = IDLE;
			end else begin
				if(do_dirty)
					next_state = EVICT;
				else
					next_state = REFILL;
			end
		end
		
		WB_BURST: begin
			next_wordsel = ~wordsel;
			if(wordsel ^ wb_we_i)
				bcounter_sel = BCOUNTER_INC;
			if(wb_we_i)
				datamem_we_wb = 1'b1;
			wb_ack_o = 1'b1;
			if(wb_cti_i != 3'b010)
				next_state = IDLE;
		end
		
		EVICT: begin
			fml_stb = 1'b1;
			fml_we = 1'b1;
			if(fml_ack) begin
				bcounter_sel = BCOUNTER_INC;
				next_state = EVICT2;
			end else
				bcounter_sel = BCOUNTER_RESET;
		end
		EVICT2: begin
			bcounter_sel = BCOUNTER_INC;
			next_state = EVICT3;
		end
		EVICT3: begin
			bcounter_sel = BCOUNTER_INC;
			next_state = EVICT4;
		end
		EVICT4: begin
			bcounter_sel = BCOUNTER_INC;
			if(wb_adr_i[invalidate_bit])
				next_state = INVALIDATE;
			else
				next_state = REFILL;
		end
		
		REFILL: begin
			/* Write the tag first. This will also set the FML address. */
			di_valid = 1'b1;
			if(wb_we_i)
				di_dirty = 1'b1;
			else
				di_dirty = 1'b0;
			if(~(dcb_stb & coincidence)) begin
				tagmem_we = 1'b1;
				next_state = REFILL_WAIT;
			end
		end
		REFILL_WAIT: next_state = REFILL1; /* one cycle latency for the FML address */
		REFILL1: begin
			bcounter_sel = BCOUNTER_RESET;
			fml_stb = 1'b1;
			datamem_we_fml = 1'b1;
			if(fml_ack)
				next_state = REFILL2;
		end
		REFILL2: begin
			datamem_we_fml = 1'b1;
			bcounter_sel = BCOUNTER_INC;
			next_state = REFILL3;
		end
		REFILL3: begin
			datamem_we_fml = 1'b1;
			bcounter_sel = BCOUNTER_INC;
			next_state = REFILL4;
		end
		REFILL4: begin
			datamem_we_fml = 1'b1;
			bcounter_sel = BCOUNTER_INC;
			next_state = IDLE;
		end
		
		TEST_INVALIDATE: begin
			if(do_dirty)
				next_state = EVICT;
			else
				next_state = INVALIDATE;
		end
		INVALIDATE: begin
			di_valid = 1'b0;
			di_dirty = 1'b0;
			tagmem_we = 1'b1;
			wb_ack_o = 1'b1;
			next_state = IDLE;
		end
	endcase
end

/* Do not hit on a line being refilled */
reg dcb_can_hit;

always @(posedge sys_clk) begin
	dcb_can_hit <= 1'b0;
	if(dcb_stb) begin
		if((state != REFILL_WAIT)
		|| (state != REFILL2)
		|| (state != REFILL3)
		|| (state != REFILL4))
			dcb_can_hit <= 1'b1;
		if(~coincidence)
			dcb_can_hit <= 1'b1;
	end
end

reg [fml_depth-cache_depth-1:0] dcb_tag_r;
always @(posedge sys_clk)
	dcb_tag_r = dcb_tag;

assign dcb_hit = dcb_can_hit & do2_valid & (do2_tag == dcb_tag_r);

endmodule
