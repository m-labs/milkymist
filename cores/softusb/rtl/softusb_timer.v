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

module softusb_timer(
	input usb_clk,
	input usb_rst,

	input io_we,
	input [5:0] io_a,
	output reg [7:0] io_do
);

reg [31:0] counter;

always @(posedge usb_clk) begin
	if(usb_rst) begin
		counter <= 32'd0;
		io_do <= 8'd0;
	end else begin
		io_do <= 8'd0;
		case(io_a)
			6'h20: io_do <= counter[7:0];
			6'h21: io_do <= counter[15:8];
			6'h22: io_do <= counter[23:16];
			6'h23: io_do <= counter[31:24];
		endcase
		if(io_we & ((io_a == 6'h20)|(io_a == 6'h21)|(io_a == 6'h22)|(io_a == 6'h23)))
			counter <= 32'd0;
		else
			counter <= counter + 32'd1;
	end
end

endmodule
