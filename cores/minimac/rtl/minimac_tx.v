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

module minimac_tx(
	input sys_clk,
	input sys_rst,
	input tx_rst,

	input tx_valid,
	input [29:0] tx_adr,
	input [1:0] tx_bytecount,
	output reg tx_next,

	output [31:0] wbtx_adr_o,
	output wbtx_cyc_o,
	output wbtx_stb_o,
	input wbtx_ack_i,
	input [31:0] wbtx_dat_i,

	input phy_tx_clk,
	output phy_tx_en,
	output [3:0] phy_tx_data
);

reg bus_stb;
assign wbtx_cyc_o = bus_stb;
assign wbtx_stb_o = bus_stb;

assign wbtx_adr_o = {tx_adr, 2'd0};

reg stb;
reg [7:0] data;
wire full;
reg can_tx;
wire empty;

minimac_txfifo txfifo(
	.sys_clk(sys_clk),
	.tx_rst(tx_rst),

	.stb(stb),
	.data(data),
	.full(full),
	.can_tx(can_tx),
	.empty(empty),

	.phy_tx_clk(phy_tx_clk),
	.phy_tx_en(phy_tx_en),
	.phy_tx_data(phy_tx_data)
);

reg load_input;
reg [31:0] input_reg;

always @(posedge sys_clk)
	if(load_input)
		input_reg <= wbtx_dat_i;

always @(*) begin
	case(tx_bytecount)
		2'd0: data = input_reg[31:24];
		2'd1: data = input_reg[23:16];
		2'd2: data = input_reg[16: 8];
		2'd3: data = input_reg[ 7: 0];
	endcase
end

wire firstbyte = tx_bytecount == 2'd0;

reg purge;

/* fetch FSM */

reg state;
reg next_state;

parameter IDLE  = 1'b0;
parameter FETCH = 1'b1;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= IDLE;
	else
		state <= next_state;
end

always @(*) begin
	next_state = state;
	
	load_input = 1'b0;
	tx_next = 1'b0;

	stb = 1'b0;

	bus_stb = 1'b0;

	case(state)
		IDLE: begin
			if(tx_valid & ~full & ~purge) begin
				if(firstbyte)
					next_state = FETCH;
				else begin
					stb = 1'b1;
					tx_next = 1'b1;
				end
			end
		end
		FETCH: begin
			bus_stb = 1'b1;
			load_input = 1'b1;
			if(wbtx_ack_i)
				next_state = IDLE;
		end
	endcase
end

/* FIFO control FSM */

reg [1:0] fstate;
reg [1:0] next_fstate;

parameter FIDLE		= 2'd0;
parameter FWAITFULL	= 2'd1;
parameter FTX		= 2'd2;
parameter FPURGE	= 2'd3;

always @(posedge sys_clk) begin
	if(sys_rst)
		fstate <= FIDLE;
	else
		fstate <= next_fstate;
end

always @(*) begin
	next_fstate = fstate;

	can_tx = 1'b0;
	purge = 1'b0;
	
	case(fstate)
		FIDLE: begin
			if(tx_valid)
				next_fstate = FWAITFULL;
		end
		/* Wait for the FIFO to fill before starting transmission.
		 * We assume that the FIFO is too small to hold the complete packet
		 * to be transmitted (ethernet minimum = 72 bytes).
		 */
		FWAITFULL: begin
			if(full)
				next_fstate = FTX;
		end
		FTX: begin
			can_tx = 1'b1;
			if(~tx_valid) begin
				purge = 1'b1;
				next_fstate = FPURGE;
			end
		end
		FPURGE: begin
			can_tx = 1'b1;
			purge = 1'b1;
			if(empty)
				next_fstate = FIDLE;
			/* NB! there is a potential bug because of the latency
			 * introducted by the synchronizer on can_tx in txfifo.
			 * However, the interframe gap prevents it to happen
			 * unless f(sys_clk) >> f(phy_tx_clk).
			 */
		end
	endcase
end

endmodule
