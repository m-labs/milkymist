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

/*
 * Verilog code that really should be replaced with a generate
 * statement, but it does not work with some free simulators.
 * So I put it in a module so as not to make other code unreadable,
 * and keep compatibility with as many simulators as possible.
 */

module hpdmc_oddr32 #(
	parameter DDR_CLK_EDGE = "SAME_EDGE",
	parameter INIT = 1'b0,
	parameter SRTYPE = "SYNC"
) (
	output [31:0] Q,
	input C,
	input CE,
	input [31:0] D1,
	input [31:0] D2,
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
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr4 (
	.Q(Q[4]),
	.C(C),
	.CE(CE),
	.D1(D1[4]),
	.D2(D2[4]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr5 (
	.Q(Q[5]),
	.C(C),
	.CE(CE),
	.D1(D1[5]),
	.D2(D2[5]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr6 (
	.Q(Q[6]),
	.C(C),
	.CE(CE),
	.D1(D1[6]),
	.D2(D2[6]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr7 (
	.Q(Q[7]),
	.C(C),
	.CE(CE),
	.D1(D1[7]),
	.D2(D2[7]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr8 (
	.Q(Q[8]),
	.C(C),
	.CE(CE),
	.D1(D1[8]),
	.D2(D2[8]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr9 (
	.Q(Q[9]),
	.C(C),
	.CE(CE),
	.D1(D1[9]),
	.D2(D2[9]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr10 (
	.Q(Q[10]),
	.C(C),
	.CE(CE),
	.D1(D1[10]),
	.D2(D2[10]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr11 (
	.Q(Q[11]),
	.C(C),
	.CE(CE),
	.D1(D1[11]),
	.D2(D2[11]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr12 (
	.Q(Q[12]),
	.C(C),
	.CE(CE),
	.D1(D1[12]),
	.D2(D2[12]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr13 (
	.Q(Q[13]),
	.C(C),
	.CE(CE),
	.D1(D1[13]),
	.D2(D2[13]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr14 (
	.Q(Q[14]),
	.C(C),
	.CE(CE),
	.D1(D1[14]),
	.D2(D2[14]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr15 (
	.Q(Q[15]),
	.C(C),
	.CE(CE),
	.D1(D1[15]),
	.D2(D2[15]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr16 (
	.Q(Q[16]),
	.C(C),
	.CE(CE),
	.D1(D1[16]),
	.D2(D2[16]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr17 (
	.Q(Q[17]),
	.C(C),
	.CE(CE),
	.D1(D1[17]),
	.D2(D2[17]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr18 (
	.Q(Q[18]),
	.C(C),
	.CE(CE),
	.D1(D1[18]),
	.D2(D2[18]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr19 (
	.Q(Q[19]),
	.C(C),
	.CE(CE),
	.D1(D1[19]),
	.D2(D2[19]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr20 (
	.Q(Q[20]),
	.C(C),
	.CE(CE),
	.D1(D1[20]),
	.D2(D2[20]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr21 (
	.Q(Q[21]),
	.C(C),
	.CE(CE),
	.D1(D1[21]),
	.D2(D2[21]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr22 (
	.Q(Q[22]),
	.C(C),
	.CE(CE),
	.D1(D1[22]),
	.D2(D2[22]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr23 (
	.Q(Q[23]),
	.C(C),
	.CE(CE),
	.D1(D1[23]),
	.D2(D2[23]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr24 (
	.Q(Q[24]),
	.C(C),
	.CE(CE),
	.D1(D1[24]),
	.D2(D2[24]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr25 (
	.Q(Q[25]),
	.C(C),
	.CE(CE),
	.D1(D1[25]),
	.D2(D2[25]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr26 (
	.Q(Q[26]),
	.C(C),
	.CE(CE),
	.D1(D1[26]),
	.D2(D2[26]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr27 (
	.Q(Q[27]),
	.C(C),
	.CE(CE),
	.D1(D1[27]),
	.D2(D2[27]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr28 (
	.Q(Q[28]),
	.C(C),
	.CE(CE),
	.D1(D1[28]),
	.D2(D2[28]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr29 (
	.Q(Q[29]),
	.C(C),
	.CE(CE),
	.D1(D1[29]),
	.D2(D2[29]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr30 (
	.Q(Q[30]),
	.C(C),
	.CE(CE),
	.D1(D1[30]),
	.D2(D2[30]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr31 (
	.Q(Q[31]),
	.C(C),
	.CE(CE),
	.D1(D1[31]),
	.D2(D2[31]),
	.R(R),
	.S(S)
);

endmodule
