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

module tb_sie();

reg usb_clk;
initial usb_clk = 1'b0;
always #10 usb_clk = ~usb_clk;
reg usb_rst;

task waitclock;
begin
	@(posedge usb_clk);
	#1;
end
endtask

reg [7:0] tx_data;
reg tx_valid;
wire tx_ready;
wire txp;
wire txm;
wire txoe;
softusb_tx tx(
	.usb_clk(usb_clk),
	.usb_rst(usb_rst),

	.tx_data(tx_data),
	.tx_valid(tx_valid),
	.tx_ready(tx_ready),

	.generate_reset(1'b0),

	.txp(txp),
	.txm(txm),
	.txoe(txoe)
);

reg rxreset;
softusb_rx rx(
	.usb_clk(usb_clk),

	.rxreset(rxreset),

	.rxp(txp),
	.rxm(txm),

	.rx_data(),
	.rx_valid(),
	.rx_active()
);

initial begin
	$dumpfile("softusb_sie.vcd");
	$dumpvars(0, tx);
	$dumpvars(0, rx);

	usb_rst = 1'b1;
	rxreset = 1'b1;
	tx_valid = 1'b0;
	waitclock;
	waitclock;
	usb_rst = 1'b0;

	@(posedge usb_clk);
	@(posedge usb_clk);
	@(posedge usb_clk);
	@(posedge usb_clk);
	@(posedge usb_clk);
	@(posedge usb_clk);
	@(posedge usb_clk);
	@(posedge usb_clk);

	rxreset = 1'b0;
	tx_data = 8'h80;
	tx_valid = 1'b1;
	#300;
	tx_data = 8'h2d;
	#900;
	tx_valid = 1'b0;
	#4000;
	$finish;
end

endmodule
