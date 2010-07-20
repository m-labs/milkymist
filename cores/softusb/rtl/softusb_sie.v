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

	input io_re,
	input io_we,
	input [5:0] io_a,
	input [7:0] io_di,
	output reg [7:0] io_do,

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

reg port_sel_rx;
reg [1:0] port_sel_tx;

reg [7:0] utmi_data_out;
reg utmi_tx_valid;
wire utmi_tx_ready;
reg tx_pending;

reg generate_reset;

wire [7:0] utmi_data_in;
wire utmi_rx_valid;
wire utmi_rx_active;
wire utmi_rx_error;

reg [7:0] data_in;
reg rx_pending;
reg utmi_rx_active_r;
reg rx_error;

always @(posedge usb_clk) begin
	if(usb_rst) begin
		port_sel_rx <= 1'b0;
		port_sel_tx <= 2'b00;
		utmi_tx_valid <= 1'b0;
		tx_pending <= 1'b0;
		generate_reset <= 1'b0;
		rx_pending <= 1'b0;
		utmi_rx_active_r <= 1'b0;
		rx_error <= 1'b0;
		io_do <= 8'd0;
	end else begin
		io_do <= 8'd0;
		case(io_a)
			6'h00: io_do <= line_state_a;
			6'h01: io_do <= line_state_b;
			6'h02: io_do <= discon_a;
			6'h03: io_do <= discon_b;

			6'h04: io_do <= port_sel_rx;
			6'h05: io_do <= port_sel_tx;

			6'h06: io_do <= utmi_data_out;
			6'h07: io_do <= tx_pending;
			6'h08: io_do <= utmi_tx_valid;
			6'h09: io_do <= generate_reset;

			6'h0a: begin
				io_do <= {data_in, 24'd0};
				if(io_re)
					rx_pending <= 1'b0;
			end
			6'h0b: io_do <= rx_pending;
			6'h0c: io_do <= utmi_rx_active;
			6'h0d: io_do <= rx_error;
			6'h0e, 6'h0f: io_do <= 8'hxx;
		endcase
		if(io_re)
			$display("USB SIE R: a=%x dat=%x", io_a, io_do);
		if(io_we) begin
			$display("USB SIE W: a=%x dat=%x", io_a, io_di);
			case(io_a)
				6'h04: port_sel_rx <= io_di[0];
				6'h05: port_sel_tx <= io_di[1:0];
				6'h06: begin
					utmi_tx_valid <= 1'b1;
					utmi_data_out <= io_di[1:0];
					tx_pending <= 1'b1;
				end
				6'h08: utmi_tx_valid <= 1'b0;
				6'h09: generate_reset <= io_di[0];
			endcase
		end
		if(utmi_tx_ready)
			tx_pending <= 1'b0;
		if(utmi_rx_valid) begin
			data_in <= utmi_data_in;
			rx_pending <= 1'b1;
		end

		utmi_rx_active_r <= utmi_rx_active;
		if(utmi_rx_active & ~utmi_rx_active_r)
			rx_error <= 1'b0;
		if(utmi_rx_active & utmi_rx_error)
			rx_error <= 1'b1;
	end
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

	.port_sel_rx(port_sel_rx),
	.port_sel_tx(port_sel_tx),

	.utmi_data_out(utmi_data_out),
	.utmi_tx_valid(utmi_tx_valid),
	.utmi_tx_ready(utmi_tx_ready),

	.generate_reset(generate_reset),
	
	.utmi_data_in(utmi_data_in),
	.utmi_rx_valid(utmi_rx_valid),
	.utmi_rx_active(utmi_rx_active),
	.utmi_rx_error(utmi_rx_error)
);

endmodule
