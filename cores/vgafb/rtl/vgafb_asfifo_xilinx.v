/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009, 2010 Sebastien Bourdeauducq
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

/* FIXME: this module does not work. Find out why. */

module vgafb_asfifo #(
	/* NB: those are fixed in this implementation */
	parameter DATA_WIDTH = 18,
	parameter ADDRESS_WIDTH = 11
) (
	/* Reading port */
	output [17:0] Data_out,
	output Empty_out,
	input ReadEn_in,
	input RClk,

	/* Writing port */
	input [17:0] Data_in,
	output Full_out,
	input WriteEn_in,
	input WClk,

	input Clear_in
);

wire full;
wire empty;

FIFO16 #(
	.DATA_WIDTH(9),
	.FIRST_WORD_FALL_THROUGH("TRUE")
) fifo_lo (
	.ALMOSTEMPTY(),
	.ALMOSTFULL(),
	.DO(Data_out[7:0]),
	.DOP(Data_out[8]),
	.EMPTY(empty),
	.FULL(full),
	.RDCOUNT(),
	.RDERR(),
	.WRCOUNT(),
	.WRERR(),
	.DI(Data_in[7:0]),
	.DIP(Data_in[8]),
	.RDCLK(RClk),
	.RDEN(ReadEn_in & ~empty & ~Clear_in),
	.RST(Clear_in),
	.WRCLK(WClk),
	.WREN(WriteEn_in & ~full & ~Clear_in)
);

assign Empty_out = empty;
assign Full_out = full;

FIFO16 #(
	.DATA_WIDTH(9),
	.FIRST_WORD_FALL_THROUGH("TRUE")
) fifo_hi (
	.ALMOSTEMPTY(),
	.ALMOSTFULL(),
	.DO(Data_out[16:9]),
	.DOP(Data_out[17]),
	.EMPTY(),
	.FULL(),
	.RDCOUNT(),
	.RDERR(),
	.WRCOUNT(),
	.WRERR(),
	.DI(Data_in[16:9]),
	.DIP(Data_in[17]),
	.RDCLK(RClk),
	.RDEN(ReadEn_in & ~empty & ~Clear_in),
	.RST(Clear_in),
	.WRCLK(WClk),
	.WREN(WriteEn_in & ~full & ~Clear_in)
);

endmodule

