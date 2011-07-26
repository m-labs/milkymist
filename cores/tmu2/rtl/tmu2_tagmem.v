/*
 * Milkymist SoC
 * Copyright (C) 2007, 2008, 2009, 2010, 2011 Sebastien Bourdeauducq
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

module tmu2_tagmem #(
	parameter cache_depth = 13,
	parameter fml_depth = 26
) (
	input sys_clk,
	input sys_rst,

	input flush,
	output reg busy,

	input pipe_stb_i,
	output reg pipe_ack_o,
	input [fml_depth-1-1:0] dadr,
	input [fml_depth-1:0] tadra,
	input [fml_depth-1:0] tadrb,
	input [fml_depth-1:0] tadrc,
	input [fml_depth-1:0] tadrd,
	input [5:0] x_frac,
	input [5:0] y_frac,
	
	output reg pipe_stb_o,
	input pipe_ack_i,
	output reg [fml_depth-1-1:0] dadr_f,
	output reg [fml_depth-1:0] tadra_f,
	output reg [fml_depth-1:0] tadrb_f,
	output reg [fml_depth-1:0] tadrc_f,
	output reg [fml_depth-1:0] tadrd_f,
	output reg [5:0] x_frac_f,
	output reg [5:0] y_frac_f,
	output miss_a,
	output miss_b,
	output miss_c,
	output miss_d
);

/* Extract cache indices. */
wire [cache_depth-1-5:0] ci_a = tadra[cache_depth-1:5];
wire [cache_depth-1-5:0] ci_b = tadrb[cache_depth-1:5];
wire [cache_depth-1-5:0] ci_c = tadrc[cache_depth-1:5];
wire [cache_depth-1-5:0] ci_d = tadrd[cache_depth-1:5];

/* Determine 'valid' channels, i.e. channels that will have
 * an influence on the result of the bilinear filter.
 * Channel a is always valid.
 */
wire valid_b = x_frac != 6'd0;
wire valid_c = y_frac != 6'd0;
wire valid_d = (x_frac != 6'd0) & (y_frac != 6'd0);

/* Group channels that have the same cache address.
 * In each group, elect a 'leader' channel.
 * The leader is chosen arbitrarily among the valid channels in the group.
 * The consequence of this is that it is sufficient and necessary
 * to take care of cache misses on the leader channels only.
 */
wire lead_a = ~(valid_b & (ci_a == ci_b)) & ~(valid_c & (ci_a == ci_c)) & ~(valid_d & (ci_a == ci_d));
wire lead_b = valid_b & ~(valid_c & (ci_b == ci_c)) & ~(valid_d & (ci_b == ci_d));
wire lead_c = valid_c & ~(valid_d & (ci_c == ci_d));
wire lead_d = valid_d;

/* Tag memory */
reg tag_re;
reg tag_we;
reg [cache_depth-5-1:0] tag_wa;
reg [1+fml_depth-cache_depth-1:0] tag_wd;

wire tag_rd_va;
wire [fml_depth-cache_depth-1:0] tag_rd_a;
tmu2_dpram #(
	.depth(cache_depth-5),
	.width(1+fml_depth-cache_depth)
) tag_a (
	.sys_clk(sys_clk),

	.ra(ci_a),
	.re(tag_re),
	.rd({tag_rd_va, tag_rd_a}),

	.wa(tag_wa),
	.we(tag_we),
	.wd(tag_wd)
);

wire tag_rd_vb;
wire [fml_depth-cache_depth-1:0] tag_rd_b;
tmu2_dpram #(
	.depth(cache_depth-5),
	.width(1+fml_depth-cache_depth)
) tag_b (
	.sys_clk(sys_clk),

	.ra(ci_b),
	.re(tag_re),
	.rd({tag_rd_vb, tag_rd_b}),

	.wa(tag_wa),
	.we(tag_we),
	.wd(tag_wd)
);

wire tag_rd_vc;
wire [fml_depth-cache_depth-1:0] tag_rd_c;
tmu2_dpram #(
	.depth(cache_depth-5),
	.width(1+fml_depth-cache_depth)
) tag_c (
	.sys_clk(sys_clk),

	.ra(ci_c),
	.re(tag_re),
	.rd({tag_rd_vc, tag_rd_c}),

	.wa(tag_wa),
	.we(tag_we),
	.wd(tag_wd)
);

wire tag_rd_vd;
wire [fml_depth-cache_depth-1:0] tag_rd_d;
tmu2_dpram #(
	.depth(cache_depth-5),
	.width(1+fml_depth-cache_depth)
) tag_d (
	.sys_clk(sys_clk),

	.ra(ci_d),
	.re(tag_re),
	.rd({tag_rd_vd, tag_rd_d}),

	.wa(tag_wa),
	.we(tag_we),
	.wd(tag_wd)
);

/* Miss detection */
reg req_valid;
reg [fml_depth-cache_depth-1:0] ct_a_r;
reg [fml_depth-cache_depth-1:0] ct_b_r;
reg [fml_depth-cache_depth-1:0] ct_c_r;
reg [fml_depth-cache_depth-1:0] ct_d_r;
reg [cache_depth-1-5:0] ci_a_r;
reg [cache_depth-1-5:0] ci_b_r;
reg [cache_depth-1-5:0] ci_c_r;
reg [cache_depth-1-5:0] ci_d_r;
reg lead_a_r;
reg lead_b_r;
reg lead_c_r;
reg lead_d_r;

