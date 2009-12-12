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

module fmlbrg_datamem #(
	parameter depth = 11
) (
	input sys_clk,
	
	input [depth-1:0] a,
	input [7:0] we,
	input [63:0] di,
	output [63:0] do
);

reg [7:0] ram0[0:(1 << depth)-1];
reg [7:0] ram1[0:(1 << depth)-1];
reg [7:0] ram2[0:(1 << depth)-1];
reg [7:0] ram3[0:(1 << depth)-1];
reg [7:0] ram4[0:(1 << depth)-1];
reg [7:0] ram5[0:(1 << depth)-1];
reg [7:0] ram6[0:(1 << depth)-1];
reg [7:0] ram7[0:(1 << depth)-1];

wire [7:0] ram0di;
wire [7:0] ram1di;
wire [7:0] ram2di;
wire [7:0] ram3di;
wire [7:0] ram4di;
wire [7:0] ram5di;
wire [7:0] ram6di;
wire [7:0] ram7di;

reg [7:0] ram0do;
reg [7:0] ram1do;
reg [7:0] ram2do;
reg [7:0] ram3do;
reg [7:0] ram4do;
reg [7:0] ram5do;
reg [7:0] ram6do;
reg [7:0] ram7do;

/*
 * Workaround for a strange Xst 11.4 bug with Spartan-6
 * We must specify the RAMs in this order, otherwise,
 * ram1 "disappears" from the netlist. The typical
 * first symptom is a Bitgen DRC failure because of
 * dangling I/O pins going to the SDRAM.
 * Problem reported to Xilinx.
 */
always @(posedge sys_clk) begin
	if(we[1]) begin
		ram1[a] <= ram1di;
		ram1do <= ram1di;
	end else
		ram1do <= ram1[a];
end
always @(posedge sys_clk) begin
	if(we[0]) begin
		ram0[a] <= ram0di;
		ram0do <= ram0di;
	end else
		ram0do <= ram0[a];
end
always @(posedge sys_clk) begin
	if(we[2]) begin
		ram2[a] <= ram2di;
		ram2do <= ram2di;
	end else
		ram2do <= ram2[a];
end
always @(posedge sys_clk) begin
	if(we[3]) begin
		ram3[a] <= ram3di;
		ram3do <= ram3di;
	end else
		ram3do <= ram3[a];
end
always @(posedge sys_clk) begin
	if(we[4]) begin
		ram4[a] <= ram4di;
		ram4do <= ram4di;
	end else
		ram4do <= ram4[a];
end
always @(posedge sys_clk) begin
	if(we[5]) begin
		ram5[a] <= ram5di;
		ram5do <= ram5di;
	end else
		ram5do <= ram5[a];
end
always @(posedge sys_clk) begin
	if(we[6]) begin
		ram6[a] <= ram6di;
		ram6do <= ram6di;
	end else
		ram6do <= ram6[a];
end
always @(posedge sys_clk) begin
	if(we[7]) begin
		ram7[a] <= ram7di;
		ram7do <= ram7di;
	end else
		ram7do <= ram7[a];
end

assign ram0di = di[7:0];
assign ram1di = di[15:8];
assign ram2di = di[23:16];
assign ram3di = di[31:24];
assign ram4di = di[39:32];
assign ram5di = di[47:40];
assign ram6di = di[55:48];
assign ram7di = di[63:56];

assign do = {ram7do, ram6do, ram5do, ram4do, ram3do, ram2do, ram1do, ram0do};

endmodule
