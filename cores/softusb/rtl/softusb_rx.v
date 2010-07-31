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

module softusb_rx(
	input usb_clk,
	input usb_rst,

	input rxen,

	input rxp,
	input rxm,

	output reg [7:0] rx_data,
	output reg rx_valid,
	output reg rx_active
);

/*
 * Ignore incoming signals when disabled.
 * If rxen goes low while the RX is idle, nothing happens.
 * If rxen goes low in the middle of a packet reception,
 * a bit-stuff error will be detected in at most 6 cycles
 * of the bit clock and RX will stop.
 */
reg rxp_r;
reg rxm_r;
always @(posedge usb_clk) begin
	if(rxen) begin
		rxp_r <= rxp;
		rxm_r <= rxm;
	end
end

/* DPLL */
wire data = rxp_r;
wire data_valid = rxp_r != rxm_r;
reg data_r;
always @(posedge usb_clk) begin
	if(data_valid)
		data_r <= data;
end
wire transition = data_valid & (data != data_r);

reg [1:0] dpll_counter;
reg dpll_ce;
always @(posedge usb_clk) begin
	if(usb_rst)
		dpll_counter <= 2'd0;
	else begin
		if(transition)
			dpll_counter <= 2'd0;
		else
			dpll_counter <= dpll_counter + 2'd1;
		dpll_ce <= dpll_counter == 2'd0;
	end
end

/* EOP detection */

/*
 * State diagram taken from
 * "Designing a Robust USB Serial Interface Engine (SIE)"
 * USB-IF Technical White Paper
 */
wire j = rxp_r & ~rxm_r;
wire k = ~rxp_r & rxm_r;
wire se0 = ~rxp_r & ~rxm_r;

reg [2:0] eop_state;
reg [2:0] eop_next_state;
always @(posedge usb_clk) begin
	if(usb_rst)
		eop_state <= 3'd0;
	else
		eop_state <= eop_next_state;
end

reg eop_detected;

always @(*) begin
	eop_detected = 1'b0;

	case(eop_state)
		3'd0: begin
			if(se0)
				eop_next_state = 3'd1;
			else
				eop_next_state = 3'd0;
		end
		3'd1: begin
			if(se0)
				eop_next_state = 3'd2;
			else
				eop_next_state = 3'd0;
		end
		3'd2: begin
			if(se0)
				eop_next_state = 3'd3;
			else
				eop_next_state = 3'd0;
		end
		3'd3: begin
			if(se0)
				eop_next_state = 3'd3;
			else begin
				if(j) begin
					eop_detected = 1'b1;
					eop_next_state = 3'd0;
				end else
					eop_next_state = 3'd4;
			end
		end
		3'd4: begin
			if(j)
				eop_detected = 1'b1;
			eop_next_state = 3'd0;
		end
	endcase
end

/* Serial->Parallel converter */

reg [2:0] bitcount;
reg [2:0] onecount;
reg lastrx;
always @(posedge usb_clk) begin
	if(usb_rst) begin
		bitcount = 3'd0;
		onecount = 3'd0;
	end else begin
		rx_valid = 1'b0;
		if(eop_detected)
			rx_active = 1'b0;
		else if(dpll_ce) begin
			if(rx_active & ~se0) begin
				if(onecount == 3'd6) begin
					/* skip stuffed bits */
					onecount = 3'd0;
					if((lastrx & ~k)|(~lastrx & ~j))
						/* no transition? bitstuff error */
						rx_active = 1'b0;
					lastrx = ~lastrx;
				end else begin
					if(j) begin
						rx_data = {lastrx, rx_data[7:1]};
						if(lastrx)
							onecount = onecount + 3'd1;
						else
							onecount = 3'd0;
						lastrx = 1'b1;
					end
					if(k) begin
						rx_data = {~lastrx, rx_data[7:1]};
						if(~lastrx)
							onecount = onecount + 3'd1;
						else
							onecount = 3'd0;
						lastrx = 1'b0;
					end
					bitcount = bitcount + 3'd1;
					rx_valid = bitcount == 3'd7;
				end
			end else begin
				if(k) begin
					rx_active = 1'b1;
					rx_data = {1'b0, rx_data[7:1]};
					bitcount = 3'd0;
					onecount = 3'd0;
					lastrx = 1'b0;
				end
			end
		end
	end
end

endmodule
