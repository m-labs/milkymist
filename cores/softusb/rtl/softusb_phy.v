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

module softusb_phy(
	input usb_clk,
	input usb_rst,

	output usba_spd,
	output usba_oe_n,
	input usba_rcv,
	inout usba_vp,
	inout usba_vm,

	output usbb_spd,
	output usbb_oe_n,
	input usbb_rcv,
	inout usbb_vp,
	inout usbb_vm,

	output [1:0] line_state_a,
	output [1:0] line_state_b,

	input port_sel_rx,
	input [1:0] port_sel_tx,

	input [7:0] tx_data,
	input tx_valid,
	output tx_ready, /* data acknowledgment */
	output reg tx_busy, /* busy generating EOP, sending data, etc. */

	input [1:0] generate_reset,

	output [7:0] rx_data,
	output rx_valid,
	output rx_active,
	output rx_error,

	input tx_low_speed,
	input [1:0] low_speed,
	input generate_eop
);

/* RX synchronizer */

wire vp_s_a;
wire vm_s_a;
wire rcv_s_a;
softusb_filter filter_a(
	.usb_clk(usb_clk),

	.rcv(usba_rcv),
	.vp(usba_vp),
	.vm(usba_vm),

	.rcv_s(rcv_s_a),
	.vp_s(vp_s_a),
	.vm_s(vm_s_a)
);
assign line_state_a = {vm_s_a, vp_s_a};

wire vp_s_b;
wire vm_s_b;
wire rcv_s_b;
softusb_filter filter_b(
	.usb_clk(usb_clk),

	.rcv(usbb_rcv),
	.vp(usbb_vp),
	.vm(usbb_vm),

	.rcv_s(rcv_s_b),
	.vp_s(vp_s_b),
	.vm_s(vm_s_b)
);
assign line_state_b = {vm_s_b, vp_s_b};

/* TX section */

wire txp;
wire txm;
wire txoe;

softusb_tx tx(
	.usb_clk(usb_clk),
	.usb_rst(usb_rst),

	.tx_data(tx_data),
	.tx_valid(tx_valid),
	.tx_ready(tx_ready),

	.txp(txp),
	.txm(txm),
	.txoe(txoe),
	.low_speed(tx_low_speed),
	.generate_eop(generate_eop)
);

reg txoe_r;
always @(posedge usb_clk) begin
	if(usb_rst) begin
		txoe_r <= 1'b0;
		tx_busy <= 1'b0;
	end else begin
		txoe_r <= txoe;
		if(txoe_r & ~txoe)
			tx_busy <= 1'b0;
		if(generate_eop | tx_valid)
			tx_busy <= 1'b1;
	end
end

/* RX section */
softusb_rx rx(
	.usb_clk(usb_clk),

	.rxreset(txoe),

	.rx(port_sel_rx ? rcv_s_b : rcv_s_a),
	.rxp(port_sel_rx ? vp_s_b : vp_s_a),
	.rxm(port_sel_rx ? vm_s_b : vm_s_a),

	.rx_data(rx_data),
	.rx_valid(rx_valid),
	.rx_active(rx_active),
	.rx_error(rx_error),

	.low_speed(port_sel_rx ? low_speed[1] : low_speed[0])
);

/* Tri-state enables and drivers */

wire txoe_a = (txoe & port_sel_tx[0])|generate_reset[0];
wire txoe_b = (txoe & port_sel_tx[1])|generate_reset[1];

assign usba_oe_n = ~txoe_a;
assign usba_vp = txoe_a ? (generate_reset[0] ? 1'b0 : txp) : 1'bz;
assign usba_vm = txoe_a ? (generate_reset[0] ? 1'b0 : txm) : 1'bz;
assign usbb_oe_n = ~txoe_b;
assign usbb_vp = txoe_b ? (generate_reset[1] ? 1'b0 : txp) : 1'bz;
assign usbb_vm = txoe_b ? (generate_reset[1] ? 1'b0 : txm) : 1'bz;

assign usba_spd = ~low_speed[0];
assign usbb_spd = ~low_speed[1];

endmodule
