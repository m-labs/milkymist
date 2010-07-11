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

module softusb_timer(
	input usb_clk,
	input usb_rst,

	input zpu_we,
	output [31:0] zpu_dat_o
);

reg [31:0] counter;

always @(posedge usb_clk) begin
	if(usb_rst)
		counter <= 32'd0;
	else begin
		if(zpu_we)
			counter <= 32'd0;
		else
			counter <= counter + 32'd1;
	end
end

assign zpu_dat_o = counter;

endmodule
