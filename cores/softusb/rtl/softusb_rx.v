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

	input rxreset,

	input rxp,
	input rxm,

	output reg [7:0] rx_data,
	output reg rx_valid,
	output reg rx_active
);

/* DPLL */
wire data = rxp;
wire data_valid = rxp != rxm;
reg data_r;
always @(posedge usb_clk) begin
	if(data_valid)
		data_r <= data;
end
wire transition = data_valid & (data != data_r);

reg [1:0] dpll_counter;
reg dpll_ce;
always @(posedge usb_clk) begin
	if(rxreset) begin
		dpll_counter <= 2'd0;
		dpll_ce <= 1'b0;
	end else begin
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
wire j = rxp & ~rxm;
wire k = ~rxp & rxm;
wire se0 = ~rxp & ~rxm;

reg [2:0] eop_state;
reg [2:0] eop_next_state;
always @(posedge usb_clk) begin
	if(rxreset)
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
reg startrx;
always @(posedge usb_clk) begin
	if(rxreset) begin
		rx_active = 1'b0;
		rx_valid = 1'b0;
	end else begin
		rx_valid = 1'b0;
		if(eop_detected)
			rx_active = 1'b0;
		else if(dpll_ce) begin
			if(rx_active) begin
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
					end else begin
						rx_data = {~lastrx, rx_data[7:1]};
						if(~lastrx)
							onecount = onecount + 3'd1;
						else
							onecount = 3'd0;
						lastrx = 1'b0;
					end
					rx_valid = bitcount == 3'd7;
					bitcount = bitcount + 3'd1;
				end
			end else if(startrx) begin
				rx_active = 1'b1;
				bitcount = 3'd0;
				onecount = 3'd1;
				lastrx = 1'b0;
			end
		end
	end
end

/* Find sync pattern */

parameter FS_IDLE	= 3'h0;
parameter K1		= 3'h1;
parameter J1		= 3'h2;
parameter K2		= 3'h3;
parameter J2		= 3'h4;
parameter K3		= 3'h5;
parameter J3		= 3'h6;
parameter K4		= 3'h7;

reg [2:0] fs_state;
reg [2:0] fs_next_state;

always @(posedge usb_clk) begin
	if(rxreset)
		fs_state <= FS_IDLE;
	else if(dpll_ce)
		fs_state <= fs_next_state;
end

always @(*) begin
	startrx = 1'b0;
	fs_next_state = fs_state;

	case(fs_state)
		FS_IDLE: begin
			if(k & ~rx_active)
				fs_next_state = K1;
		end
		K1: begin
			if(j)
				fs_next_state = J1;
			else
				fs_next_state = FS_IDLE;
		end
		J1: begin
			if(k)
				fs_next_state = K2;
			else
				fs_next_state = FS_IDLE;
		end
		K2: begin
			if(j)
				fs_next_state = J2;
			else
				fs_next_state = FS_IDLE;
		end
		J2: begin
			if(k)
				fs_next_state = K3;
			else
				fs_next_state = FS_IDLE;
		end
		K3: begin
			if(j)
				fs_next_state = J3;
			else if(k) begin
				fs_next_state = FS_IDLE; /* first bit may have been missed */
				startrx = 1'b1;
			end else
				fs_next_state = FS_IDLE;
		end
		J3: begin
			if(k)
				fs_next_state = K4;
			else
				fs_next_state = FS_IDLE;
		end
		K4: begin
			if(k)
				startrx = 1'b1;
			fs_next_state = FS_IDLE;
		end
	endcase
end

endmodule
