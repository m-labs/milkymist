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
	input [28:0] dma_base,
	input [6:0] x,
	input [6:0] y,
	input [31:0] dma_d1,
	input [31:0] dma_d2,

	output ack,
	output busy,

	output [31:0] wbm_dat_o,
	output reg [31:0] wbm_adr_o,
	output wbm_cyc_o,
	output wbm_stb_o,
	input wbm_ack_i,

	output [2:0] dma_pending
);

/* FIFO logic */

parameter q_width = 7+7+64;

wire q_p;
wire q_c;
wire [q_width-1:0] q_i;
wire [q_width-1:0] q_o;
wire full;
wire empty;

reg [1:0] produce;
reg [1:0] consume;
reg [2:0] level;
reg [q_width-1:0] wq[0:3];

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
reg write_y;

assign q_p = dma_en;
assign q_c = wbm_ack_i & write_y;
assign q_i = {dma_d1, dma_d2, y, x};

always @(posedge sys_clk)
	wbm_adr_o <= {dma_base, 3'd0} + {q_o[13:0], write_y, 2'd0};

always @(posedge sys_clk) begin
	if(sys_rst)
		write_y <= 1'b0;
	else if(wbm_ack_i) write_y <= ~write_y;
end

assign wbm_dat_o = write_y ? q_o[45:14] : q_o[q_width-1:46];

reg address_not_valid_yet;
always @(posedge sys_clk)
	address_not_valid_yet <= q_c;

assign wbm_cyc_o = ~empty & ~address_not_valid_yet;
assign wbm_stb_o = ~empty & ~address_not_valid_yet;

assign ack = ~full;
assign busy = ~empty;
assign dma_pending = level;

endmodule
