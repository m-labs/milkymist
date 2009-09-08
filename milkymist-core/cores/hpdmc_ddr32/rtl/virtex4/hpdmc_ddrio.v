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
	input direction_r,
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

wire [31:0] sdram_data_out;
assign sdram_dq = direction ? sdram_data_out : 32'hzzzzzzzz;
assign sdram_dqs = direction ? {4{dqs_clk}} : 4'hz;

hpdmc_oddr4 oddr_dqm(
	.Q(sdram_dqm),
	.C(sys_clk),
	.CE(1'b1),
	.D1(mo[7:4]),
	.D2(mo[3:0]),
	.R(1'b0),
	.S(1'b0)
);

hpdmc_oddr32 oddr_dq(
	.Q(sdram_data_out),
	.C(sys_clk),
	.CE(1'b1),
	.D1(do[63:32]),
	.D2(do[31:0]),
	.R(1'b0),
	.S(1'b0)
);

wire [31:0] sdram_dq_delayed;

hpdmc_idelay8 dq_delay0 (
	.i(sdram_dq[7:0]),
	.o(sdram_dq_delayed[7:0]),
	
	.clk(sys_clk),
	.rst(idelay_rst),
	.ce(idelay_ce),
	.inc(idelay_inc)
);
hpdmc_idelay8 dq_delay1 (
	.i(sdram_dq[15:8]),
	.o(sdram_dq_delayed[15:8]),
	
	.clk(sys_clk),
	.rst(idelay_rst),
	.ce(idelay_ce),
	.inc(idelay_inc)
);
hpdmc_idelay8 dq_delay2 (
	.i(sdram_dq[23:16]),
	.o(sdram_dq_delayed[23:16]),
	
	.clk(sys_clk),
	.rst(idelay_rst),
	.ce(idelay_ce),
	.inc(idelay_inc)
);
hpdmc_idelay8 dq_delay3 (
	.i(sdram_dq[31:24]),
	.o(sdram_dq_delayed[31:24]),
	
	.clk(sys_clk),
	.rst(idelay_rst),
	.ce(idelay_ce),
	.inc(idelay_inc)
);

hpdmc_iddr32 iddr_dq(
	.Q1(di[31:0]),
	.Q2(di[63:32]),
	.C(sys_clk),
	.CE(1'b1),
	.D(sdram_dq_delayed),
	.R(1'b0),
	.S(1'b0)
);

endmodule
