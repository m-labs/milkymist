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

	output usba_discon,
	output usbb_discon,

	output [1:0] line_state_a,
	output [1:0] line_state_b,

	input port_sel_rx,
	input [1:0] port_sel_tx,

	input [7:0] tx_data,
	input tx_valid,
	output tx_ready,

	input generate_reset,

	output [7:0] rx_data,
	output rx_valid,
	output rx_active
);

/* RX synchronizer */

wire vp_s_a;
wire vm_s_a;
softusb_filter filter_a(
	.usb_clk(usb_clk),

	.vp(usba_vp),
	.vm(usba_vm),

	.vp_s(rxdp_s_a),
	.vm_s(rxdn_s_a)
);
assign line_state_a = {vm_s_a, vp_s_a};

wire vp_s_b;
wire vm_s_b;
softusb_filter filter_b(
	.usb_clk(usb_clk),

	.vp(usbb_vp),
	.vm(usbb_vm),

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

	.generate_reset(generate_reset),

	.txp(txp),
	.txm(txm),
	.txoe(txoe)
);

/* RX section */

softusb_rx rx(
	.usb_clk(usb_clk),

	.rxreset(txoe),

	.rxp(port_sel_rx ? usbb_vp : usba_vp),
	.rxm(port_sel_rx ? usbb_vm : usba_vm),

	.rx_data(rx_data),
	.rx_valid(rx_valid),
	.rx_active(rx_active)
);

/* Tri-state enables and drivers */

wire txoe_a = txoe & port_sel_tx[0];
wire txoe_b = txoe & port_sel_tx[1];

assign usba_oe_n = ~txoe_a;
assign usba_vp = txoe_a ? txp : 1'bz;
assign usba_vm = txoe_a ? txm : 1'bz;
assign usbb_oe_n = ~txoe_b;
assign usbb_vp = txoe_b ? txp : 1'bz;
assign usbb_vm = txoe_b ? txm : 1'bz;

/* Assert USB disconnect if we see SE0 for at least 2.5us */

reg [6:0] usba_discon_cnt;
assign usba_discon = (usba_discon_cnt == 7'd127);
always @(posedge usb_clk) begin
	if(usb_rst)
		usba_discon_cnt <= 7'd0;
	else begin
		if(line_state_a != 7'd0)
			usba_discon_cnt <= 7'd0;
		else if(~usba_discon)
			usba_discon_cnt <= usba_discon_cnt + 7'd1;
	end
end

reg [6:0] usbb_discon_cnt;
assign usbb_discon = (usbb_discon_cnt == 7'd127);
always @(posedge usb_clk) begin
	if(usb_rst)
		usbb_discon_cnt <= 7'd0;
	else begin
		if(line_state_b != 2'h0)
			usbb_discon_cnt <= 7'd0;
		else if(~usbb_discon)
			usbb_discon_cnt <= usbb_discon_cnt + 7'd1;
	end
end

/* FIXME: full speed only for now */
assign usba_spd = 1'b1;
assign usbb_spd = 1'b1;

endmodule
