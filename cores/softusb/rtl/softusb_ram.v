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


module softusb_ram(
	input sys_clk,
	input sys_rst,

	input usb_clk,
	input usb_rst,

	input [31:0] wb_adr_i,
	output [31:0] wb_dat_o,
	input [31:0] wb_dat_i,
	input [3:0] wb_sel_i,
	input wb_stb_i,
	input wb_cyc_i,
	output reg wb_ack_o,
	input wb_we_i,

	input zpu_we,
	input [3:0] zpu_sel,
	input [31:0] zpu_a,
	input [31:0] zpu_dat_i,
	output [31:0] zpu_dat_o
);

always @(posedge sys_clk) begin
	if(sys_rst)
		wb_ack_o <= 1'b0;
	else begin
		if(wb_stb_i & wb_cyc_i & ~wb_ack_o)
			wb_ack_o <= 1'b1;
		else
			wb_ack_o <= 1'b0;
	end
end

reg zpu_ack;
always @(posedge usb_clk) begin
	if(usb_rst)
		zpu_ack <= 1'b0;
	else begin
		if(zpu_we & ~zpu_ack)
			zpu_ack <= 1'b1;
		else
			zpu_ack <= 1'b0;
	end
end

parameter depth = 14; /* in bytes */

softusb_dpram #(
	.depth(depth-2),
	.width(8)
) ram0 (
	.clk(sys_clk),
	.clk2(usb_clk),

	.a(wb_adr_i[depth-1:2]),
	.we(wb_stb_i & wb_cyc_i & wb_we_i & wb_sel_i[0] & ~wb_ack_o),
	.di(wb_dat_i[7:0]),
	.do(wb_dat_o[7:0]),

	.a2(zpu_a[depth-1:2]),
	.we2(zpu_we & zpu_sel[0] & ~zpu_ack),
	.di2(zpu_dat_i[7:0]),
	.do2(zpu_dat_o[7:0])
);

softusb_dpram #(
	.depth(depth-2),
	.width(8)
) ram1 (
	.clk(sys_clk),
	.clk2(usb_clk),

	.a(wb_adr_i[depth-1:2]),
	.we(wb_stb_i & wb_cyc_i & wb_we_i & wb_sel_i[1] & ~wb_ack_o),
	.di(wb_dat_i[15:8]),
	.do(wb_dat_o[15:8]),

	.a2(zpu_a[depth-1:2]),
	.we2(zpu_we & zpu_sel[1] & ~zpu_ack),
	.di2(zpu_dat_i[15:8]),
	.do2(zpu_dat_o[15:8])
);

softusb_dpram #(
	.depth(depth-2),
	.width(8)
) ram2 (
	.clk(sys_clk),
	.clk2(usb_clk),

	.a(wb_adr_i[depth-1:2]),
	.we(wb_stb_i & wb_cyc_i & wb_we_i & wb_sel_i[2] & ~wb_ack_o),
	.di(wb_dat_i[23:16]),
	.do(wb_dat_o[23:16]),

	.a2(zpu_a[depth-1:2]),
	.we2(zpu_we & zpu_sel[2] & ~zpu_ack),
	.di2(zpu_dat_i[23:16]),
	.do2(zpu_dat_o[23:16])
);

softusb_dpram #(
	.depth(depth-2),
	.width(8)
) ram3 (
	.clk(sys_clk),
	.clk2(usb_clk),

	.a(wb_adr_i[depth-1:2]),
	.we(wb_stb_i & wb_cyc_i & wb_we_i & wb_sel_i[3] & ~wb_ack_o),
	.di(wb_dat_i[31:24]),
	.do(wb_dat_o[31:24]),

	.a2(zpu_a[depth-1:2]),
	.we2(zpu_we & zpu_sel[3] & ~zpu_ack),
	.di2(zpu_dat_i[31:24]),
	.do2(zpu_dat_o[31:24])
);

endmodule
