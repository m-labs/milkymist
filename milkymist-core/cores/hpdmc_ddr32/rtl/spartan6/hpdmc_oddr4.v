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

/*
 * Verilog code that really should be replaced with a generate
 * statement, but it does not work with some free simulators.
 * So I put it in a module so as not to make other code unreadable,
 * and keep compatibility with as many simulators as possible.
 */

module hpdmc_oddr4 #(
	parameter DDR_CLK_EDGE = "SAME_EDGE",
	parameter INIT = 1'b0,
	parameter SRTYPE = "SYNC"
) (
	output [3:0] Q,
	input C,
	input CE,
	input [3:0] D1,
	input [3:0] D2,
	input R,
	input S
);

ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr0 (
	.Q(Q[0]),
	.C(C),
	.CE(CE),
	.D1(D1[0]),
	.D2(D2[0]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr1 (
	.Q(Q[1]),
	.C(C),
	.CE(CE),
	.D1(D1[1]),
	.D2(D2[1]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr2 (
	.Q(Q[2]),
	.C(C),
	.CE(CE),
	.D1(D1[2]),
	.D2(D2[2]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr3 (
	.Q(Q[3]),
	.C(C),
	.CE(CE),
	.D1(D1[3]),
	.D2(D2[3]),
	.R(R),
	.S(S)
);

endmodule
