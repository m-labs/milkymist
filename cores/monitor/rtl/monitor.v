/*
 * Milkymist VJ SoC
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

	input [31:0] wb_adr_i,
	output [31:0] wb_dat_o,
	input [31:0] wb_dat_i,
	input [3:0] wb_sel_i,
	input wb_stb_i,
	input wb_cyc_i,
	output reg wb_ack_o,
	input wb_we_i
);

parameter s_idle    = 2'd0;
parameter s_readout = 2'd1;
parameter s_write   = 2'd2;
parameter s_ack     = 2'd3;

reg [31:0] wdata;
reg [1:0] state;
reg we;
reg [31:0] dat_o;
wire ram_we;

/* 2kb ram */
reg [31:0] mem[0:511];
initial $readmemh("monitor.rom", mem);

/* write protect */
assign ram_we = (wb_adr_i[10:9] == 2'b11);

assign wb_dat_o = dat_o;

always @(posedge sys_clk)
	dat_o <= mem[wb_adr_i[10:2]];

always @(posedge sys_clk) begin
	if(sys_rst) begin	
		wb_ack_o <= 1'b0;
		wdata <= 32'd0;
		state <= s_idle;
	end else begin
		case(state)
			s_idle: begin
				if(wb_stb_i & wb_cyc_i)
					state <= s_readout;
			end
			s_readout: begin
				/* read/modify */
				wdata[7:0]   <= wb_sel_i[0] ? wb_dat_i[7:0]   : dat_o[7:0];
				wdata[15:8]  <= wb_sel_i[1] ? wb_dat_i[15:8]  : dat_o[15:8];
				wdata[23:16] <= wb_sel_i[2] ? wb_dat_i[23:16] : dat_o[23:16];
				wdata[31:24] <= wb_sel_i[3] ? wb_dat_i[31:24] : dat_o[31:24];
				if(wb_we_i & ram_we) begin
					state <= s_write;
				end else begin
					wb_ack_o <= 1'b1;
					state <= s_ack;
				end
			end
			s_write: begin
				/* write */
				mem[wb_adr_i[10:2]] <= wdata;
				wb_ack_o <= 1'b1;
				state <= s_ack;
			end
			s_ack: begin
				wb_ack_o <= 1'b0;
				state <= s_idle;
			end
		endcase
	end
end

endmodule

