/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
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

module bram #(
	parameter adr_width = 11 // in bytes
) (
	input sys_clk,
	input sys_rst,

	input wb_stb_i,
	input wb_cyc_i,
	input wb_we_i,
	output reg wb_ack_o,
	input [31:0] wb_adr_i,
	output [31:0] wb_dat_o,
	input [31:0] wb_dat_i,
	input [3:0] wb_sel_i
);

//-----------------------------------------------------------------
// Storage depth in 32 bit words
//-----------------------------------------------------------------
parameter word_width = adr_width - 2;
parameter word_depth = (1 << word_width);


//-----------------------------------------------------------------
// Actual RAM
//-----------------------------------------------------------------
reg [7:0] ram0 [0:word_depth-1];
reg [7:0] ram1 [0:word_depth-1];
reg [7:0] ram2 [0:word_depth-1];
reg [7:0] ram3 [0:word_depth-1];
wire [word_width-1:0] adr;

wire [7:0] ram0di;
wire ram0we;
wire [7:0] ram1di;
wire ram1we;
wire [7:0] ram2di;
wire ram2we;
wire [7:0] ram3di;
wire ram3we;

reg [7:0] ram0do;
reg [7:0] ram1do;
reg [7:0] ram2do;
reg [7:0] ram3do;

always @(posedge sys_clk) begin
	if(ram0we)
		ram0[adr] <= ram0di;
	ram0do <= ram0[adr];
end

always @(posedge sys_clk) begin
	if(ram1we)
		ram1[adr] <= ram1di;
	ram1do <= ram1[adr];
end

always @(posedge sys_clk) begin
	if(ram2we)
		ram2[adr] <= ram2di;
	ram2do <= ram2[adr];
end

always @(posedge sys_clk) begin
	if(ram3we)
		ram3[adr] <= ram3di;
	ram3do <= ram3[adr];
end

assign ram0we = wb_cyc_i & wb_stb_i & wb_we_i & wb_sel_i[0];
assign ram1we = wb_cyc_i & wb_stb_i & wb_we_i & wb_sel_i[1];
assign ram2we = wb_cyc_i & wb_stb_i & wb_we_i & wb_sel_i[2];
assign ram3we = wb_cyc_i & wb_stb_i & wb_we_i & wb_sel_i[3];

assign ram0di = wb_dat_i[7:0];
assign ram1di = wb_dat_i[15:8];
assign ram2di = wb_dat_i[23:16];
assign ram3di = wb_dat_i[31:24];

assign wb_dat_o = {ram3do, ram2do, ram1do, ram0do};

assign adr = wb_adr_i[adr_width-1:2];

always @(posedge sys_clk) begin
	if(sys_rst)
		wb_ack_o <= 1'b0;
	else begin
		if(wb_cyc_i & wb_stb_i)
			wb_ack_o <= ~wb_ack_o;
		else
			wb_ack_o <= 1'b0;
	end
end

endmodule
