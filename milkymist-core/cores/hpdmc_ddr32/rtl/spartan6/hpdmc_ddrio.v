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

module hpdmc_ddrio(
	input sys_clk,
	input sys_clk_n,
	input dqs_clk,
	input dqs_clk_n,
	
	input direction,
	input [7:0] mo,
	input [63:0] do,
	output [63:0] di,
	
	output [3:0] sdram_dqm,
	inout [31:0] sdram_dq,
	inout [3:0] sdram_dqs,
	
	input idelay_rst,
	input idelay_ce,
	input idelay_inc
);

/******/
/* DQ */
/******/

wire [31:0] sdram_dq_out;
assign sdram_dq = direction ? sdram_dq_out : 32'hzzzzzzzz;

hpdmc_oddr32 oddr_dq(
	.Q(sdram_dq_out),
	.C0(sys_clk),
	.C1(sys_clk_n),
	.CE(1'b1),
	.D0(do[63:32]),
	.D1(do[31:0]),
	.R(1'b0),
	.S(1'b0)
);

hpdmc_iddr32 iddr_dq(
	.Q0(di[31:0]),
	.Q1(di[63:32]),
	.C0(sys_clk),
	.C1(sys_clk_n),
	.CE(1'b1),
	.D(sdram_dq),
	.R(1'b0),
	.S(1'b0)
);

/*******/
/* DQM */
/*******/

hpdmc_oddr4 oddr_dqm(
	.Q(sdram_dqm),
	.C0(sys_clk),
	.C1(sys_clk_n),
	.CE(1'b1),
	.D0(mo[7:4]),
	.D1(mo[3:0]),
	.R(1'b0),
	.S(1'b0)
);

/*******/
/* DQS */
/*******/

wire [3:0] sdram_dqs_out;
assign sdram_dqs = direction ? {4{sdram_dqs_out}} : 4'hz;

hpdmc_oddr4 oddr_dqs(
	.Q(sdram_dqs_out),
	.C0(dqs_clk),
	.C1(dqs_clk_n),
	.CE(1'b1),
	.D0(4'hf),
	.D1(4'h0),
	.R(1'b0),
	.S(1'b0)
);

endmodule
