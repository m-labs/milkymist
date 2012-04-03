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

module softusb_hostif #(
	parameter csr_addr = 4'h0,
	parameter pmem_width = 12
) (
	input sys_clk,
	input sys_rst,

	input usb_clk,
	output reg usb_rst,

	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output reg [31:0] csr_do,

	output irq,

	input io_we,
	input [5:0] io_a,

	input [pmem_width-1:0] dbg_pc
);

wire csr_selected = csr_a[13:10] == csr_addr;

reg usb_rst0;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		usb_rst0 <= 1'b1;
		csr_do <= 1'b0;
	end else begin
		csr_do <= 1'b0;
		if(csr_selected) begin
			if(csr_we)
				usb_rst0 <= csr_di[0];
			csr_do <= { dbg_pc, 1'b0 };
		end
	end
end

/* Synchronize USB Reset to the USB clock domain */
reg usb_rst1;

always @(posedge usb_clk) begin
	usb_rst1 <= usb_rst0;
	usb_rst <= usb_rst1;
end

/* Generate IRQs */

reg irq_flip;
always @(posedge usb_clk) begin
	if(usb_rst)
		irq_flip <= 1'b0;
	else if(io_we && (io_a == 6'h15))
		irq_flip <= ~irq_flip;
end

reg irq_flip0;
reg irq_flip1;
reg irq_flip2;

always @(posedge sys_clk) begin
	irq_flip0 <= irq_flip;
	irq_flip1 <= irq_flip0;
	irq_flip2 <= irq_flip1;
end

assign irq = irq_flip1 != irq_flip2;

endmodule

