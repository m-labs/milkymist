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

	output reg usba_discon,
	output reg usbb_discon,

	output [1:0] utmi_line_state_a,
	output [1:0] utmi_line_state_b,

	input port_sel_rx,
	input [1:0] port_sel_tx,

	input [7:0] utmi_data_out,
	input utmi_tx_valid,
	output utmi_tx_ready,

	input generate_reset,

	output [7:0] utmi_data_in,
	output utmi_rx_valid,
	output utmi_rx_active,
	output utmi_rx_error
);

/* RX synchronizer */

wire rcv_s_a;
wire vp_s_a;
wire vm_s_a;
softusb_filter filter_a(
	.usb_clk(usb_clk),

	.rcv(usba_rcv),
	.vp(usba_vp),
	.vm(usba_vm),

	.rcv_s(rxd_s_a),
	.vp_s(rxdp_s_a),
	.vm_s(rxdn_s_a)
);
assign utmi_line_state_a = {vm_s_a, vp_s_a};

wire rcv_s_b;
wire vp_s_b;
wire vm_s_b;
softusb_filter filter_b(
	.usb_clk(usb_clk),

	.rcv(usbb_rcv),
	.vp(usbb_vp),
	.vm(usbb_vm),

	.rcv_s(rcv_s_b),
	.vp_s(vp_s_b),
	.vm_s(vm_s_b)
);
assign utmi_line_state_b = {vm_s_b, vp_s_b};

/* TX section */

wire txoe;

// TODO

/* RX section */

// TODO

/* Tri-state enables and drivers */

wire txoe_a = txoe & port_sel_tx[0];
wire txoe_b = txoe & port_sel_tx[1];

assign usba_oe_n = ~txoe_a;
assign usba_vp = txoe_a ? txdp : 1'bz;
assign usba_vm = txoe_a ? txdn : 1'bz;
assign usbb_oe_n = ~txoe_b;
assign usbb_vp = txoe_b ? txdp : 1'bz;
assign usbb_vm = txoe_b ? txdn : 1'bz;

/* Assert USB disconnect if we see SE0 for at least 2.5us */

reg [4:0] usba_discon_cnt;
always @(posedge usb_clk) begin
	if(usb_rst) begin
		usba_discon_cnt <= 5'h0;
		usba_discon <= 1'b0;
	end else begin
		if(utmi_line_state_a != 2'h0)
			usba_discon_cnt <= 5'h0;
		else if(!usba_discon && fs_ce)
			usba_discon_cnt <= usba_discon_cnt + 5'h1;
		usba_discon <= (usba_discon_cnt == 5'h1f);
	end
end

reg [4:0] usbb_discon_cnt;
always @(posedge usb_clk) begin
	if(usb_rst) begin
		usbb_discon_cnt <= 5'h0;
		usbb_discon <= 1'b0;
	end else begin
		if(utmi_line_state_b != 2'h0)
			usbb_discon_cnt <= 5'h0;
		else if(!usbb_discon && fs_ce)
			usbb_discon_cnt <= usbb_discon_cnt + 5'h1;
		usbb_discon <= (usbb_discon_cnt == 5'h1f);
	end
end

/* FIXME: full speed only for now */
assign usba_spd = 1'b1;
assign usbb_spd = 1'b1;

endmodule
