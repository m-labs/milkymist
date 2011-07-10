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

module pfpu_seq(
	input sys_clk,
	input sys_rst,
	
	output reg alu_rst,
	
	input dma_en,
	input dma_busy,
	input dma_ack,
	
	output reg vfirst,
	output reg vnext,
	input vlast,
	
	output reg pcount_rst,
	output reg c_en,
	
	input start,
	output reg busy
);

reg [1:0] state;
reg [1:0] next_state;
parameter IDLE		= 2'd0;
parameter INIT		= 2'd1;
parameter RUNNING	= 2'd2;
parameter LASTDMA	= 2'd3;
always @(posedge sys_clk) begin
	if(sys_rst)
		state <= IDLE;
	else
		state <= next_state;
end

// synthesis translate_off
always @(posedge sys_clk) begin
	if(state == RUNNING) begin
		if(~dma_ack) begin
			$display("ERROR - Write queue acknowledge went DOWN during computation");
			$finish;
		end
	end
end
// synthesis translate_on

always @(*) begin
	next_state = state;
	
	busy = 1'b0;
	alu_rst = 1'b0;
	vfirst = 1'b0;
	vnext = 1'b0;
	
	pcount_rst = 1'b0;
	c_en = 1'b0;
	
	case(state)
		IDLE: begin
			alu_rst = 1'b1;
			pcount_rst = 1'b1;
			vfirst = 1'b1;
			c_en = 1'b1;
			if(start)
				next_state = INIT;
		end
		INIT: begin /* fetch isn 0 */
			busy = 1'b1;
			alu_rst = 1'b1;
			pcount_rst = 1'b1;
			if(dma_ack) begin
				/* we will be able to send immediately our word
				 * to the DMA engine - carry on.
				 */
				pcount_rst = 1'b0;
				next_state = RUNNING;
			end
		end
		RUNNING: begin
			busy = 1'b1;
			if(dma_en) begin
				pcount_rst = 1'b1;
				alu_rst = 1'b1;
				vnext = 1'b1;
				if(vlast)
					next_state = LASTDMA;
				else
					next_state = INIT;
			end
		end
		LASTDMA: begin
			busy = 1'b1;
			alu_rst = 1'b1;
			if(~dma_busy)
				next_state = IDLE;
		end
	endcase
end

endmodule
