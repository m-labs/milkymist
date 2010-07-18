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

	input zpu_re,
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
	end else begin
		case(zpu_a[5:2])
			4'b0000: zpu_dat_o <= {6'd0, line_state_a, 24'd0};
			4'b0001: zpu_dat_o <= {6'd0, line_state_b, 24'd0};
			4'b0010: zpu_dat_o <= {7'd0, discon_a, 24'd0};
			4'b0011: zpu_dat_o <= {7'd0, discon_b, 24'd0};

			4'b0100: zpu_dat_o <= {7'd0, port_sel_rx, 24'd0};
			4'b0101: zpu_dat_o <= {6'd0, port_sel_tx, 24'd0};

			4'b0110: zpu_dat_o <= {utmi_data_out, 24'd0};
			4'b0111: zpu_dat_o <= {7'd0, tx_pending, 24'd0};
			4'b1000: zpu_dat_o <= {7'd0, utmi_tx_valid, 24'd0};
			4'b1001: zpu_dat_o <= {7'd0, generate_reset, 24'd0};

			4'b1010: begin
				zpu_dat_o <= {data_in, 24'd0};
				if(zpu_re)
					rx_pending <= 1'b0;
			end
			4'b1011: zpu_dat_o <= {7'd0, rx_pending, 24'd0};
			4'b1100: zpu_dat_o <= {7'd0, utmi_rx_active, 24'd0};
			4'b1101: zpu_dat_o <= {7'd0, rx_error, 24'd0};
		endcase
		if(zpu_re)
			$display("USB SIE R: a=%x dat=%x", zpu_a, zpu_dat_o);
		if(zpu_we) begin
			$display("USB SIE W: a=%x dat=%x", zpu_a, zpu_dat_i);
			case(zpu_a[5:2])
				4'b0100: port_sel_rx <= zpu_dat_i[24];
				4'b0101: port_sel_tx <= zpu_dat_i[25:24];
				4'b0110: begin
					utmi_tx_valid <= 1'b1;
					utmi_data_out <= zpu_dat_i[31:24];
					tx_pending <= 1'b1;
				end
				4'b1000: utmi_tx_valid <= 1'b0;
				4'b1001: generate_reset <= zpu_dat_i[24];
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
