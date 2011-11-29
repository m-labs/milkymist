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

reg port_sel_rx;
reg [1:0] port_sel_tx;

reg [7:0] tx_data;
reg tx_valid;
wire tx_ready;
reg tx_pending;

reg [1:0] generate_reset;

wire [7:0] rx_data;
wire rx_valid;
wire rx_active;
wire rx_error;
reg rx_error_pending;
wire tx_busy;

reg [7:0] data_in;
reg rx_pending;

reg tx_low_speed;
reg [1:0] low_speed;

always @(posedge usb_clk) begin
	if(usb_rst) begin
		port_sel_rx <= 1'b0;
		port_sel_tx <= 2'b00;
		tx_valid <= 1'b0;
		tx_pending <= 1'b0;
		generate_reset <= 2'd0;
		rx_error_pending <= 1'b0;
		rx_pending <= 1'b0;
		tx_low_speed <= 1'b0;
		low_speed <= 2'b00;
		io_do <= 8'd0;
	end else begin
		io_do <= 8'd0;
		case(io_a)
			6'h00: io_do <= line_state_a;
			6'h01: io_do <= line_state_b;

			6'h02: io_do <= port_sel_rx;
			6'h03: io_do <= port_sel_tx;

			6'h04: io_do <= tx_data;
			6'h05: io_do <= tx_pending;
			6'h06: io_do <= tx_valid;
			6'h07: io_do <= tx_busy;
			6'h08: io_do <= generate_reset;

			6'h09: begin
				io_do <= data_in;
				if(io_re)
					rx_pending <= 1'b0;
			end
			6'h0a: io_do <= { rx_pending, rx_active };
			6'h0b: io_do <= rx_active;
			6'h0c: begin
				io_do <= rx_error_pending;
				if(io_re)
					rx_error_pending <= 1'b0;
			end
			
			6'h0d: io_do <= tx_low_speed;
			6'h0e: io_do <= low_speed;
			6'h0f: io_do <= 8'hxx;
		endcase
		if(io_we) begin
			$display("USB SIE W: a=%x dat=%x", io_a, io_di);
			case(io_a)
				6'h02: port_sel_rx <= io_di[0];
				6'h03: port_sel_tx <= io_di[1:0];
				6'h04: begin
					tx_valid <= 1'b1;
					tx_data <= io_di;
					tx_pending <= 1'b1;
				end
				6'h06: tx_valid <= 1'b0;
				6'h08: generate_reset <= io_di[1:0];
				6'h0d: tx_low_speed <= io_di[0];
				6'h0e: low_speed <= io_di[1:0];
				// 6'h0f is Generate EOP, handled separately
			endcase
		end
		if(tx_ready)
			tx_pending <= 1'b0;
		if(rx_valid) begin
			data_in <= rx_data;
			rx_pending <= 1'b1;
		end
		if(rx_error)
			rx_error_pending <= 1'b1;

		if(io_re) // must be at the end because of the delay!
			#1 $display("USB SIE R: a=%x dat=%x", io_a, io_do);
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

	.line_state_a(line_state_a),
	.line_state_b(line_state_b),

	.port_sel_rx(port_sel_rx),
	.port_sel_tx(port_sel_tx),

	.tx_data(tx_data),
	.tx_valid(tx_valid),
	.tx_ready(tx_ready),
	.tx_busy(tx_busy),

	.generate_reset(generate_reset),
	
	.rx_data(rx_data),
	.rx_valid(rx_valid),
	.rx_active(rx_active),
	.rx_error(rx_error),

	.tx_low_speed(tx_low_speed),
	.low_speed(low_speed),
	.generate_eop(io_we & (io_a == 6'h0f))
);

endmodule
