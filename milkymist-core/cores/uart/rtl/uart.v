/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 *
 * This program is free and excepted software; you can use it, redistribute it
 * and/or modify it under the terms of the Exception General Public License as
 * published by the Exception License Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the Exception General Public License for more
 * details.
 *
 * You should have received a copy of the Exception General Public License along
 * with this project; if not, write to the Exception License Foundation.
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
wire rx_avail;
wire rx_error;
wire rx_ack;

wire [7:0] tx_data;
wire tx_wr;
wire tx_busy;

uart_transceiver transceiver(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.uart_rxd(uart_rxd),
	.uart_txd(uart_txd),

	.divisor(divisor),

	.rx_data(rx_data),
	.rx_avail(rx_avail),
	.rx_error(rx_error),
	.rx_ack(rx_ack),
	
	.tx_data(tx_data),
	.tx_wr(tx_wr),
	.tx_busy(tx_busy)
);

/* Generate tx_done signal */
wire tx_ack;
reg tx_busy_r;
reg tx_done;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		tx_busy_r <= 1'b0;
		tx_done <= 1'b0;
	end else begin
		tx_busy_r <= tx_busy;
		if(tx_ack|tx_wr)
			tx_done <= 1'b0;
		if(tx_busy_r & ~tx_busy)
			tx_done <= 1'b1;
	end
end

/* CSR interface */
wire csr_selected = csr_a[13:10] == csr_addr;

assign rx_ack = csr_selected & csr_we & (csr_a[1:0] == 2'b00) & csr_di[2];
assign tx_data = csr_di[7:0];
assign tx_wr = csr_selected & csr_we & (csr_a[1:0] == 2'b01);
assign tx_ack = csr_selected & csr_we & (csr_a[1:0] == 2'b00) & csr_di[5];

parameter default_divisor = clk_freq/baud/16;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		divisor <= default_divisor;
		csr_do <= 32'd0;
	end else begin
		csr_do <= 32'd0;
		if(csr_selected) begin
			case(csr_a[1:0])
				2'b00: csr_do <= {1'b0, tx_done, tx_busy, 1'b0, rx_error, rx_avail};
				2'b01: csr_do <= rx_data;
				2'b10: csr_do <= divisor;
			endcase
			if(csr_we) begin
				if(csr_a[1:0] == 2'b10)
					divisor <= csr_di[15:0];
			end
		end
	end
end

/* IRQs */
assign rx_irq = rx_avail|rx_error;
assign tx_irq = tx_done;

endmodule
