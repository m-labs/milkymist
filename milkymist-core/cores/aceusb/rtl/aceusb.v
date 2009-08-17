/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 *
 * This program is free and excepted software; you can use it, redistribute it
 * and/or modify it under the terms of the Exception General Public License as
 * published by the Exception License Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the Exception General Public License for more
 * details.
 *
 * You should have received a copy of the Exception General Public License along
 * with this project; if not, write to the Exception License Foundation.
 */

module aceusb(
	/* WISHBONE interface */
	input sys_clk,
	input sys_rst,
	
	input [31:0] wb_adr_i,
	input [31:0] wb_dat_i,
	output [31:0] wb_dat_o,
	input wb_cyc_i,
	input wb_stb_i,
	input wb_we_i,
	output reg wb_ack_o,

	/* Signals shared between SystemACE and USB */
	output [6:0] aceusb_a,
	inout [15:0] aceusb_d,
	output aceusb_oe_n,
	output aceusb_we_n,

	/* SystemACE signals */
	input ace_clkin,
	output ace_mpce_n,
	input ace_mpirq,

	output usb_cs_n,
	output usb_hpi_reset_n,
	input usb_hpi_int
);

wire access_read1;
wire access_write1;
wire access_ack1;

/* Avoid potential glitches by sampling wb_adr_i and wb_dat_i only at the appropriate time */
reg load_adr_dat;
reg [5:0] address_reg;
reg [15:0] data_reg;
always @(posedge sys_clk) begin
	if(load_adr_dat) begin
		address_reg <= wb_adr_i[7:2];
		data_reg <= wb_dat_i[15:0];
	end
end

aceusb_access access(
	.ace_clkin(ace_clkin),
	.rst(sys_rst),
	
	.a(address_reg),
	.di(data_reg),
	.do(wb_dat_o[15:0]),
	.read(access_read1),
	.write(access_write1),
	.ack(access_ack1),

	.aceusb_a(aceusb_a),
	.aceusb_d(aceusb_d),
	.aceusb_oe_n(aceusb_oe_n),
	.aceusb_we_n(aceusb_we_n),
	.ace_mpce_n(ace_mpce_n),
	.ace_mpirq(ace_mpirq),
	.usb_cs_n(usb_cs_n),
	.usb_hpi_reset_n(usb_hpi_reset_n),
	.usb_hpi_int(usb_hpi_int)
);

assign wb_dat_o[31:16] = 16'h0000;

/* Synchronize read, write and acknowledgement pulses */ 
reg access_read;
reg access_write;
wire access_ack;

aceusb_sync sync_read(
	.clk0(sys_clk),
	.flagi(access_read),
	
	.clk1(ace_clkin),
	.flago(access_read1)
);

aceusb_sync sync_write(
	.clk0(sys_clk),
	.flagi(access_write),
	
	.clk1(ace_clkin),
	.flago(access_write1)
);

aceusb_sync sync_ack(
	.clk0(ace_clkin),
	.flagi(access_ack1),
	
	.clk1(sys_clk),
	.flago(access_ack)
);

/* Main FSM */

reg state;
reg next_state;

parameter IDLE = 1'd0;
parameter WAIT = 1'd1;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= IDLE;
	else
		state <= next_state;
end

always @(*) begin
	load_adr_dat = 1'b0;
	wb_ack_o = 1'b0;
	access_read = 1'b0;
	access_write = 1'b0;
	
	next_state = state;
	
	case(state)
		IDLE: begin
			if(wb_cyc_i & wb_stb_i) begin
				load_adr_dat = 1'b1;
				if(wb_we_i)
					access_write = 1'b1;
				else
					access_read = 1'b1;
				next_state = WAIT;
			end
		end
		
		WAIT: begin
			if(access_ack) begin
				wb_ack_o = 1'b1;
				next_state = IDLE;
			end
		end
	endcase
end

endmodule
 