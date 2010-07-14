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

module softusb_sie(
	input usb_clk,
	input usb_rst,

	input zpu_we,
	input [31:0] zpu_a,
	input [31:0] zpu_dat_i,
	output reg [31:0] zpu_dat_o,

	output usba_spd,
	output usba_oe_n,
	input usba_rcv,
	inout usba_vp,
	inout usba_vm,

	output usbb_spd,
	output usbb_oe_n,
	input usbb_rcv,
	inout usbb_vp,
	inout usbb_vm
);

wire [1:0] line_state_a;
wire [1:0] line_state_b;

wire discon_a;
wire discon_b;

always @(posedge usb_clk) begin
	case(zpu_a[2])
		1'b0: zpu_dat_o[31:24] <= line_state_a;
		1'b1: zpu_dat_o[31:24] <= line_state_b;
	endcase
end

softusb_phy phy(
	.usb_clk(usb_clk),
	.usb_rst(usb_rst),

	.usba_spd(usba_spd),
	.usba_oe_n(usba_oe_n),
	.usba_rcv(usba_rcv),
	.usba_vp(usba_vp),
	.usba_vm(usba_vm),

	.usbb_spd(usbb_spd),
	.usbb_oe_n(usbb_oe_n),
	.usbb_rcv(usbb_rcv),
	.usbb_vp(usbb_vp),
	.usbb_vm(usbb_vm),

	.usba_discon(discon_a),
	.usbb_discon(discon_b),

	.utmi_line_state_a(line_state_a),
	.utmi_line_state_b(line_state_b),

	.port_sel_rx(1'b0),
	.port_sel_tx(2'b00),

	.utmi_data_out(8'h0),
	.utmi_tx_valid(1'b0),
	.utmi_tx_ready(),
	.utmi_data_in(),
	.utmi_rx_valid(),
	.utmi_rx_active(),
	.utmi_rx_error()
);

endmodule
