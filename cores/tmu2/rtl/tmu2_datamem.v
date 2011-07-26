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

module tmu2_datamem #(
	parameter cache_depth = 13,
	parameter fml_depth = 26
) (
	input sys_clk,
	input sys_rst,
	
	output reg busy,
	
	/* from fragment FIFO */
	input frag_pipe_stb_i,
	output reg frag_pipe_ack_o,
	input [fml_depth-1-1:0] frag_dadr,
	input [cache_depth-1:0] frag_tadra, /* < texel cache addresses (in bytes) */
	input [cache_depth-1:0] frag_tadrb,
	input [cache_depth-1:0] frag_tadrc,
	input [cache_depth-1:0] frag_tadrd,
	input [5:0] frag_x_frac,
	input [5:0] frag_y_frac,
	input frag_miss_a,
	input frag_miss_b,
	input frag_miss_c,
	input frag_miss_d,
	
	/* from fetch unit */
	input fetch_pipe_stb_i,
	output reg fetch_pipe_ack_o,
	input [255:0] fetch_dat,
	
	/* to downstream pipeline */
	output reg pipe_stb_o,
	input pipe_ack_i,
	output reg [fml_depth-1-1:0] dadr_f, /* in 16-bit words */
	output [15:0] tcolora,
	output [15:0] tcolorb,
	output [15:0] tcolorc,
	output [15:0] tcolord,
	output reg [5:0] x_frac_f,
	output reg [5:0] y_frac_f
);

reg req_ce;
reg req_valid;
reg [cache_depth-1:0] frag_tadra_r;
reg [cache_depth-1:0] frag_tadrb_r;
reg [cache_depth-1:0] frag_tadrc_r;
reg [cache_depth-1:0] frag_tadrd_r;
reg frag_miss_a_r;
reg frag_miss_b_r;
reg frag_miss_c_r;
reg frag_miss_d_r;
always @(posedge sys_clk) begin
	if(req_ce) begin
		req_valid <= frag_pipe_stb_i;
		
		frag_tadra_r <= frag_tadra;
		frag_tadrb_r <= frag_tadrb;
		frag_tadrc_r <= frag_tadrc;
		frag_tadrd_r <= frag_tadrd;
		frag_miss_a_r <= frag_miss_a;
		frag_miss_b_r <= frag_miss_b;
		frag_miss_c_r <= frag_miss_c;
		frag_miss_d_r <= frag_miss_d;
		
		dadr_f <= frag_dadr;
		x_frac_f <= frag_x_frac;
		y_frac_f <= frag_y_frac;
	end
end

reg retry;
wire [cache_depth-1:0] adra = retry ? frag_tadra_r : frag_tadra;
wire [cache_depth-1:0] adrb = retry ? frag_tadrb_r : frag_tadrb;
wire [cache_depth-1:0] adrc = retry ? frag_tadrc_r : frag_tadrc;
wire [cache_depth-1:0] adrd = retry ? frag_tadrd_r : frag_tadrd;

reg [1:0] wa_sel;
reg [cache_depth-1:0] wa;
always @(*) begin
	case(wa_sel)
		2'd0: wa = frag_tadra_r;
		2'd1: wa = frag_tadrb_r;
		2'd2: wa = frag_tadrc_r;
		default: wa = frag_tadrd_r;
	endcase
end

reg we;
tmu2_qpram #(
	.depth(cache_depth)
) qpram (
	.sys_clk(sys_clk),
	
	.raa(adra),
	.rda(tcolora),
	.rab(adrb),
	.rdb(tcolorb),
	.rac(adrc),
	.rdc(tcolorc),
	.rad(adrd),
	.rdd(tcolord),
	
	.we(we),
	.wa(wa),
	.wd(fetch_dat)
);

reg [3:0] missmask;
reg missmask_init;
reg missmask_we;
always @(posedge sys_clk) begin
	if(missmask_init) begin
		missmask <= 4'b1111;
		if(missmask_we) begin
			case(wa_sel)
				2'd0: missmask <= 4'b1110;
				2'd1: missmask <= 4'b1101;
				2'd2: missmask <= 4'b1011;
				default: missmask <= 4'b0111;
			endcase
		end
	end else if(missmask_we) begin
		case(wa_sel)
			2'd0: missmask <= missmask & 4'b1110;
			2'd1: missmask <= missmask & 4'b1101;
			2'd2: missmask <= missmask & 4'b1011;
			default: missmask <= missmask & 4'b0111;
		endcase
	end
end

reg [1:0] state;
reg [1:0] next_state;

parameter RUNNING		= 2'd0;
parameter COMMIT		= 2'd1;
parameter STROBE		= 2'd2;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= RUNNING;
	else
		state <= next_state;
end

always @(*) begin
	next_state = state;
	
	busy = 1'b0;
	frag_pipe_ack_o = 1'b0;
	fetch_pipe_ack_o = 1'b0;
	pipe_stb_o = 1'b0;
	
	req_ce = 1'b0;
	retry = 1'b0;
	wa_sel = 2'd0;
	we = 1'b0;
	missmask_init = 1'b0;
	missmask_we = 1'b0;
	
	case(state)
		RUNNING: begin
			frag_pipe_ack_o = 1'b1;
			req_ce = 1'b1;
			missmask_init = 1'b1;
			if(req_valid) begin
				busy = 1'b1;
				pipe_stb_o = 1'b1;
				if(frag_miss_a_r | frag_miss_b_r | frag_miss_c_r | frag_miss_d_r) begin
					frag_pipe_ack_o = 1'b0;
					req_ce = 1'b0;
					pipe_stb_o = 1'b0;
					fetch_pipe_ack_o = 1'b1;
					if(fetch_pipe_stb_i) begin
						if(frag_miss_a_r)
							wa_sel = 2'd0;
						else if(frag_miss_b_r)
							wa_sel = 2'd1;
						else if(frag_miss_c_r)
							wa_sel = 2'd2;
						else
							wa_sel = 2'd3;
						missmask_we = 1'b1;
						we = 1'b1;
					end
					next_state = COMMIT;
				end else if(~pipe_ack_i) begin
					frag_pipe_ack_o = 1'b0;
					req_ce = 1'b0;
					retry = 1'b1;
				end
			end
		end
		COMMIT: begin
			busy = 1'b1;
			retry = 1'b1;
			if((frag_miss_a_r & missmask[0]) | (frag_miss_b_r & missmask[1]) | (frag_miss_c_r & missmask[2]) | (frag_miss_d_r & missmask[3])) begin
				fetch_pipe_ack_o = 1'b1;
				if(fetch_pipe_stb_i) begin
					if(frag_miss_a_r & missmask[0])
						wa_sel = 2'd0;
					else if(frag_miss_b_r & missmask[1])
						wa_sel = 2'd1;
					else if(frag_miss_c_r & missmask[2])
						wa_sel = 2'd2;
					else
						wa_sel = 2'd3;
					missmask_we = 1'b1;
					we = 1'b1;
				end
			end else
				next_state = STROBE;
		end
		STROBE: begin
			busy = 1'b1;
			retry = 1'b1;
			pipe_stb_o = 1'b1;
			if(pipe_ack_i) begin
				retry = 1'b0;
				req_ce = 1'b1;
				frag_pipe_ack_o = 1'b1;
				next_state = RUNNING;
			end
		end
	endcase
end

endmodule
