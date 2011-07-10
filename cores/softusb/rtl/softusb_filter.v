/*
 * Milkymist SoC
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

module softusb_filter(
	input usb_clk,

	input rcv,
	input vp,
	input vm,

	output reg rcv_s,
	output reg vp_s,
	output reg vm_s
);

reg rcv_s0;
reg vp_s0;
reg vm_s0;

/* synchronizer */
always @(posedge usb_clk) begin
	rcv_s0 <= rcv;
	vp_s0 <= vp;
	vm_s0 <= vm;
	rcv_s <= rcv_s0;
	vp_s <= vp_s0;
	vm_s <= vm_s0;
end

endmodule
