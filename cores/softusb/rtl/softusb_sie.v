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

module softusb_sie(
	input usb_clk,
	input usb_rst,

	input zpu_we,
	input [31:0] zpu_a,
	input [31:0] zpu_dat_i,
	output [31:0] zpu_dat_o,

	output usba_spd,
	output usba_oe_n,
	input usba_rcv,
	inout usba_vp,
	inout usba_vm,

	output usbb_spd,
	output usbb_oe_n,
	input usbb_rcv,
	inout usbb_vp,
	inout usbb_vm
);

assign zpu_dat_o = 32'd0;

assign usba_spd = 1'b0;
assign usba_oe_n = 1'b0;
assign usba_vp = 1'bz;
assign usba_vm = 1'bz;

assign usbb_spd = 1'b0;
assign usbb_oe_n = 1'b0;
assign usbb_vp = 1'bz;
assign usbb_vm = 1'bz;

endmodule
