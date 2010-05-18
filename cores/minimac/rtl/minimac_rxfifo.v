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

module minimac_rxfifo(
	input sys_clk,
	input rx_rst,

	input phy_rx_clk,
	input [3:0] phy_rx_data,
	input phy_dv,
	input phy_rx_er,

	output empty,
	input ack,
	output eof,
	output [7:0] data,

	output reg fifo_full
);

/*
 * EOF = 0		frame data
 * EOF = 1, data[0] = 0	frame completed without errors
 * EOF = 1, data[0] = 1	frame completed with errors
 */

wire [8:0] fifo_out;
assign eof = fifo_out[8];
assign data = fifo_out[7:0];

reg fifo_eof;
reg [3:0] fifo_hi;
reg [3:0] fifo_lo;
wire [8:0] fifo_in = {fifo_eof, fifo_hi, fifo_lo};
reg fifo_we;
wire full;

minimac_asfifo #(
	.DATA_WIDTH(9),
	.ADDRESS_WIDTH(7)
) fifo (
	.Data_out(fifo_out),
	.Empty_out(empty),
	.ReadEn_in(ack),
	.RClk(sys_clk),

	.Data_in(fifo_in),
	.Full_out(full),
	.WriteEn_in(fifo_we),
	.WClk(phy_rx_clk),
	.Clear_in(rx_rst)
);

/* we assume f(sys_clk) > f(phy_rx_clk) */
reg fifo_full1;
always @(posedge sys_clk) begin
	fifo_full1 <= full;
	fifo_full <= fifo_full1;
end

reg rx_rst1;
reg rx_rst2;

always @(posedge phy_rx_clk) begin
	rx_rst1 <= rx_rst;
	rx_rst2 <= rx_rst1;
end

reg hi_nibble;
reg abort;
reg phy_dv_r;

always @(posedge phy_rx_clk) begin
	if(rx_rst2) begin
		fifo_we <= 1'b0;
		fifo_eof <= 1'b0;
		fifo_hi <= 4'd0;
		fifo_lo <= 4'd0;
		hi_nibble <= 1'b0;
		abort <= 1'b0;
		phy_dv_r <= 1'b0;
	end else begin
		fifo_eof <= 1'b0;
		fifo_we <= 1'b0;

		/* Transfer data */
		if(~abort) begin
			if(~hi_nibble) begin
				fifo_lo <= phy_rx_data;
				if(phy_dv)
					hi_nibble <= 1'b1;
			end else begin
				fifo_hi <= phy_rx_data;
				fifo_we <= 1'b1;
				hi_nibble <= 1'b0;
			end
		end

		/* Detect error events */
		if(phy_dv & phy_rx_er) begin
			fifo_eof <= 1'b1;
			fifo_hi <= 4'd0;
			fifo_lo <= 4'd1;
			fifo_we <= 1'b1;
			abort <= 1'b1;
			hi_nibble <= 1'b0;
		end

		/* Detect end of frame */
		phy_dv_r <= phy_dv;
		if(phy_dv_r & ~phy_dv) begin
			if(~abort) begin
				fifo_eof <= 1'b1;
				fifo_hi <= 4'd0;
				fifo_lo <= 4'd0;
				fifo_we <= 1'b1;
			end
			abort <= 1'b0;
			hi_nibble <= 1'b0;
		end
	end
end

endmodule
