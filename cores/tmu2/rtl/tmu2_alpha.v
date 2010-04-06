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

module tmu2_alpha #(
	parameter fml_depth = 26
) (
	input sys_clk,
	input sys_rst,

	output busy,

	input [5:0] alpha,

	input pipe_stb_i,
	output pipe_ack_o,
	input [15:0] color,
	input [fml_depth-1-1:0] dadr, /* in 16-bit words */
	input [15:0] dcolor,

	output pipe_stb_o,
	input pipe_ack_i,
	output reg [fml_depth-1-1:0] dadr_f,
	output [15:0] acolor
);

wire en;
reg valid_1;
reg valid_2;
reg valid_3;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		valid_1 <= 1'b0;
		valid_2 <= 1'b0;
		valid_3 <= 1'b0;
	end else if(en) begin
		valid_1 <= pipe_stb_i;
		valid_2 <= valid_1;
		valid_3 <= valid_2;
	end
end

/* Pipeline operation on three stages. */
reg [fml_depth-1-1:0] dadr_1;
reg [fml_depth-1-1:0] dadr_2;

wire [4:0] r = color[15:11];
wire [5:0] g = color[10:5];
wire [4:0] b = color[4:0];
wire [4:0] dr = dcolor[15:11];
wire [5:0] dg = dcolor[10:5];
wire [4:0] db = dcolor[4:0];

reg [10:0] r_1;
reg [11:0] g_1;
reg [10:0] b_1;
reg [10:0] dr_1;
reg [11:0] dg_1;
reg [10:0] db_1;

reg [10:0] r_2;
reg [11:0] g_2;
reg [10:0] b_2;
reg [10:0] dr_2;
reg [11:0] dg_2;
reg [10:0] db_2;

reg [10:0] r_3;
reg [11:0] g_3;
reg [10:0] b_3;

always @(posedge sys_clk) begin
	if(en) begin
		dadr_1 <= dadr;
		dadr_2 <= dadr_1;
		dadr_f <= dadr_2;

		r_1 <= ({1'b0, alpha} + 7'd1)*r;
		g_1 <= ({1'b0, alpha} + 7'd1)*g;
		b_1 <= ({1'b0, alpha} + 7'd1)*b;
		dr_1 <= (6'd63 - alpha)*dr;
		dg_1 <= (6'd63 - alpha)*dg;
		db_1 <= (6'd63 - alpha)*db;

		r_2 <= r_1;
		g_2 <= g_1;
		b_2 <= b_1;
		dr_2 <= dr_1;
		dg_2 <= dg_1;
		db_2 <= db_1;

		r_3 <= r_2 + dr_2;
		g_3 <= g_2 + dg_2;
		b_3 <= b_2 + db_2;
	end
end

assign acolor = {r_3[10:6], g_3[11:6], b_3[10:6]};

/* Pipeline management */

assign busy = valid_1 | valid_2 | valid_3;

assign pipe_ack_o = ~valid_3 | pipe_ack_i;
assign en = ~valid_3 | pipe_ack_i;

assign pipe_stb_o = valid_3;

endmodule
