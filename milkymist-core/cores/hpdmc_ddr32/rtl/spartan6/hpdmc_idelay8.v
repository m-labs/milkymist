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
