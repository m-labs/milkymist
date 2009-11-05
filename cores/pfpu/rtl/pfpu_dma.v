/*
 * Milkymist VJ SoC
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

module pfpu_dma(
	input sys_clk,
	input sys_rst,

	input dma_en,
	input [31:0] dma_adr,
	input [31:0] dma_d,

	output ack,
	output busy,

	output [31:0] wbm_dat_o,
	output [31:0] wbm_adr_o,
	output wbm_cyc_o,
	output wbm_stb_o,
	input wbm_ack_i,

	output [2:0] dma_pending
);

/* FIFO logic */

wire q_p;
wire q_c;
wire [63:0] q_i;
wire [63:0] q_o;
wire full;
wire empty;

reg [1:0] produce;
reg [1:0] consume;
reg [2:0] level;
reg [63:0] wq[0:3];

always @(posedge sys_clk) begin
	if(sys_rst) begin
		produce = 2'd0;
		consume = 2'd0;
		level = 3'd0;
	end else begin
		if(q_p) begin
			wq[produce] = q_i;
			produce = produce + 2'd1;
			level = level + 3'd1;
		end
		if(q_c) begin
			consume = consume + 2'd1;
			level = level - 3'd1;
		end
	end
end

assign q_o = wq[consume];
assign full = level[2];
assign empty = (level == 3'd0);

// synthesis translate_off
always @(posedge sys_clk) begin
	if(full & q_p) begin
		$display("ERROR - Writing to full DMA write queue");
		$finish;
	end
	if(empty & q_c) begin
		$display("ERROR - Reading from empty DMA write queue");
		$finish;
	end
end
// synthesis translate_on

/* Interface */
assign q_p = dma_en;
assign q_c = wbm_ack_i;
assign q_i = {dma_d, dma_adr};
assign wbm_dat_o = q_o[63:32];
assign wbm_adr_o = q_o[31:0];
assign wbm_cyc_o = ~empty;
assign wbm_stb_o = ~empty;
assign ack = ~full;
assign busy = ~empty;
assign dma_pending = level;

endmodule
