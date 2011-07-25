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

module tmu2_fetchtexel #(
	parameter depth = 2,
	parameter fml_depth = 26
) (
	input sys_clk,
	input sys_rst,

	output busy,

	input pipe_stb_i,
	output pipe_ack_o,
	input [fml_depth-5-1:0] fetch_adr,
	
	output pipe_stb_o,
	input pipe_ack_i,
	output [255:0] fetch_dat,
	
	output reg [fml_depth-1:0] fml_adr,
	output reg fml_stb,
	input fml_ack,
	input [63:0] fml_di
);

/* Generate FML requests */
wire fetch_en;
always @(posedge sys_clk) begin
	if(sys_rst)
		fml_stb <= 1'b0;
	else begin
		if(fml_ack)
			fml_stb <= 1'b0;
		if(pipe_ack_o) begin
			fml_stb <= pipe_stb_i;
			fml_adr <= {fetch_adr, 5'd0};
		end
	end
end
assign pipe_ack_o = fetch_en & (~fml_stb | fml_ack);

/* Gather received data */
wire fifo_we;
tmu2_fifo64to256 #(
	.depth(depth)
) fifo64to256 (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.w8avail(fetch_en),
	.we(fifo_we),
	.wd(fml_di),
	
	.ravail(pipe_stb_o),
	.re(pipe_ack_i),
	.rd(fetch_dat)
);

reg [1:0] bcount;
assign fifo_we = fml_ack | (|bcount);
always @(posedge sys_clk) begin
	if(sys_rst)
		bcount <= 2'd0;
	else if(fml_ack)
		bcount <= 2'd3;
	else if(|bcount)
		bcount <= bcount - 2'd1;
end

assign busy = pipe_stb_o | fml_stb | fifo_we;

endmodule
