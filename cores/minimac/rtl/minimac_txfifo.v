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

module minimac_txfifo(
	input sys_clk,
	input tx_rst,

	input stb,
	input [7:0] data,
	output full,
	input can_tx,
	output reg empty,

	input phy_tx_clk,
	output reg phy_tx_en,
	output reg [3:0] phy_tx_data
);

wire [7:0] fifo_out;
wire fifo_empty;
reg fifo_read;

reg empty2;
always @(posedge sys_clk) begin
	empty2 <= fifo_empty;
	empty <= empty2;
end

minimac_asfifo #(
	.DATA_WIDTH(8),
	.ADDRESS_WIDTH(6)
) fifo (
	.Data_out(fifo_out),
	.Empty_out(fifo_empty),
	.ReadEn_in(fifo_read),
	.RClk(phy_tx_clk),

	.Data_in(data),
	.Full_out(full),
	.WriteEn_in(stb),
	.WClk(sys_clk),
	.Clear_in(tx_rst)
);

reg can_tx1;
reg can_tx2;
always @(posedge phy_tx_clk) begin
	can_tx1 <= can_tx;
	can_tx2 <= can_tx1;
end

reg tx_rst1;
reg tx_rst2;
always @(posedge phy_tx_clk) begin
	tx_rst1 <= tx_rst;
	tx_rst2 <= tx_rst2;
end

wire interframe_gap;
wire transmitting = can_tx2 & ~fifo_empty & ~interframe_gap;

reg transmitting_r;
always @(posedge phy_tx_clk)
	transmitting_r <= transmitting;

reg [4:0] interframe_counter;
always @(posedge phy_tx_clk) begin
	if(tx_rst2)
		interframe_counter <= 5'd0;
	else begin
		if(transmitting_r & ~transmitting)
			interframe_counter <= 5'd24;
		else if(interframe_counter != 5'd0)
			interframe_counter <= interframe_counter - 5'd1;
	end
end
assign interframe_gap = |interframe_counter;

reg hi_nibble;

always @(posedge phy_tx_clk) begin
	if(tx_rst2) begin
		hi_nibble <= 1'b0;
		phy_tx_en <= 1'b0;
	end else begin
		hi_nibble <= 1'b0;
		phy_tx_en <= 1'b0;
		fifo_read <= 1'b0;

		if(transmitting) begin
			phy_tx_en <= 1'b1;
			if(~hi_nibble) begin
				phy_tx_data <= fifo_out[3:0];
				fifo_read <= 1'b1;
				hi_nibble <= 1'b1;
			end else begin
				phy_tx_data <= fifo_out[7:4];
				hi_nibble <= 1'b0;
			end
		end
	end
end

endmodule
