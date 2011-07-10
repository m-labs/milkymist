/*
 * Milkymist SoC
 * Copyright (C) 2007, 2008, 2009, 2010, 2011 Sebastien Bourdeauducq
 * Copyright (C) 2007 Das Labor
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

module rc5 #(
	parameter csr_addr = 4'h0,
	parameter clk_freq = 100000000
) (
	input sys_clk,
	input sys_rst,

	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output reg [31:0] csr_do,

	output reg rx_irq,

	input rx
);

//-----------------------------------------------------------------
// enable16 generator
//-----------------------------------------------------------------
parameter divisor = clk_freq/596/16;

reg [15:0] enable16_counter;

wire enable16;
assign enable16 = (enable16_counter == 16'd0);

always @(posedge sys_clk) begin
	if(sys_rst)
		enable16_counter <= divisor - 1;
	else begin
		enable16_counter <= enable16_counter - 16'd1;
		if(enable16)
			enable16_counter <= divisor - 1;
	end
end

//-----------------------------------------------------------------
// Synchronize rx
//-----------------------------------------------------------------
reg rx1;
reg rx2;

always @(posedge sys_clk) begin
	rx1 <= rx;
	rx2 <= rx1;
end

//-----------------------------------------------------------------
// RX Logic
//-----------------------------------------------------------------
reg rx_busy;
reg [3:0] rx_count16;
reg [3:0] rx_bitcount;
reg [12:0] rx_reg;
reg [12:0] rx_data;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		rx_irq <= 1'b0;
		rx_busy <= 1'b0;
		rx_count16 <= 4'd0;
		rx_bitcount <= 4'd0;
	end else begin
		rx_irq <= 1'b0;

		if(enable16) begin
			if(~rx_busy) begin // look for start bit
				if(rx2) begin // start bit found
					rx_busy <= 1'b1;
					rx_count16 <= 4'd13;
					rx_bitcount <= 4'd0;
				end
			end else begin
				rx_count16 <= rx_count16 + 4'd1;

				if(rx_count16 == 4'd0) begin // sample
					rx_bitcount <= rx_bitcount + 4'd1;

					if(rx_bitcount == 4'd0) begin // verify startbit
						if(~rx2)
							rx_busy <= 1'b0;
					end else if(rx_bitcount == 4'd14) begin
						rx_busy <= 1'b0;
						rx_data <= rx_reg;
						rx_irq <= 1'b1;
					end else
						rx_reg <= {rx_reg[11:0], rx2};
				end
			end
		end
	end
end

//-----------------------------------------------------------------
// CSR interface
//-----------------------------------------------------------------

wire csr_selected = csr_a[13:10] == csr_addr;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		csr_do <= 32'd0;
	end else begin
		csr_do <= 32'd0;
		if(csr_selected)
			csr_do <= rx_data;
	end
end

endmodule
