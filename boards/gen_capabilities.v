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

`include "setup.v"

module gen_capabilities(
	output [31:0] capabilities
);

wire systemace;
wire ac97;
wire pfpu;
wire tmu;
wire ps2_keyboard;
wire ps2_mouse;
wire ethernet;
wire fmlmeter;

assign capabilities = {
	24'd0,
	fmlmeter,
	ethernet,
	ps2_mouse,
	ps2_keyboard,
	tmu,
	pfpu,
	ac97,
 systemace
};

`ifdef ENABLE_ACEUSB
assign systemace = 1'b1;
`else
assign systemace = 1'b0;
`endif

`ifdef ENABLE_AC97
assign ac97 = 1'b1;
`else
assign ac97 = 1'b0;
`endif

`ifdef ENABLE_PFPU
assign pfpu = 1'b1;
`else
assign pfpu = 1'b0;
`endif

`ifdef ENABLE_TMU
assign tmu = 1'b1;
`else
assign tmu = 1'b0;
`endif

`ifdef ENABLE_PS2_KEYBOARD
assign ps2_keyboard = 1'b1;
`else
assign ps2_keyboard = 1'b0;
`endif

`ifdef ENABLE_PS2_MOUSE
assign ps2_mouse = 1'b1;
`else
assign ps2_mouse = 1'b0;
`endif

`ifdef ENABLE_ETHERNET
assign ethernet = 1'b1;
`else
assign ethernet = 1'b0;
`endif

`ifdef ENABLE_FMLMETER
assign fmlmeter = 1'b1;
`else
assign fmlmeter = 1'b0;
`endif

endmodule
