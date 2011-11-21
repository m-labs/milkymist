/*
 * Milkymist SoC
 * Copyright (C) 2007, 2008, 2009, 2010 Sebastien Bourdeauducq
 * Copyright (C) 2010 Michael Walle
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

module monitor(
	input sys_clk,
	input sys_rst,

	input write_lock,

	input [31:0] wb_adr_i,
	output reg [31:0] wb_dat_o,
	input [31:0] wb_dat_i,
	input [3:0] wb_sel_i,
	input wb_stb_i,
	input wb_cyc_i,
	output reg wb_ack_o,
	input wb_we_i
);

`ifdef CFG_GDBSTUB_ENABLED
/* 8kb ram */
reg [31:0] mem[0:2047];
initial $readmemh("gdbstub.rom", mem);
`else
/* 2kb ram */
reg [31:0] mem[0:511];
initial $readmemh("monitor.rom", mem);
`endif

/* write protect */
`ifdef CFG_GDBSTUB_ENABLED
assign ram_we = (wb_adr_i[12] == 1'b1) | ~write_lock;
wire [10:0] adr;
assign adr = wb_adr_i[12:2];
`else
assign ram_we = (wb_adr_i[10:9] == 2'b11) | ~write_lock;
wire [9:0] adr;
assign adr = wb_adr_i[10:2];
`endif

always @(posedge sys_clk) begin
	wb_dat_o <= mem[adr];
	if(sys_rst)
		wb_ack_o <= 1'b0;
	else begin
		wb_ack_o <= 1'b0;
		
		if(wb_stb_i & wb_cyc_i & ~wb_ack_o) begin
			if(wb_we_i & ram_we) begin
				if(wb_sel_i[0])
					mem[adr][7:0] <= wb_dat_i[7:0];
				if(wb_sel_i[1])
					mem[adr][15:8] <= wb_dat_i[15:8];
				if(wb_sel_i[2])
					mem[adr][23:16] <= wb_dat_i[23:16];
				if(wb_sel_i[3])
					mem[adr][31:24] <= wb_dat_i[31:24];
			end

			wb_ack_o <= 1'b1;
		end
	
	end
end

endmodule
