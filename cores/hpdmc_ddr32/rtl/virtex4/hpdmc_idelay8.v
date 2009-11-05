/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
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

module hpdmc_idelay8(
	input [7:0] i,
	output [7:0] o,
	
	input clk,
	input rst,
	input ce,
	input inc
);

IDELAY #(
	.IOBDELAY_TYPE("VARIABLE"),
	.IOBDELAY_VALUE(0)
) d0 (
	.I(i[0]),
	.C(clk),
	.INC(inc),
	.CE(ce),
	.RST(rst),
	.O(o[0])
);
IDELAY #(
	.IOBDELAY_TYPE("VARIABLE"),
	.IOBDELAY_VALUE(0)
) d1 (
	.I(i[1]),
	.C(clk),
	.INC(inc),
	.CE(ce),
	.RST(rst),
	.O(o[1])
);
IDELAY #(
	.IOBDELAY_TYPE("VARIABLE"),
	.IOBDELAY_VALUE(0)
) d2 (
	.I(i[2]),
	.C(clk),
	.INC(inc),
	.CE(ce),
	.RST(rst),
	.O(o[2])
);
IDELAY #(
	.IOBDELAY_TYPE("VARIABLE"),
	.IOBDELAY_VALUE(0)
) d3 (
	.I(i[3]),
	.C(clk),
	.INC(inc),
	.CE(ce),
	.RST(rst),
	.O(o[3])
);
IDELAY #(
	.IOBDELAY_TYPE("VARIABLE"),
	.IOBDELAY_VALUE(0)
) d4 (
	.I(i[4]),
	.C(clk),
	.INC(inc),
	.CE(ce),
	.RST(rst),
	.O(o[4])
);
IDELAY #(
	.IOBDELAY_TYPE("VARIABLE"),
	.IOBDELAY_VALUE(0)
) d5 (
	.I(i[5]),
	.C(clk),
	.INC(inc),
	.CE(ce),
	.RST(rst),
	.O(o[5])
);
IDELAY #(
	.IOBDELAY_TYPE("VARIABLE"),
	.IOBDELAY_VALUE(0)
) d6 (
	.I(i[6]),
	.C(clk),
	.INC(inc),
	.CE(ce),
	.RST(rst),
	.O(o[6])
);
IDELAY #(
	.IOBDELAY_TYPE("VARIABLE"),
	.IOBDELAY_VALUE(0)
) d7 (
	.I(i[7]),
	.C(clk),
	.INC(inc),
	.CE(ce),
	.RST(rst),
	.O(o[7])
);

endmodule
