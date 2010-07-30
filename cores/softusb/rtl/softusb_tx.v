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

module softusb_tx(
	input usb_clk,
	input usb_rst,

	input [7:0] tx_data,
	input tx_valid,
	output reg tx_ready,

	input generate_reset,

	output reg txp,
	output reg txm,
	output reg txoe
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
reg [1:0] gce_counter;
always @(posedge usb_clk) begin
	if(usb_rst) begin
		gce <= 1'b0;
		gce_counter <= 2'd0;
	end else begin
		gce <= gce_counter == 2'd3;
		gce_counter <= gce_counter + 2'd1;
	end
end

/* Shift register w/bit stuffing */
reg sr_load;
reg sr_done;
reg sr_out;
reg [2:0] bitcount;
reg [2:0] onecount;
reg [6:0] sr;
always @(posedge usb_clk) begin
	if(usb_rst)
		sr_done <= 1'b1;
	else if(gce) begin
		if(sr_load) begin
			sr_done <= 1'b0;
			sr_out <= tx_data[0];
			bitcount <= 3'd0;
			if(tx_data[0])
				onecount <= 1'b1;
			else
				onecount <= 1'b0;
			sr <= tx_data[7:1];
		end else if(~sr_done) begin
			if(onecount == 3'd6) begin
				onecount <= 3'd0;
				sr_out <= 1'b0;
				if(bitcount == 3'd7)
					sr_done <= 1'b1;
			end else begin
				sr <= {1'b0, sr[6:1]};
				sr_out <= sr[0];
				if(sr[0])
					onecount <= onecount + 3'd1;
				bitcount <= bitcount + 3'd1;
				if((bitcount == 3'd7) & (~sr[0] | (onecount != 3'd5)))
					sr_done <= 1'b1;
			end
		end
	end
end

/* Output generation */
reg txoe_ctl;
reg generate_se0;
reg generate_j;

always @(posedge usb_clk) begin
	if(gce) begin
		if(~txoe_ctl) begin
			txp_r <= 1'b1; /* return to J */
			txm_r <= 1'b0;
		end else begin
			case({generate_reset, generate_se0, generate_j})
				3'b000: begin
					if(~sr_out) begin
						txp_r <= ~txp_r;
						txm_r <= ~txm_r;
					end
				end
				3'b100,
				3'b010: begin
					txp_r <= 1'b0;
					txm_r <= 1'b0;
				end
				3'b001: begin
					txp_r <= 1'b1;
					txm_r <= 1'b0;
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

reg [2:0] state;
reg [2:0] next_state;

always @(posedge usb_clk) begin
	if(usb_rst)
		state <= IDLE;
	else if(gce)
		state <= next_state;
end

always @(*) begin
	txoe_ctl = 1'b0;
	sr_load = 1'b0;
	generate_se0 = 1'b0;
	generate_j = 1'b0;
	tx_ready = 1'b0;

	next_state = state;

	case(state)
		IDLE: begin
			txoe_ctl = generate_reset;
			sr_load = tx_valid;
			if(tx_valid)
				next_state = DATA;
			tx_ready = 1'b1;
		end
		DATA: begin
			txoe_ctl = 1'b1;
			if(sr_done) begin
				tx_ready = 1'b1;
				if(tx_valid)
					sr_load = 1'b1;
				else
					next_state = EOP1;
			end
		end
		EOP1: begin
			txoe_ctl = 1'b1;
			generate_se0 = 1'b1;
			next_state = EOP2;
		end
		EOP2: begin
			txoe_ctl = 1'b1;
			generate_se0 = 1'b1;
			next_state = J;
		end
		J: begin
			txoe_ctl = 1'b1;
			generate_j = 1'b1;
			next_state = IDLE;
		end
	endcase
end

endmodule
