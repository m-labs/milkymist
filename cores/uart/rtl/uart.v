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

module uart #(
	parameter csr_addr = 4'h0,
	parameter clk_freq = 100000000,
	parameter baud = 115200
) (
	input sys_clk,
	input sys_rst,
	
	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output reg [31:0] csr_do,

	output rx_irq,
	output tx_irq,

	input uart_rxd,
	output uart_txd
);

reg [15:0] divisor;
wire [7:0] rx_data;
wire [7:0] tx_data;
wire tx_wr;

uart_transceiver transceiver(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.uart_rxd(uart_rxd),
	.uart_txd(uart_txd),

	.divisor(divisor),

	.rx_data(rx_data),
	.rx_done(rx_irq),

	.tx_data(tx_data),
	.tx_wr(tx_wr),
	.tx_done(tx_irq)
);

/* CSR interface */
wire csr_selected = csr_a[13:10] == csr_addr;

assign tx_data = csr_di[7:0];
assign tx_wr = csr_selected & csr_we & (csr_a[0] == 1'b0);

parameter default_divisor = clk_freq/baud/16;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		divisor <= default_divisor;
		csr_do <= 32'd0;
	end else begin
		csr_do <= 32'd0;
		if(csr_selected) begin
			case(csr_a[0])
				1'b0: csr_do <= rx_data;
				1'b1: csr_do <= divisor;
			endcase
			if(csr_we) begin
				if(csr_a[0] == 1'b1)
					divisor <= csr_di[15:0];
			end
		end
	end
end

endmodule
