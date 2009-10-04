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
 * statement, but free simulators won't let me do.
 * So I put it in a module so as not to make other code unreadable.
 */

module hpdmc_iddr32 #(
	parameter DDR_CLK_EDGE = "SAME_EDGE",
	parameter INIT_Q1 = 1'b0,
	parameter INIT_Q2 = 1'b0,
	parameter SRTYPE = "SYNC"
) (
	output [31:0] Q1,
	output [31:0] Q2,
	input C,
	input CE,
	input [31:0] D,
	input R,
	input S
);

IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr0 (
	.Q1(Q1[0]),
	.Q2(Q2[0]),
	.C(C),
	.CE(CE),
	.D(D[0]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr1 (
	.Q1(Q1[1]),
	.Q2(Q2[1]),
	.C(C),
	.CE(CE),
	.D(D[1]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr2 (
	.Q1(Q1[2]),
	.Q2(Q2[2]),
	.C(C),
	.CE(CE),
	.D(D[2]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr3 (
	.Q1(Q1[3]),
	.Q2(Q2[3]),
	.C(C),
	.CE(CE),
	.D(D[3]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr4 (
	.Q1(Q1[4]),
	.Q2(Q2[4]),
	.C(C),
	.CE(CE),
	.D(D[4]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr5 (
	.Q1(Q1[5]),
	.Q2(Q2[5]),
	.C(C),
	.CE(CE),
	.D(D[5]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr6 (
	.Q1(Q1[6]),
	.Q2(Q2[6]),
	.C(C),
	.CE(CE),
	.D(D[6]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr7 (
	.Q1(Q1[7]),
	.Q2(Q2[7]),
	.C(C),
	.CE(CE),
	.D(D[7]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr8 (
	.Q1(Q1[8]),
	.Q2(Q2[8]),
	.C(C),
	.CE(CE),
	.D(D[8]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr9 (
	.Q1(Q1[9]),
	.Q2(Q2[9]),
	.C(C),
	.CE(CE),
	.D(D[9]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr10 (
	.Q1(Q1[10]),
	.Q2(Q2[10]),
	.C(C),
	.CE(CE),
	.D(D[10]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr11 (
	.Q1(Q1[11]),
	.Q2(Q2[11]),
	.C(C),
	.CE(CE),
	.D(D[11]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr12 (
	.Q1(Q1[12]),
	.Q2(Q2[12]),
	.C(C),
	.CE(CE),
	.D(D[12]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr13 (
	.Q1(Q1[13]),
	.Q2(Q2[13]),
	.C(C),
	.CE(CE),
	.D(D[13]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr14 (
	.Q1(Q1[14]),
	.Q2(Q2[14]),
	.C(C),
	.CE(CE),
	.D(D[14]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr15 (
	.Q1(Q1[15]),
	.Q2(Q2[15]),
	.C(C),
	.CE(CE),
	.D(D[15]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr16 (
	.Q1(Q1[16]),
	.Q2(Q2[16]),
	.C(C),
	.CE(CE),
	.D(D[16]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr17 (
	.Q1(Q1[17]),
	.Q2(Q2[17]),
	.C(C),
	.CE(CE),
	.D(D[17]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr18 (
	.Q1(Q1[18]),
	.Q2(Q2[18]),
	.C(C),
	.CE(CE),
	.D(D[18]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr19 (
	.Q1(Q1[19]),
	.Q2(Q2[19]),
	.C(C),
	.CE(CE),
	.D(D[19]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr20 (
	.Q1(Q1[20]),
	.Q2(Q2[20]),
	.C(C),
	.CE(CE),
	.D(D[20]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr21 (
	.Q1(Q1[21]),
	.Q2(Q2[21]),
	.C(C),
	.CE(CE),
	.D(D[21]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr22 (
	.Q1(Q1[22]),
	.Q2(Q2[22]),
	.C(C),
	.CE(CE),
	.D(D[22]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr23 (
	.Q1(Q1[23]),
	.Q2(Q2[23]),
	.C(C),
	.CE(CE),
	.D(D[23]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr24 (
	.Q1(Q1[24]),
	.Q2(Q2[24]),
	.C(C),
	.CE(CE),
	.D(D[24]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr25 (
	.Q1(Q1[25]),
	.Q2(Q2[25]),
	.C(C),
	.CE(CE),
	.D(D[25]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr26 (
	.Q1(Q1[26]),
	.Q2(Q2[26]),
	.C(C),
	.CE(CE),
	.D(D[26]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr27 (
	.Q1(Q1[27]),
	.Q2(Q2[27]),
	.C(C),
	.CE(CE),
	.D(D[27]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr28 (
	.Q1(Q1[28]),
	.Q2(Q2[28]),
	.C(C),
	.CE(CE),
	.D(D[28]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr29 (
	.Q1(Q1[29]),
	.Q2(Q2[29]),
	.C(C),
	.CE(CE),
	.D(D[29]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr30 (
	.Q1(Q1[30]),
	.Q2(Q2[30]),
	.C(C),
	.CE(CE),
	.D(D[30]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr31 (
	.Q1(Q1[31]),
	.Q2(Q2[31]),
	.C(C),
	.CE(CE),
	.D(D[31]),
	.R(R),
	.S(S)
);

endmodule
