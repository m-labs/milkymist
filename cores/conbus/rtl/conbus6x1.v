/*
 * Wishbone Arbiter and Address Decoder
 * Copyright (C) 2008, 2009, 2010 Sebastien Bourdeauducq
 * Copyright (C) 2000 Johny Chi - chisuhua@yahoo.com.cn
 * This file is part of Milkymist.
 *
 * This source file may be used and distributed without
 * restriction provided that this copyright statement is not
 * removed from the file and that any derivative work contains
 * the original copyright notice and the associated disclaimer.
 *
 * This source file is free software; you can redistribute it
 * and/or modify it under the terms of the GNU Lesser General
 * Public License as published by the Free Software Foundation;
 * either version 2.1 of the License, or (at your option) any
 * later version.
 *
 * This source is distributed in the hope that it will be
 * useful, but WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 * PURPOSE.  See the GNU Lesser General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Lesser General
 * Public License along with this source; if not, download it
 * from http://www.opencores.org/lgpl.shtml.
 */

module conbus6x1(
	input sys_clk,
	input sys_rst,
	
	// Master 0 Interface
	input	[31:0]	m0_dat_i,
	output	[31:0]	m0_dat_o,
	input	[31:0]	m0_adr_i,
	input	[2:0]	m0_cti_i,
	input	[3:0]	m0_sel_i,
	input		m0_we_i,
	input		m0_cyc_i,
	input		m0_stb_i,
	output		m0_ack_o,
	
	// Master 1 Interface
	input	[31:0]	m1_dat_i,
	output	[31:0]	m1_dat_o,
	input	[31:0]	m1_adr_i,
	input	[2:0]	m1_cti_i,
	input	[3:0]	m1_sel_i,
	input		m1_we_i,
	input		m1_cyc_i,
	input		m1_stb_i,
	output		m1_ack_o,
	
	// Master 2 Interface
	input	[31:0]	m2_dat_i,
	output	[31:0]	m2_dat_o,
	input	[31:0]	m2_adr_i,
	input	[2:0]	m2_cti_i,
	input	[3:0]	m2_sel_i,
	input		m2_we_i,
	input		m2_cyc_i,
	input		m2_stb_i,
	output		m2_ack_o,
	
	// Master 3 Interface
	input	[31:0]	m3_dat_i,
	output	[31:0]	m3_dat_o,
	input	[31:0]	m3_adr_i,
	input	[2:0]	m3_cti_i,
	input	[3:0]	m3_sel_i,
	input		m3_we_i,
	input		m3_cyc_i,
	input		m3_stb_i,
	output		m3_ack_o,
	
	// Master 4 Interface
	input	[31:0]	m4_dat_i,
	output	[31:0]	m4_dat_o,
	input	[31:0]	m4_adr_i,
	input	[2:0]	m4_cti_i,
	input	[3:0]	m4_sel_i,
	input		m4_we_i,
	input		m4_cyc_i,
	input		m4_stb_i,
	output		m4_ack_o,

	// Master 5 Interface
	input	[31:0]	m5_dat_i,
	output	[31:0]	m5_dat_o,
	input	[31:0]	m5_adr_i,
	input	[2:0]	m5_cti_i,
	input	[3:0]	m5_sel_i,
	input		m5_we_i,
	input		m5_cyc_i,
	input		m5_stb_i,
	output		m5_ack_o,

	// Slave Interface
	input	[31:0]	s_dat_i,
	output	[31:0]	s_dat_o,
	output	[31:0]	s_adr_o,
	output	[2:0]	s_cti_o,
	output	[3:0]	s_sel_o,
	output		s_we_o,
	output		s_cyc_o,
	output		s_stb_o,
	input		s_ack_i
);

// address + CTI + data + byte select
// + cyc + we + stb
`define mbusw_ls  32 + 3 + 32 + 4 + 3

wire [2:0] gnt;
reg [`mbusw_ls -1:0] i_bus_m;	// internal shared bus, master data and control to slave
wire [31:0] i_dat_s;		// internal shared bus, slave data to master
wire i_bus_ack;			// internal shared bus, ack signal

// !!!! This breaks WISHBONE combinatorial feedback. Don't use it !!!!
reg [5:0] gnt_dec;
always @(posedge sys_clk) begin
	case(gnt)
		3'd0: gnt_dec <= 6'b000001;
		3'd1: gnt_dec <= 6'b000010;
		3'd2: gnt_dec <= 6'b000100;
		3'd3: gnt_dec <= 6'b001000;
		3'd4: gnt_dec <= 6'b010000;
		3'd5: gnt_dec <= 6'b100000;
		default: gnt_dec <= 6'bxxxxxx;
	endcase
end
// !!!! This breaks WISHBONE combinatorial feedback. Don't use it !!!!

// master 0
assign m0_dat_o = i_dat_s;
assign m0_ack_o = i_bus_ack & gnt_dec[0];

// master 1
assign m1_dat_o = i_dat_s;
assign m1_ack_o = i_bus_ack & gnt_dec[1];

// master 2
assign m2_dat_o = i_dat_s;
assign m2_ack_o = i_bus_ack & gnt_dec[2];

// master 3
assign m3_dat_o = i_dat_s;
assign m3_ack_o = i_bus_ack & gnt_dec[3];

// master 4
assign m4_dat_o = i_dat_s;
assign m4_ack_o = i_bus_ack & gnt_dec[4];

// master 5
assign m5_dat_o = i_dat_s;
assign m5_ack_o = i_bus_ack & gnt_dec[5];

assign i_bus_ack = s_ack_i;

// slave
assign {s_adr_o, s_cti_o, s_sel_o, s_dat_o, s_we_o, s_cyc_o, s_stb_o} = i_bus_m;

always @(*) begin
	case(gnt)
		3'd0: i_bus_m = {m0_adr_i, m0_cti_i, m0_sel_i, m0_dat_i, m0_we_i, m0_cyc_i, m0_stb_i};
		3'd1: i_bus_m = {m1_adr_i, m1_cti_i, m1_sel_i, m1_dat_i, m1_we_i, m1_cyc_i, m1_stb_i};
		3'd2: i_bus_m = {m2_adr_i, m2_cti_i, m2_sel_i, m2_dat_i, m2_we_i, m2_cyc_i, m2_stb_i};
		3'd3: i_bus_m = {m3_adr_i, m3_cti_i, m3_sel_i, m3_dat_i, m3_we_i, m3_cyc_i, m3_stb_i};
		3'd4: i_bus_m = {m4_adr_i, m4_cti_i, m4_sel_i, m4_dat_i, m4_we_i, m4_cyc_i, m4_stb_i};
		3'd5: i_bus_m = {m5_adr_i, m5_cti_i, m5_sel_i, m5_dat_i, m5_we_i, m5_cyc_i, m5_stb_i};
		default: i_bus_m = {`mbusw_ls{1'bx}};
	endcase
end

assign i_dat_s = s_dat_i;

wire [5:0] req = {m5_cyc_i, m4_cyc_i, m3_cyc_i, m2_cyc_i, m1_cyc_i, m0_cyc_i};

conbus_arb6 arb(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.req(req),
	.gnt(gnt)
);

endmodule
