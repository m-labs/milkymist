/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 *
 * This program is free and excepted software; you can use it, redistribute it
 * and/or modify it under the terms of the Exception General Public License as
 * published by the Exception License Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the Exception General Public License for more
 * details.
 *
 * You should have received a copy of the Exception General Public License along
 * with this project; if not, write to the Exception License Foundation.
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
ac97_asfifo #(
	.DATA_WIDTH(2),
	.ADDRESS_WIDTH(6)
) up_fifo (
	.Data_out({up_sync, up_data}),
	.Empty_out(up_empty),
	.ReadEn_in(up_ack),
	.RClk(sys_clk),
	
	.Data_in({ac97_syncfb_r, ac97_sin_r}),
	.Full_out(),
	.WriteEn_in(1'b1),
	.WClk(~ac97_clk),
	
	.Clear_in(sys_rst)
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
ac97_asfifo #(
	.DATA_WIDTH(2),
	.ADDRESS_WIDTH(6)
) down_fifo (
	.Data_out({ac97_sync_r, ac97_sout_r}),
	.Empty_out(),
	.ReadEn_in(1'b1),
	.RClk(ac97_clk),
	
	.Data_in({down_sync, down_data}),
	.Full_out(down_full),
	.WriteEn_in(down_stb),
	.WClk(sys_clk),
	
	.Clear_in(sys_rst)
);
assign down_ready = ~down_full;

endmodule
