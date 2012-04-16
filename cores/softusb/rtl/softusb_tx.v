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

module softusb_tx(
	input usb_clk,
	input usb_rst,

	input [7:0] tx_data,
	input tx_valid,
	output reg tx_ready,

	output reg txp,
	output reg txm,
	output reg txoe,

	input low_speed,
	input generate_eop
);

/* Register outputs */
reg txp_r;
reg txm_r;
reg txoe_r;
always @(posedge usb_clk) begin
	txp <= txp_r;
	txm <= txm_r;
	txoe <= txoe_r;
end

/* Clock 'divider' */
reg gce; /* global clock enable */
reg [5:0] gce_counter;
always @(posedge usb_clk) begin
	if(usb_rst) begin
		gce <= 1'b0;
		gce_counter <= 6'd0;
	end else begin
		gce <= 1'b0;
		gce_counter <= gce_counter + 6'd1;
		if((low_speed & gce_counter == 6'd47) | (~low_speed & gce_counter == 6'd5)) begin
			gce <= 1'b1;
			gce_counter <= 6'd0;
		end
	end
end

/* Shift register w/bit stuffing */
reg sr_rst;
reg sr_load;
reg sr_done;
reg sr_out;
reg [2:0] bitcount;
reg [2:0] onecount;
reg [6:0] sr;
always @(posedge usb_clk) begin
	if(sr_rst) begin
		sr_done <= 1'b1;
		onecount <= 3'd0;
		sr_out <= 1'b1;
	end else if(gce) begin
		if(sr_load) begin
			sr_done <= 1'b0;
			sr_out <= tx_data[0];
			bitcount <= 3'd0;
			if(tx_data[0])
				onecount <= onecount + 3'd1;
			else
				onecount <= 3'd0;
			sr <= tx_data[7:1];
		end else if(~sr_done) begin
			if(onecount == 3'd6) begin
				onecount <= 3'd0;
				sr_out <= 1'b0;
				if(bitcount == 3'd7)
					sr_done <= 1'b1;
			end else begin
				sr_out <= sr[0];
				if(sr[0])
					onecount <= onecount + 3'd1;
				else
					onecount <= 3'd0;
				bitcount <= bitcount + 3'd1;
				if((bitcount == 3'd6) & (~sr[0] | (onecount != 3'd5)))
					sr_done <= 1'b1;
				sr <= {1'b0, sr[6:1]};
			end
		end
	end
end

/* Output generation */
reg txoe_ctl;
reg generate_se0;
reg generate_j;

always @(posedge usb_clk) begin
	if(usb_rst) begin
		txoe_r <= 1'b0;
		txp_r <= ~low_speed;
		txm_r <= low_speed;
	end else if(gce) begin
		if(~txoe_ctl) begin
			txp_r <= ~low_speed; /* return to J */
			txm_r <= low_speed;
		end else begin
			case({generate_se0, generate_j})
				2'b00: begin
					if(~sr_out) begin
						txp_r <= ~txp_r;
						txm_r <= ~txm_r;
					end
				end
				2'b10: begin
					txp_r <= 1'b0;
					txm_r <= 1'b0;
				end
				2'b01: begin
					txp_r <= ~low_speed;
					txm_r <= low_speed;
				end
				default: begin
					txp_r <= 1'bx;
					txm_r <= 1'bx;
				end
			endcase
		end
		txoe_r <= txoe_ctl;
	end
end

/* Sequencer */

parameter IDLE		= 3'd0;
parameter DATA		= 3'd1;
parameter EOP1		= 3'd2;
parameter EOP2		= 3'd3;
parameter J		= 3'd4;
parameter GEOP1		= 3'd5;
parameter GEOP2		= 3'd6;
parameter GJ		= 3'd7;

reg [2:0] state;
reg [2:0] next_state;

always @(posedge usb_clk) begin
	if(usb_rst)
		state <= IDLE;
	else if(gce)
		state <= next_state;
end

reg tx_ready0;
always @(posedge usb_clk)
	tx_ready <= tx_ready0 & gce;

reg tx_valid_r;
reg transmission_continue;
reg transmission_end_ack;
always @(posedge usb_clk) begin
	if(usb_rst) begin
		tx_valid_r <= 1'b0;
		transmission_continue <= 1'b1;
	end else begin
		tx_valid_r <= tx_valid;
		if(tx_valid_r & ~tx_valid)
			transmission_continue <= 1'b0;
		if(transmission_end_ack)
			transmission_continue <= 1'b1;
	end
end

reg generate_eop_pending;
reg generate_eop_clear;
always @(posedge usb_clk) begin
	if(usb_rst)
		generate_eop_pending <= 1'b0;
	else begin
		if(generate_eop)
			generate_eop_pending <= 1'b1;
		if(generate_eop_clear)
			generate_eop_pending <= 1'b0;
	end
end

always @(*) begin
	txoe_ctl = 1'b0;
	sr_rst = 1'b0;
	sr_load = 1'b0;
	generate_se0 = 1'b0;
	generate_j = 1'b0;
	tx_ready0 = 1'b0;
	transmission_end_ack = 1'b0;
	generate_eop_clear = 1'b0;

	next_state = state;

	case(state)
		IDLE: begin
			txoe_ctl = 1'b0;
			if(generate_eop_pending)
				next_state = GEOP1;
			else begin
				if(tx_valid) begin
					sr_load = 1'b1;
					tx_ready0 = 1'b1;
					next_state = DATA;
				end else
					sr_rst = 1'b1;
			end
		end
		DATA: begin
			txoe_ctl = 1'b1;
			if(sr_done) begin
				if(transmission_continue) begin
					sr_load = 1'b1;
					tx_ready0 = 1'b1;
				end else
					next_state = EOP1;
			end
		end
		EOP1: begin
			transmission_end_ack = 1'b1;
			sr_rst = 1'b1;
			txoe_ctl = 1'b1;
			generate_se0 = 1'b1;
			next_state = EOP2;
		end
		EOP2: begin
			sr_rst = 1'b1;
			txoe_ctl = 1'b1;
			generate_se0 = 1'b1;
			next_state = J;
		end
		J: begin
			sr_rst = 1'b1;
			txoe_ctl = 1'b1;
			generate_j = 1'b1;
			next_state = IDLE;
		end
		GEOP1: begin
			sr_rst = 1'b1;
			txoe_ctl = 1'b1;
			generate_se0 = 1'b1;
			next_state = GEOP2;
		end
		GEOP2: begin
			sr_rst = 1'b1;
			txoe_ctl = 1'b1;
			generate_se0 = 1'b1;
			next_state = GJ;
		end
		GJ: begin
			generate_eop_clear = 1'b1;
			sr_rst = 1'b1;
			txoe_ctl = 1'b1;
			generate_j = 1'b1;
			next_state = IDLE;
		end
	endcase
end

endmodule
