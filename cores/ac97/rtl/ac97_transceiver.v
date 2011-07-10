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

module ac97_transceiver(
	input sys_clk,
	input sys_rst,
	input ac97_clk,
	input ac97_rst_n,
	
	/* to codec */
	input ac97_sin,
	output reg ac97_sout,
	output reg ac97_sync,
	
	/* to system, upstream */
	output up_stb,
	input up_ack,
	output up_sync,
	output up_data,
	
	/* to system, downstream */
	output down_ready,
	input down_stb,
	input down_sync,
	input down_data
);

/* Upstream */
reg ac97_sin_r;
always @(negedge ac97_clk) ac97_sin_r <= ac97_sin;

reg ac97_syncfb_r;
always @(negedge ac97_clk) ac97_syncfb_r <= ac97_sync;

wire up_empty;
asfifo #(
	.data_width(2),
	.address_width(6)
) up_fifo (
	.data_out({up_sync, up_data}),
	.empty(up_empty),
	.read_en(up_ack),
	.clk_read(sys_clk),
	
	.data_in({ac97_syncfb_r, ac97_sin_r}),
	.full(),
	.write_en(1'b1),
	.clk_write(~ac97_clk),
	
	.rst(sys_rst)
);
assign up_stb = ~up_empty;

/* Downstream */

/* Set SOUT and SYNC to 0 during RESET to avoid ATE/Test Mode */
wire ac97_sync_r;
always @(negedge ac97_rst_n, posedge ac97_clk) begin
	if(~ac97_rst_n)
		ac97_sync <= 1'b0;
	else
		ac97_sync <= ac97_sync_r;
end

wire ac97_sout_r;
always @(negedge ac97_rst_n, posedge ac97_clk) begin
	if(~ac97_rst_n)
		ac97_sout <= 1'b0;
	else
		ac97_sout <= ac97_sout_r;
end

wire down_full;
asfifo #(
	.data_width(2),
	.address_width(6)
) down_fifo (
	.data_out({ac97_sync_r, ac97_sout_r}),
	.empty(),
	.read_en(1'b1),
	.clk_read(ac97_clk),
	
	.data_in({down_sync, down_data}),
	.full(down_full),
	.write_en(down_stb),
	.clk_write(sys_clk),

	.rst(sys_rst)
);
assign down_ready = ~down_full;

endmodule
