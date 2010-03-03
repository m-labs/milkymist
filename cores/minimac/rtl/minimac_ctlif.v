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

module minimac_ctlif #(
	parameter csr_addr = 4'h0
) (
	input sys_clk,
	input sys_rst,

	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output reg [31:0] csr_do,

	output reg irq_rx,
	output reg irq_tx,

	output reg rx_rst,
	output reg tx_rst,

	output rx_valid,
	output [29:0] rx_adr,
	input rx_resetcount,
	input rx_incrcount,
	input rx_endframe,
	input fifo_full,

	output tx_valid,
	output reg [29:0] tx_adr,
	output reg [1:0] tx_bytecount,
	input tx_next,

	output reg phy_mii_clk,
	inout phy_mii_data
);

reg mii_data_oe;
reg mii_data_do;
assign phy_mii_data = mii_data_oe ? mii_data_do : 1'bz;

/* Be paranoid about metastability */
reg mii_data_di1;
reg mii_data_di;
always @(posedge sys_clk) begin
	mii_data_di1 <= phy_mii_data;
	mii_data_di <= mii_data_di1;
end

/*
 * RX Slots
 *
 * State:
 * 00 -> slot is not in use
 * 01 -> slot has been loaded with a buffer
 * 10 -> slot has received a packet
 * 11 -> invalid
 */
reg [1:0] slot0_state;
reg [29:0] slot0_adr;
reg [10:0] slot0_count;
reg [1:0] slot1_state;
reg [29:0] slot1_adr;
reg [10:0] slot1_count;
reg [1:0] slot2_state;
reg [29:0] slot2_adr;
reg [10:0] slot2_count;
reg [1:0] slot3_state;
reg [29:0] slot3_adr;
reg [10:0] slot3_count;

wire select0 = slot0_state[0];
wire select1 = slot1_state[0] & ~slot0_state[0];
wire select2 = slot2_state[0] & ~slot1_state[0] & ~slot0_state[0];
wire select3 = slot3_state[0] & ~slot2_state[0] & ~slot1_state[0] & ~slot0_state[0];

assign rx_valid = slot0_state[0] | slot1_state[0] | slot2_state[0] | slot3_state[0];
assign rx_adr =  {30{select0}} & slot0_adr
		|{30{select1}} & slot1_adr
		|{30{select2}} & slot2_adr
		|{30{select3}} & slot3_adr;

/*
 * TX
 */
reg [10:0] tx_remaining;
assign tx_valid = |tx_remaining;

wire csr_selected = csr_a[13:10] == csr_addr;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		csr_do <= 32'd0;

		rx_rst <= 1'b1;
		tx_rst <= 1'b1;

		mii_data_oe <= 1'b0;
		mii_data_do <= 1'b0;
		phy_mii_clk <= 1'b0;

		slot0_state <= 2'b00;
		slot0_adr <= 30'd0;
		slot0_count <= 11'd0;
		slot1_state <= 2'b00;
		slot1_adr <= 30'd0;
		slot1_count <= 11'd0;
		slot2_state <= 2'b00;
		slot2_adr <= 30'd0;
		slot2_count <= 11'd0;
		slot3_state <= 2'b00;
		slot3_adr <= 30'd0;
		slot3_count <= 11'd0;

		tx_remaining <= 11'd0;
		tx_adr <= 30'd0;
		tx_bytecount <= 2'd0;
	end else begin
		csr_do <= 32'd0;
		if(csr_selected) begin
			if(csr_we) begin
				case(csr_a[3:0])
					4'd0 : begin
						tx_rst <= csr_di[1];
						rx_rst <= csr_di[0];
					end

					4'd1 : begin
						phy_mii_clk <= csr_di[3];
						mii_data_oe <= csr_di[2];
						mii_data_do <= csr_di[0];
					end

					4'd2 : begin
						slot0_state <= csr_di[1:0];
						slot0_count <= 11'd0;
					end
					4'd3 : slot0_adr <= csr_di[31:2];
					// slot0_count is read-only
					4'd5 : begin
						slot1_state <= csr_di[1:0];
						slot1_count <= 11'd0;
					end
					4'd6 : slot1_adr <= csr_di[31:2];
					// slot1_count is read-only
					4'd8 : begin
						slot2_state <= csr_di[1:0];
						slot2_count <= 11'd0;
					end
					4'd9 : slot2_adr <= csr_di[31:2];
					// slot2_count is read-only
					4'd11: begin
						slot3_state <= csr_di[1:0];
						slot3_count <= 11'd0;
					end
					4'd12: slot3_adr <= csr_di[31:2];
					// slot3_count is read-only

					4'd14: csr_do <= tx_adr;
					4'd15: begin
						csr_do <= tx_remaining;
						tx_bytecount <= 2'd0;
					end
				endcase
			end
			case(csr_a[3:0])
				4'd0 : csr_do <= {tx_rst, rx_rst};

				4'd1 : csr_do <= {phy_mii_clk, mii_data_oe, mii_data_di, mii_data_do};
				
				4'd2 : csr_do <= slot0_state;
				4'd3 : csr_do <= {slot0_adr, 2'd0};
				4'd4 : csr_do <= slot0_count;
				4'd5 : csr_do <= slot1_state;
				4'd6 : csr_do <= {slot1_adr, 2'd0};
				4'd7 : csr_do <= slot1_count;
				4'd8 : csr_do <= slot2_state;
				4'd9 : csr_do <= {slot2_adr, 2'd0};
				4'd10: csr_do <= slot2_count;
				4'd11: csr_do <= slot3_state;
				4'd12: csr_do <= {slot3_adr, 2'd0};
				4'd13: csr_do <= slot3_count;

				4'd14: csr_do <= tx_adr;
				4'd15: csr_do <= tx_remaining;
			endcase
		end

		if(fifo_full)
			rx_rst <= 1'b1;

		if(rx_resetcount) begin
			if(select0)
				slot0_count <= 11'd0;
			if(select1)
				slot1_count <= 11'd0;
			if(select2)
				slot2_count <= 11'd0;
			if(select3)
				slot3_count <= 11'd0;
		end
		if(rx_incrcount) begin
			if(select0)
				slot0_count <= slot0_count + 11'd1;
			if(select1)
				slot1_count <= slot1_count + 11'd1;
			if(select2)
				slot2_count <= slot2_count + 11'd1;
			if(select3)
				slot3_count <= slot3_count + 11'd1;
		end
		if(rx_endframe) begin
			if(select0)
				slot0_state <= 2'b10;
			if(select1)
				slot1_state <= 2'b10;
			if(select2)
				slot2_state <= 2'b10;
			if(select3)
				slot3_state <= 2'b10;
		end

		if(tx_next) begin
			tx_remaining <= tx_remaining - 11'd1;
			tx_bytecount <= tx_bytecount + 2'd1;
			if(tx_bytecount == 2'd3)
				tx_adr <= tx_adr + 30'd1;
		end
	end
end

/* Interrupt logic */

reg tx_valid_r;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		irq_rx <= 1'b0;
		tx_valid_r <= 1'b0;
		irq_tx <= 1'b0;
	end else begin
		irq_rx <= slot0_state[1] | slot1_state[1] | slot2_state[1] | slot3_state[1] | fifo_full;
		tx_valid_r <= tx_valid;
		irq_tx <= tx_valid_r & ~tx_valid;
	end
end

endmodule
