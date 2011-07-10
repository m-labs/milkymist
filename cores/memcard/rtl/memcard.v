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

module memcard #(
	parameter csr_addr = 4'h0
) (
	input sys_clk,
	input sys_rst,

	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output reg [31:0] csr_do,

	inout [3:0] mc_d,
	inout mc_cmd,
	output mc_clk
);

reg [10:0] clkdiv2x_factor;
reg cmd_tx_enabled;
reg cmd_tx_pending;
reg cmd_rx_enabled;
reg cmd_rx_pending;
reg cmd_rx_started;
reg [7:0] cmd_data;
reg dat_tx_enabled;
reg dat_tx_pending;
reg dat_rx_enabled;
reg dat_rx_pending;
reg dat_rx_started;
reg [31:0] dat_data;

reg [10:0] clkdiv2x_counter;
reg clkdiv2x_ce;
always @(posedge sys_clk) begin
	if(sys_rst) begin
		clkdiv2x_counter <= 11'd0;
		clkdiv2x_ce <= 1'b0;
	end else begin
		clkdiv2x_counter <= clkdiv2x_counter + 1'b1;
		clkdiv2x_ce <= 1'b0;
		if(clkdiv2x_counter == clkdiv2x_factor) begin
			clkdiv2x_counter <= 11'd0;
			clkdiv2x_ce <= 1'b1;
		end
	end
end

wire clock_active = (~cmd_tx_enabled | cmd_tx_pending)
	&(~cmd_rx_enabled | ~cmd_rx_pending)
	&(~dat_tx_enabled | dat_tx_pending)
	&(~dat_rx_enabled | ~dat_rx_pending);
reg clkdiv;
always @(posedge sys_clk) begin
	if(sys_rst)
		clkdiv <= 1'b0;
	else if(clkdiv2x_ce & clock_active)
		clkdiv <= ~clkdiv;
end

reg clkdiv_ce0;
reg clkdiv_ce;
always @(posedge sys_clk) begin
	clkdiv_ce0 <= clkdiv2x_ce & clock_active & ~clkdiv;
	clkdiv_ce <= clkdiv_ce0;
end

reg mc_cmd_r0;
reg mc_cmd_r1;
reg mc_cmd_r2;
always @(posedge sys_clk) begin
	mc_cmd_r0 <= mc_cmd;
	mc_cmd_r1 <= mc_cmd_r0;
	mc_cmd_r2 <= mc_cmd_r1;
end

reg [3:0] mc_d_r0;
reg [3:0] mc_d_r1;
reg [3:0] mc_d_r2;
always @(posedge sys_clk) begin
	mc_d_r0 <= mc_d;
	mc_d_r1 <= mc_d_r0;
	mc_d_r2 <= mc_d_r1;
end

wire csr_selected = csr_a[13:10] == csr_addr;

reg [2:0] cmd_bitcount;
reg [2:0] dat_bitcount;
always @(posedge sys_clk) begin
	if(sys_rst) begin
		csr_do <= 32'd0;
		
		clkdiv2x_factor <= 11'd1023;
		cmd_tx_enabled <= 1'b0;
		cmd_tx_pending <= 1'b0;
		cmd_rx_enabled <= 1'b0;
		cmd_rx_pending <= 1'b0;
		cmd_rx_started <= 1'b0;
		cmd_data <= 8'd0;
		dat_tx_enabled <= 1'b0;
		dat_tx_pending <= 1'b0;
		dat_rx_enabled <= 1'b0;
		dat_rx_pending <= 1'b0;
		dat_rx_started <= 1'b0;
		dat_data <= 32'd0;

		cmd_bitcount <= 3'd0;
		dat_bitcount <= 3'd0;
	end else begin
		csr_do <= 32'd0;

		if(csr_selected) begin
			case(csr_a[2:0])
				3'b000: csr_do <= clkdiv2x_factor;
				3'b001: csr_do <= {dat_rx_enabled, dat_tx_enabled, cmd_rx_enabled, cmd_tx_enabled};
				3'b010: csr_do <= {dat_rx_pending, dat_tx_pending, cmd_rx_pending, cmd_tx_pending};
				3'b011: csr_do <= {dat_rx_started, cmd_rx_started};
				3'b100: csr_do <= cmd_data;
				3'b101: csr_do <= dat_data;
			endcase
			if(csr_we) begin
				case(csr_a[2:0])
					3'b000: clkdiv2x_factor <= csr_di[10:0];
					3'b001: {dat_rx_enabled, dat_tx_enabled, cmd_rx_enabled, cmd_tx_enabled} <= csr_di[3:0];
					3'b010: begin
						if(csr_di[1]) begin
							cmd_rx_pending <= 1'b0;
							cmd_bitcount <= 3'd0;
						end
						if(csr_di[3]) begin
							dat_rx_pending <= 1'b0;
							dat_bitcount <= 3'd0;
						end
					end
					3'b011: begin
						if(csr_di[0])
							cmd_rx_started <= 1'b0;
						if(csr_di[1])
							dat_rx_started <= 1'b0;
					end
					3'b100: begin
						cmd_data <= csr_di[7:0];
						cmd_tx_pending <= 1'b1;
						cmd_bitcount <= 3'd0;
					end
					3'b101: begin
						dat_data <= csr_di;
						dat_tx_pending <= 1'b1;
						dat_bitcount <= 3'd0;
					end
				endcase
			end
		end

		if(clkdiv_ce) begin
			if(cmd_tx_enabled|cmd_rx_started|~mc_cmd_r2) begin
				cmd_data <= {cmd_data[6:0], mc_cmd_r2};
				if(cmd_rx_enabled)
					cmd_rx_started <= 1'b1;
			end
			if(cmd_tx_enabled|(cmd_rx_enabled & (cmd_rx_started|~mc_cmd_r2)))
				cmd_bitcount <= cmd_bitcount + 3'd1;
			if(cmd_bitcount == 3'd7) begin
				if(cmd_tx_enabled)
					cmd_tx_pending <= 1'b0;
				if(cmd_rx_enabled)
					cmd_rx_pending <= 1'b1;
			end

			if(dat_tx_enabled|dat_rx_started)
				dat_data <= {dat_data[27:0], mc_d_r2};
			if(dat_tx_enabled|dat_rx_started|(mc_d_r2 == 4'h0)) begin
				if(dat_rx_enabled)
					dat_rx_started <= 1'b1;
			end
			if(dat_tx_enabled|(dat_rx_enabled & dat_rx_started))
				dat_bitcount <= dat_bitcount + 3'd1;
			if(dat_bitcount == 3'd7) begin
				if(dat_tx_enabled)
					dat_tx_pending <= 1'b0;
				if(dat_rx_enabled)
					dat_rx_pending <= 1'b1;
			end
		end
	end
end

assign mc_cmd = cmd_tx_enabled ? cmd_data[7] : 1'bz;
assign mc_d = dat_tx_enabled ? dat_data[31:28] : 4'bzzzz;
assign mc_clk = clkdiv;

endmodule
