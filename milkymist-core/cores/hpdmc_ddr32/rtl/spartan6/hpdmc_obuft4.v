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

module hpdmc_obuft4(
	input [3:0] T,
	input [3:0] I,
	output [3:0] O
);

OBUFT obuft0(
	.T(T[0]),
	.I(I[0]),
	.O(O[0])
);
OBUFT obuft1(
	.T(T[1]),
	.I(I[1]),
	.O(O[1])
);
OBUFT obuft2(
	.T(T[2]),
	.I(I[2]),
	.O(O[2])
);
OBUFT obuft3(
	.T(T[3]),
	.I(I[3]),
	.O(O[3])
);

endmodule
