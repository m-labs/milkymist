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
	output [31:0] wbm_adr_o,
	output wbm_cyc_o,
	output reg wbm_stb_o,
	input wbm_ack_i
);

reg write_y;
reg [28:0] vector_start;
reg [31:0] dma_d1_r;
reg [31:0] dma_d2_r;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		vector_start <= 29'd0;
		write_y <= 1'b0;
		wbm_stb_o <= 1'b0;
	end else begin
		if(dma_en) begin
			wbm_stb_o <= 1'b1;
			write_y <= 1'b0;
			vector_start <= dma_base + {y, x};
			dma_d1_r <= dma_d1;
			dma_d2_r <= dma_d2;
		end
		if(wbm_ack_i) begin
			if(write_y)
				wbm_stb_o <= 1'b0;
			else
				write_y <= ~write_y;
		end
	end
end

assign wbm_adr_o = {vector_start, write_y, 2'b00};
assign wbm_dat_o = write_y ? dma_d2_r : dma_d1_r;

assign wbm_cyc_o = wbm_stb_o;

assign ack = ~wbm_stb_o;
assign busy = wbm_stb_o;

endmodule