always @(posedge sys_clk) begin
	if(sys_rst)
		req_valid <= 1'b0;
	else if(tag_re) begin
		req_valid <= pipe_stb_i;
		ct_a_r <= tadra[fml_depth-1:cache_depth];
		ct_b_r <= tadrb[fml_depth-1:cache_depth];
		ct_c_r <= tadrc[fml_depth-1:cache_depth];
		ct_d_r <= tadrd[fml_depth-1:cache_depth];
		ci_a_r <= ci_a;
		ci_b_r <= ci_b;
		ci_c_r <= ci_c;
		ci_d_r <= ci_d;
		lead_a_r <= lead_a;
		lead_b_r <= lead_b;
		lead_c_r <= lead_c;
		lead_d_r <= lead_d;
	end
end

assign miss_a = lead_a_r & (~tag_rd_va | (ct_a_r != tag_rd_a));
assign miss_b = lead_b_r & (~tag_rd_vb | (ct_b_r != tag_rd_b));
assign miss_c = lead_c_r & (~tag_rd_vc | (ct_c_r != tag_rd_c));
assign miss_d = lead_d_r & (~tag_rd_vd | (ct_d_r != tag_rd_d));

wire more_than_one_miss = (miss_a & miss_b) | (miss_a & miss_c) | (miss_a & miss_d)
	| (miss_b & miss_c) | (miss_b & miss_d)
	| (miss_c & miss_d);

/* Flush counter */
reg [cache_depth-5-1:0] flush_counter;
reg flush_counter_en;

always @(posedge sys_clk) begin
	if(flush_counter_en)
		flush_counter <= flush_counter + 1;
	else
		flush_counter <= 0;
end

wire flush_done = &flush_counter;

/* Tag rewrite */
reg [2:0] tag_sel;
always @(*) begin
	case(tag_sel)
		3'd0: begin
			tag_wa = ci_a_r;
			tag_wd = {1'b1, ct_a_r};
		end
		3'd1: begin
			tag_wa = ci_b_r;
			tag_wd = {1'b1, ct_b_r};
		end
		3'd2: begin
			tag_wa = ci_c_r;
			tag_wd = {1'b1, ct_c_r};
		end
		3'd3: begin
			tag_wa = ci_d_r;
			tag_wd = {1'b1, ct_d_r};
		end
		default: begin
			tag_wa = flush_counter;
			tag_wd = {1+fml_depth-cache_depth{1'b0}};
		end
	endcase
end

/* Miss mask */
reg [3:0] missmask;

reg missmask_init;
reg missmask_we;

always @(posedge sys_clk) begin
	if(missmask_init) begin
		case(tag_sel[1:0])
			2'd0: missmask <= 4'b1110;
			2'd1: missmask <= 4'b1101;
			2'd2: missmask <= 4'b1011;
			default: missmask <= 4'b0111;
		endcase
	end
	if(missmask_we) begin
		case(tag_sel[1:0])
			2'd0: missmask <= missmask & 4'b1110;
			2'd1: missmask <= missmask & 4'b1101;
			2'd2: missmask <= missmask & 4'b1011;
			default: missmask <= missmask & 4'b0111;
		endcase
	end
end

/* Control logic */
reg [1:0] state;
reg [1:0] next_state;

parameter RUNNING		= 2'd0;
parameter RESOLVE_MISS		= 2'd1;
parameter FLUSH			= 2'd2;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= RUNNING;
	else
		state <= next_state;
end

always @(*) begin
	next_state = state;
	
	pipe_ack_o = 1'b0;
	pipe_stb_o = 1'b0;
	busy = 1'b0;
	
	tag_re = 1'b0;
	tag_we = 1'b0;
	tag_sel = 3'd0;
	
	missmask_init = 1'b0;
	missmask_we = 1'b0;
	
	flush_counter_en = 1'b0;
	
	case(state)
		RUNNING: begin
			pipe_ack_o = 1'b1;
			tag_re = 1'b1;
			missmask_init = 1'b1;
			if(req_valid) begin
				pipe_stb_o = 1'b1;
				busy = 1'b1;
				tag_we = 1'b1;
				if(miss_a)
					tag_sel = 3'd0;
				else if(miss_b)
					tag_sel = 3'd1;
				else if(miss_c)
					tag_sel = 3'd2;
				else if(miss_d)
					tag_sel = 3'd3;
				else
					tag_we = 1'b0;
				if(~pipe_ack_i) begin
					tag_re = 1'b0;
					pipe_ack_o = 1'b0;
					tag_we = 1'b0;
				end
				if(more_than_one_miss) begin
					tag_re = 1'b0;
					pipe_ack_o = 1'b0;
					if(pipe_ack_i)
						next_state = RESOLVE_MISS;
				end
			end
			if(flush)
				next_state = FLUSH;
		end
		RESOLVE_MISS: begin
			busy = 1'b1;
			tag_we = 1'b1;
			missmask_we = 1'b1;
			if(miss_a & missmask[0])
				tag_sel = 3'd0;
			else if(miss_b & missmask[1])
				tag_sel = 3'd1;
			else if(miss_c & missmask[2])
				tag_sel = 3'd2;
			else if(miss_d & missmask[3])
				tag_sel = 3'd3;
			else begin
				tag_we = 1'b0;
				tag_re = 1'b1;
				pipe_ack_o = 1'b1;
				next_state = RUNNING;
			end
		end
		FLUSH: begin
			busy = 1'b1;
			tag_sel = 3'd4;
			tag_we = 1'b1;
			flush_counter_en = 1'b1;
			if(flush_done)
				next_state = RUNNING;
		end
	endcase
end

/* Forward data */
always @(posedge sys_clk) begin
	if(tag_re) begin
		dadr_f <= dadr;
		tadra_f <= tadra;
		tadrb_f <= tadrb;
		tadrc_f <= tadrc;
		tadrd_f <= tadrd;
		x_frac_f <= x_frac;
		y_frac_f <= y_frac;
	end
end

endmodule
