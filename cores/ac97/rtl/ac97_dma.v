/*
 * Milkymist SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
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

module ac97_dma(
	input sys_rst,
	input sys_clk,
	
	output reg [31:0] wbm_adr_o,
	output [2:0] wbm_cti_o,
	output reg wbm_we_o,
	output wbm_cyc_o,
	output wbm_stb_o,
	input wbm_ack_i,
	input [31:0] wbm_dat_i,
	output [31:0] wbm_dat_o,
	
	output reg down_en,
	input down_next_frame,
	output reg down_pcmleft_valid,
	output reg [19:0] down_pcmleft,
	output reg down_pcmright_valid,
	output reg [19:0] down_pcmright,
	
	output reg up_en,
	input up_next_frame,
	input up_frame_valid,
	input up_pcmleft_valid,
	input [19:0] up_pcmleft,
	input up_pcmright_valid,
	input [19:0] up_pcmright,
	
	/* in 32-bit words */
	input dmar_en,
	input [29:0] dmar_addr,
	input [15:0] dmar_remaining,
	output reg dmar_next,
	input dmaw_en,
	input [29:0] dmaw_addr,
	input [15:0] dmaw_remaining,
	output reg dmaw_next
);

assign wbm_cti_o = 3'd0;

reg wbm_strobe;
assign wbm_cyc_o = wbm_strobe;
assign wbm_stb_o = wbm_strobe;

reg load_read_addr;
reg load_write_addr;
always @(posedge sys_clk) begin
	if(load_read_addr)
		wbm_adr_o <= {dmar_addr, 2'b00};
	else if(load_write_addr)
		wbm_adr_o <= {dmaw_addr, 2'b00};
end

reg load_downpcm;
always @(posedge sys_clk) begin
	if(load_downpcm) begin
		down_pcmleft_valid <= dmar_en;
		down_pcmright_valid <= dmar_en;
		down_pcmleft <= {20{dmar_en}} & {{wbm_dat_i[31:16], wbm_dat_i[30:27]}};
		down_pcmright <= {20{dmar_en}} & {{wbm_dat_i[15:0], wbm_dat_i[14:11]}};
	end
end

assign wbm_dat_o = {up_pcmleft[19:4], up_pcmright[19:4]};

reg [2:0] state;
reg [2:0] next_state;

parameter IDLE		= 3'd0;
parameter DMAR		= 3'd1;
parameter DMAW		= 3'd2;
parameter NEXTDFRAME	= 3'd3;
parameter NEXTUFRAME	= 3'd4;

wire dmar_finished = dmar_remaining == 16'd0;
wire dmaw_finished = dmaw_remaining == 16'd0;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= IDLE;
	else
		state <= next_state;
	//$display("state:%d->%d %b %b %b", state, next_state, down_next_frame, dmar_en, ~dmar_finished);
end

always @(*) begin
	next_state = state;

	wbm_strobe = 1'b0;
	load_read_addr = 1'b0;
	load_write_addr = 1'b0;
	wbm_we_o = 1'b0;
	down_en = 1'b0;
	up_en = 1'b0;
	
	dmar_next = 1'b0;
	dmaw_next = 1'b0;
	
	load_downpcm = 1'b0;
	
	case(state)
		IDLE: begin
			down_en = 1'b1;
			up_en = 1'b1;
			
			if(down_next_frame) begin
				if(dmar_en)
					down_en = 1'b0;
				else
					load_downpcm = 1'b1;
			end
			if(up_next_frame) begin
				if(dmaw_en)
					up_en = 1'b0;
			end
			
			if(down_next_frame & dmar_en & ~dmar_finished) begin
				load_read_addr = 1'b1;
				next_state = DMAR;
			end else if(up_next_frame & dmaw_en & ~dmaw_finished) begin
				load_write_addr = 1'b1;
				next_state = DMAW;
			end
		end
		DMAR: begin
			wbm_strobe = 1'b1;
			load_downpcm = 1'b1;
			if(wbm_ack_i) begin
				dmar_next = 1'b1;
				next_state = NEXTDFRAME;
			end
		end
		DMAW: begin
			wbm_strobe = 1'b1;
			wbm_we_o = 1'b1;
			if(wbm_ack_i) begin
				dmaw_next = 1'b1;
				next_state = NEXTUFRAME;
			end
		end
		NEXTDFRAME: begin
			down_en = 1'b1;
			next_state = IDLE;
		end
		NEXTUFRAME: begin
			up_en = 1'b1;
			next_state = IDLE;
		end
	endcase
end

endmodule
