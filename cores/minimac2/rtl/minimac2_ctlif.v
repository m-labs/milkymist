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

module minimac2_ctlif #(
	parameter csr_addr = 4'h0
) (
	input sys_clk,
	input sys_rst,

	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output reg [31:0] csr_do,

	output irq_rx,
	output irq_tx,
	
	output [1:0] rx_ready,
	input [1:0] rx_done,
	input [10:0] rx_count_0,
	input [10:0] rx_count_1,
	
	output tx_start,
	input tx_done,
	output reg [10:0] tx_count,

	output reg phy_mii_clk,
	inout phy_mii_data,
	output phy_rst_n
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

reg phy_rst;
assign phy_rst_n = ~(phy_rst | sys_rst);

/*
 * RX Slots
 *
 * State:
 * 00 -> slot is disabled
 * 01 -> slot can receive a new packet
 * 10 -> slot has received a packet (IRQ asserted)
 * 11 -> invalid
 */
reg [1:0] slot0_state;
reg [1:0] slot1_state;

wire csr_selected = csr_a[13:10] == csr_addr;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		csr_do <= 32'd0;

		phy_rst <= 1'b1;

		mii_data_oe <= 1'b0;
		mii_data_do <= 1'b0;
		phy_mii_clk <= 1'b0;
		phy_rst <= 1'b0;

		slot0_state <= 2'b00;
		slot1_state <= 2'b00;

		tx_count <= 11'd0;
	end else begin
		csr_do <= 32'd0;
		if(csr_selected) begin
			if(csr_we) begin
				case(csr_a[2:0])
					3'd0: phy_rst <= csr_di[0];

					3'd1: begin
						phy_mii_clk <= csr_di[3];
						mii_data_oe <= csr_di[2];
						mii_data_do <= csr_di[0];
					end

					3'd2: slot0_state <= csr_di[1:0];
					// 'd3 rx_count_0 is read-only
					3'd4: slot1_state <= csr_di[1:0];
					// 'd5 rx_count_1 is read-only

					3'd6: tx_count <= csr_di[10:0];
				endcase
			end
			case(csr_a[2:0])
				3'd0: csr_do <= phy_rst;

				3'd1: csr_do <= {phy_mii_clk, mii_data_oe, mii_data_di, mii_data_do};
				
				3'd2: csr_do <= slot0_state;
				3'd3: csr_do <= rx_count_0;
				3'd4: csr_do <= slot1_state;
				3'd5: csr_do <= rx_count_1;

				3'd6: csr_do <= tx_count;
			endcase
		end /* if(csr_selected) */
		
		if(rx_done[0])
			slot0_state <= 2'b10;
		if(rx_done[1])
			slot1_state <= 2'b10;
		if(tx_done)
			tx_count <= 11'd0;
	end
end

wire [1:0] slots_loaded = {slot1_state[0], slot0_state[0]}; 
reg [1:0] slots_loaded_r;
always @(posedge sys_clk)
	slots_loaded_r <= slots_loaded;
assign rx_ready = slots_loaded & ~slots_loaded_r;

wire tx_remaining = |tx_count;
reg tx_remaining_r;
always @(posedge sys_clk)
	tx_remaining_r <= tx_remaining;
assign tx_start = tx_remaining & ~tx_remaining_r;

/* Interrupt logic */
assign irq_rx = slot0_state[1] | slot1_state[1];
assign irq_tx = tx_done;

endmodule
