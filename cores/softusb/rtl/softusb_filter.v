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
reg rcv_s1;
reg vp_s1;
reg vm_s1;

/* synchronizer */
always @(posedge usb_clk) begin
	rcv_s0 <= rcv;
	vp_s0 <= vp;
	vm_s0 <= vm;
	rcv_s1 <= rcv_s0;
	vp_s1 <= vp_s0;
	vm_s1 <= vm_s0;
end

/* glitch filter */
reg rcv_s2;
reg vp_s2;
reg vm_s2;
always @(posedge usb_clk) begin
	rcv_s2 <= rcv_s1;
	vp_s2 <= vp_s1;
	vm_s2 <= vm_s1;

	if(rcv_s2 == rcv_s1)
		rcv_s <= rcv_s2;
	if(vp_s2 == vp_s1)
		vp_s <= vp_s2;
	if(vm_s2 == vm_s1)
		vm_s <= vm_s2;
end

endmodule
