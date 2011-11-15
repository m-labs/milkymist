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


module softusb_ram #(
	parameter pmem_width = 12,
	parameter dmem_width = 13,
	parameter initprog = ""
) (
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

	input pmem_ce,
	input [pmem_width-1:0] pmem_a,
	output [15:0] pmem_d,

	input dmem_we,
	input [dmem_width-1:0] dmem_a,
	input [7:0] dmem_di,
	output reg [7:0] dmem_do
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

wire [31:0] wb_dat_o_prog;
softusb_dpram #(
	.depth(pmem_width),
	.width(16),
	.initfile(initprog)
) program (
	.clk(sys_clk),
	.clk2(usb_clk),

	.a(wb_adr_i[pmem_width+1:2]),
	.we(wb_stb_i & wb_cyc_i & ~wb_adr_i[17] & wb_we_i & ~wb_ack_o),
	.di(wb_dat_i[15:0]),
	.do(wb_dat_o_prog[15:0]),

	.ce2(pmem_ce),
	.a2(pmem_a),
	.we2(1'b0),
	.di2(16'hxxxx),
	.do2(pmem_d)
);
assign wb_dat_o_prog[31:16] = 16'd0;

wire [7:0] dmem_do0;
wire [7:0] dmem_do1;
wire [7:0] dmem_do2;
wire [7:0] dmem_do3;
wire [31:0] wb_dat_o_data;

softusb_dpram #(
	.depth(dmem_width-2),
	.width(8)
) dataram0 (
	.clk(sys_clk),
	.clk2(usb_clk),

	.a(wb_adr_i[dmem_width-1:2]),
	.we(wb_stb_i & wb_cyc_i & wb_adr_i[17] & wb_we_i & wb_sel_i[0] & ~wb_ack_o),
	.di(wb_dat_i[7:0]),
	.do(wb_dat_o_data[7:0]),

	.ce2(1'b1),
	.a2(dmem_a[dmem_width-1:2]),
	.we2(dmem_we & (dmem_a[1:0] == 2'd3)),
	.di2(dmem_di),
	.do2(dmem_do0)
);

softusb_dpram #(
	.depth(dmem_width-2),
	.width(8)
) dataram1 (
	.clk(sys_clk),
	.clk2(usb_clk),

	.a(wb_adr_i[dmem_width-1:2]),
	.we(wb_stb_i & wb_cyc_i & wb_adr_i[17] & wb_we_i & wb_sel_i[1] & ~wb_ack_o),
	.di(wb_dat_i[15:8]),
	.do(wb_dat_o_data[15:8]),

	.ce2(1'b1),
	.a2(dmem_a[dmem_width-1:2]),
	.we2(dmem_we & (dmem_a[1:0] == 2'd2)),
	.di2(dmem_di),
	.do2(dmem_do1)
);

softusb_dpram #(
	.depth(dmem_width-2),
	.width(8)
) dataram2 (
	.clk(sys_clk),
	.clk2(usb_clk),

	.a(wb_adr_i[dmem_width-1:2]),
	.we(wb_stb_i & wb_cyc_i & wb_adr_i[17] & wb_we_i & wb_sel_i[2] & ~wb_ack_o),
	.di(wb_dat_i[23:16]),
	.do(wb_dat_o_data[23:16]),

	.ce2(1'b1),
	.a2(dmem_a[dmem_width-1:2]),
	.we2(dmem_we & (dmem_a[1:0] == 2'd1)),
	.di2(dmem_di),
	.do2(dmem_do2)
);

softusb_dpram #(
	.depth(dmem_width-2),
	.width(8)
) dataram3 (
	.clk(sys_clk),
	.clk2(usb_clk),

	.a(wb_adr_i[dmem_width-1:2]),
	.we(wb_stb_i & wb_cyc_i & wb_adr_i[17] & wb_we_i & wb_sel_i[3] & ~wb_ack_o),
	.di(wb_dat_i[31:24]),
	.do(wb_dat_o_data[31:24]),

	.ce2(1'b1),
	.a2(dmem_a[dmem_width-1:2]),
	.we2(dmem_we & (dmem_a[1:0] == 2'd0)),
	.di2(dmem_di),
	.do2(dmem_do3)
);

reg [1:0] dmem_a01;
always @(posedge usb_clk) dmem_a01 <= dmem_a[1:0];
always @(*) begin
	case(dmem_a01)
		2'd0: dmem_do = dmem_do3;
		2'd1: dmem_do = dmem_do2;
		2'd2: dmem_do = dmem_do1;
		2'd3: dmem_do = dmem_do0;
	endcase
end

reg datasel;
always @(posedge sys_clk) datasel <= wb_adr_i[17];
assign wb_dat_o = datasel ? wb_dat_o_data : wb_dat_o_prog;

endmodule
