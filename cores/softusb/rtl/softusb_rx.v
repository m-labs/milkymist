/*
 * Milkymist SoC
 * Copyright (C) 2007, 2008, 2009, 2010, 2011 Sebastien Bourdeauducq
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

	input rx,
	input rxp,
	input rxm,

	output reg [7:0] rx_data,
	output reg rx_valid,
	output reg rx_active,
	output reg rx_error,

	input low_speed
);

wire rx_corrected = rx ^ low_speed;

/* EOP detection */

/*
 * State diagram taken from
 * "Designing a Robust USB Serial Interface Engine (SIE)"
 * USB-IF Technical White Paper
 */
wire se0 = ~rxp & ~rxm;

wire eop_state_ce;
reg [2:0] eop_state;
reg [2:0] eop_next_state;
always @(posedge usb_clk) begin
	if(rxreset)
		eop_state <= 3'd0;
	else if(eop_state_ce)
		eop_state <= eop_next_state;
end

reg [2:0] eop_clkdiv_counter;
assign eop_state_ce = ~low_speed | (eop_clkdiv_counter == 3'd0);
initial eop_clkdiv_counter <= 3'd0;
always @(posedge usb_clk)
	eop_clkdiv_counter <= eop_clkdiv_counter + 3'd1;


reg eop_detected;

always @(*) begin
	eop_detected = 1'b0;
	eop_next_state = eop_state;

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
				eop_next_state = 3'd4;
			else
				eop_next_state = 3'd0;
		end
		3'd4: begin
			if(se0)
				eop_next_state = 3'd5;
			else
				eop_next_state = 3'd0;
		end
		3'd5: begin
			if(se0)
				eop_next_state = 3'd5;
			else begin
				if(rx_corrected) begin
					eop_detected = 1'b1;
					eop_next_state = 3'd0;
				end else
					eop_next_state = 3'd6;
			end
		end
		3'd6: begin
			if(rx_corrected)
				eop_detected = 1'b1;
			eop_next_state = 3'd0;
		end
	endcase
end

/* DPLL */
reg [2:0] div8_counter;
reg div8_ce;
initial div8_counter <= 3'd0;
always @(posedge usb_clk) begin
	div8_counter <= div8_counter + 3'd1;
	div8_ce <= div8_counter == 3'd0;
end

wire speed_ce = ~low_speed | div8_ce;

reg [3:0] dpll_state;
reg [3:0] dpll_next_state;

always @(posedge usb_clk) begin
	if(rxreset)
		dpll_state <= 4'h5;
	else if(speed_ce)
		dpll_state <= dpll_next_state;
end

always @(*) begin
	dpll_next_state = dpll_state;
	case(dpll_state)
		4'h5: dpll_next_state = 4'hd;
		4'hd: dpll_next_state = 4'h7;
		4'h7: if( rx_corrected) dpll_next_state = 4'he; else dpll_next_state = 4'hb;
		4'he: dpll_next_state = 4'h6;
		4'h6: if( rx_corrected) dpll_next_state = 4'h4; else dpll_next_state = 4'h1;
		4'h4: if( rx_corrected) dpll_next_state = 4'h5; else dpll_next_state = 4'h1;
		4'h1: dpll_next_state = 4'h9;
		4'h9: dpll_next_state = 4'h3;
		4'h3: if(~rx_corrected) dpll_next_state = 4'ha; else dpll_next_state = 4'hf;
		4'ha: dpll_next_state = 4'h2;
		4'h2: if(~rx_corrected) dpll_next_state = 4'h0; else dpll_next_state = 4'h5;
		4'h0: if(~rx_corrected) dpll_next_state = 4'h1; else dpll_next_state = 4'h5;
		4'hb: dpll_next_state = 4'ha;
		4'hf: dpll_next_state = 4'he;
	endcase
end

wire dpll_ce = speed_ce & (dpll_next_state[1] & ~dpll_state[1]);

/* Serial->Parallel converter */

reg [2:0] bitcount;
reg [2:0] onecount;
reg lastrx;
reg startrx;
always @(posedge usb_clk) begin
	if(rxreset) begin
		rx_active <= 1'b0;
		rx_valid <= 1'b0;
		rx_error <= 1'b0;
	end else begin
		rx_valid <= 1'b0;
		rx_error <= 1'b0;
		if(eop_detected)
			rx_active <= 1'b0;
		else if(dpll_ce) begin
			if(rx_active & ~se0) begin
				if(onecount == 3'd6) begin
					/* skip stuffed bits */
					onecount <= 3'd0;
					if((lastrx & rx_corrected)|(~lastrx & ~rx_corrected)) begin
						/* no transition? bitstuff error */
						rx_active <= 1'b0;
						rx_error <= 1'b1;
					end
					lastrx <= ~lastrx;
				end else begin
					if(rx_corrected) begin
						rx_data <= {lastrx, rx_data[7:1]};
						if(lastrx)
							onecount <= onecount + 3'd1;
						else
							onecount <= 3'd0;
						lastrx <= 1'b1;
					end else begin
						rx_data <= {~lastrx, rx_data[7:1]};
						if(~lastrx)
							onecount <= onecount + 3'd1;
						else
							onecount <= 3'd0;
						lastrx <= 1'b0;
					end
					rx_valid <= bitcount == 3'd7;
					bitcount <= bitcount + 3'd1;
				end
			end else if(startrx) begin
				rx_active <= 1'b1;
				bitcount <= 3'd0;
				onecount <= 3'd1;
				lastrx <= 1'b0;
			end
		end
	end
end

/* Find sync pattern */

parameter FS_IDLE	= 4'h0;
parameter K1		= 4'h1;
parameter J1		= 4'h2;
parameter K2		= 4'h3;
parameter J2		= 4'h4;
parameter K3		= 4'h5;
parameter J3		= 4'h6;
parameter K4		= 4'h7;
parameter K5		= 4'h8;

reg [3:0] fs_state;
reg [3:0] fs_next_state;

reg [6:0] fs_timeout_counter;
reg fs_timeout;
always @(posedge usb_clk) begin
	if(rxreset|eop_detected) begin
		fs_timeout_counter <= 7'd0;
		fs_timeout <= 1'b0;
	end else begin
		if((fs_state != fs_next_state) | (fs_state == FS_IDLE))
			fs_timeout_counter <= 7'd0;
		else
			fs_timeout_counter <= fs_timeout_counter + 7'd1;
		if(low_speed)
			fs_timeout <= fs_timeout_counter == 7'd95;
		else
			fs_timeout <= fs_timeout_counter == 7'd11;
	end
end

always @(posedge usb_clk) begin
	if(rxreset|eop_detected|fs_timeout)
		fs_state <= FS_IDLE;
	else
		fs_state <= fs_next_state;
end

always @(*) begin
	startrx = 1'b0;
	fs_next_state = fs_state;

	case(fs_state)
		FS_IDLE: if(~rx_corrected & ~rx_active)
			fs_next_state = K1;
		K1: if(rx_corrected)
			fs_next_state = J1;
		J1: if(~rx_corrected)
			fs_next_state = K2;
		K2: if(rx_corrected)
			fs_next_state = J2;
		J2: if(~rx_corrected)
			fs_next_state = K3;
		K3: if(rx_corrected)
			fs_next_state = J3;
		J3: if(~rx_corrected)
			fs_next_state = K4;
		K4: if(dpll_ce) begin
			if(~rx_corrected)
				fs_next_state = K5;
			else
				fs_next_state = FS_IDLE;
		end
		K5: begin
			if(~rx_corrected)
				startrx = 1'b1;
			if(dpll_ce)
				fs_next_state = FS_IDLE;
		end
	endcase
end

endmodule
