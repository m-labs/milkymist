/*
 * ML401 Flasher
 * Copyright (C) 2009 Sebastien Bourdeauducq
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

module flasher(
	input clkin,
	
	output [24:0] flash_adr,
	output [31:0] flash_d,
	output flash_byte_n,
	output flash_oe_n,
	output flash_we_n,
	output flash_ce,
	output flash_ac97_reset_n,
	
	output sram_clk,
	output sram_ce_n,
	output sram_zz,
	
	output [3:0] led
);

wire drck;
wire tdi;
wire update;

BSCAN_VIRTEX4 #(
	.JTAG_CHAIN(1)
) bscan (
	.CAPTURE(),
	.DRCK(drck),
	.RESET(),
	.SEL(),
	.SHIFT(),
	.TDI(tdi),
	.UPDATE(update),
	.TDO(1'b0)
);

reg [56:0] jtag_shift;
reg [56:0] jtag_latched;

always @(posedge drck)
	jtag_shift <= {tdi, jtag_shift[56:1]};

always @(posedge update)
	jtag_latched <= jtag_shift;

/*
 * JTAG register layout :
 * Bits 0-31: Data
 * Bits 52-32: Address
 * Bit  53: WE_N
 * Bit  54: CE
 * Bit  55: RESET_N
 * Bit  56: OE_N
 */

assign flash_d = jtag_latched[56] ? jtag_latched[31:0] : 32'hzzzzzzzz;
assign flash_adr[21:1] = jtag_latched[52:32];
assign flash_adr[0] = 1'b0;
assign flash_adr[24:22] = 3'b000;
assign flash_we_n = jtag_latched[53];
assign flash_ce = jtag_latched[54];
assign flash_ac97_reset_n = jtag_latched[55];
assign flash_oe_n = jtag_latched[56];

assign flash_byte_n = 1'b1;

/* Display a flashing pattern on the LEDs so we know we are in flash mode */
reg [25:0] counter;
always @(posedge clkin) counter <= counter + 26'd1;
assign led = {counter[25], ~counter[25], ~counter[25], counter[25]};

/* Disable the SRAM */
assign sram_clk = clkin;
assign sram_ce_n = 1'b1;
assign sram_zz = 1'b1;

endmodule
