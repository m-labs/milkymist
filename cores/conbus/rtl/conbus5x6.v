/*
 * Wishbone Arbiter and Address Decoder
 * Copyright (C) 2008, 2009, 2010, 2011 Sebastien Bourdeauducq
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

module conbus5x6 #(
	parameter s0_addr = 3'b000,
	parameter s1_addr = 3'b001,
	parameter s2_addr = 3'b010,
	parameter s3_addr = 3'b011,
	parameter s4_addr = 2'b10,
	parameter s5_addr = 2'b11
) (
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


	// Slave 0 Interface
	input	[31:0]	s0_dat_i,
	output	[31:0]	s0_dat_o,
	output	[31:0]	s0_adr_o,
	output	[2:0]	s0_cti_o,
	output	[3:0]	s0_sel_o,
	output		s0_we_o,
	output		s0_cyc_o,
	output		s0_stb_o,
	input		s0_ack_i,
	
	// Slave 1 Interface
	input	[31:0]	s1_dat_i,
	output	[31:0]	s1_dat_o,
	output	[31:0]	s1_adr_o,
	output	[2:0]	s1_cti_o,
	output	[3:0]	s1_sel_o,
	output		s1_we_o,
	output		s1_cyc_o,
	output		s1_stb_o,
	input		s1_ack_i,
	
	// Slave 2 Interface
	input	[31:0]	s2_dat_i,
	output	[31:0]	s2_dat_o,
	output	[31:0]	s2_adr_o,
	output	[2:0]	s2_cti_o,
	output	[3:0]	s2_sel_o,
	output		s2_we_o,
	output		s2_cyc_o,
	output		s2_stb_o,
	input		s2_ack_i,
	
	// Slave 3 Interface
	input	[31:0]	s3_dat_i,
	output	[31:0]	s3_dat_o,
	output	[31:0]	s3_adr_o,
	output	[2:0]	s3_cti_o,
	output	[3:0]	s3_sel_o,
	output		s3_we_o,
	output		s3_cyc_o,
	output		s3_stb_o,
	input		s3_ack_i,
	
	// Slave 4 Interface
	input	[31:0]	s4_dat_i,
	output	[31:0]	s4_dat_o,
	output	[31:0]	s4_adr_o,
	output	[2:0]	s4_cti_o,
	output	[3:0]	s4_sel_o,
	output		s4_we_o,
	output		s4_cyc_o,
	output		s4_stb_o,
	input		s4_ack_i,
	
	// Slave 5 Interface
	input	[31:0]	s5_dat_i,
	output	[31:0]	s5_dat_o,
	output	[31:0]	s5_adr_o,
	output	[2:0]	s5_cti_o,
	output	[3:0]	s5_sel_o,
	output		s5_we_o,
	output		s5_cyc_o,
	output		s5_stb_o,
	input		s5_ack_i
);

// address + CTI + data + byte select
// + cyc + we + stb
`define mbusw_ls  32 + 3 + 32 + 4 + 3

wire [5:0] slave_sel;
wire [2:0] gnt;
reg [`mbusw_ls -1:0] i_bus_m;	// internal shared bus, master data and control to slave
wire [31:0] i_dat_s;		// internal shared bus, slave data to master
wire i_bus_ack;			// internal shared bus, ack signal

// master 0
assign m0_dat_o = i_dat_s;
assign m0_ack_o = i_bus_ack & (gnt == 3'd0);

// master 1
assign m1_dat_o = i_dat_s;
assign m1_ack_o = i_bus_ack & (gnt == 3'd1);

// master 2
assign m2_dat_o = i_dat_s;
assign m2_ack_o = i_bus_ack & (gnt == 3'd2);

// master 3
assign m3_dat_o = i_dat_s;
assign m3_ack_o = i_bus_ack & (gnt == 3'd3);

// master 4
assign m4_dat_o = i_dat_s;
assign m4_ack_o = i_bus_ack & (gnt == 3'd4);

assign i_bus_ack = s0_ack_i | s1_ack_i | s2_ack_i | s3_ack_i | s4_ack_i | s5_ack_i;

// slave 0
assign {s0_adr_o, s0_cti_o, s0_sel_o, s0_dat_o, s0_we_o, s0_cyc_o, s0_stb_o} 
	= {i_bus_m[`mbusw_ls -1:2], i_bus_m[1] & slave_sel[0], i_bus_m[0]};

// slave 1
assign {s1_adr_o, s1_cti_o, s1_sel_o, s1_dat_o, s1_we_o, s1_cyc_o, s1_stb_o} 
	= {i_bus_m[`mbusw_ls -1:2], i_bus_m[1] & slave_sel[1], i_bus_m[0]};

// slave 2
assign {s2_adr_o, s2_cti_o, s2_sel_o, s2_dat_o, s2_we_o, s2_cyc_o, s2_stb_o} 
	= {i_bus_m[`mbusw_ls -1:2], i_bus_m[1] & slave_sel[2], i_bus_m[0]};

// slave 3
assign {s3_adr_o, s3_cti_o, s3_sel_o, s3_dat_o, s3_we_o, s3_cyc_o, s3_stb_o} 
	= {i_bus_m[`mbusw_ls -1:2], i_bus_m[1] & slave_sel[3], i_bus_m[0]};

// slave 4
assign {s4_adr_o, s4_cti_o, s4_sel_o, s4_dat_o, s4_we_o, s4_cyc_o, s4_stb_o} 
	= {i_bus_m[`mbusw_ls -1:2], i_bus_m[1] & slave_sel[4], i_bus_m[0]};

// slave 5
assign {s5_adr_o, s5_cti_o, s5_sel_o, s5_dat_o, s5_we_o, s5_cyc_o, s5_stb_o} 
	= {i_bus_m[`mbusw_ls -1:2], i_bus_m[1] & slave_sel[5], i_bus_m[0]};

always @(*) begin
	case(gnt)
		3'd0:    i_bus_m = {m0_adr_i, m0_cti_i, m0_sel_i, m0_dat_i, m0_we_i, m0_cyc_i, m0_stb_i};
		3'd1:    i_bus_m = {m1_adr_i, m1_cti_i, m1_sel_i, m1_dat_i, m1_we_i, m1_cyc_i, m1_stb_i};
		3'd2:    i_bus_m = {m2_adr_i, m2_cti_i, m2_sel_i, m2_dat_i, m2_we_i, m2_cyc_i, m2_stb_i};
		3'd3:    i_bus_m = {m3_adr_i, m3_cti_i, m3_sel_i, m3_dat_i, m3_we_i, m3_cyc_i, m3_stb_i};
		default: i_bus_m = {m4_adr_i, m4_cti_i, m4_sel_i, m4_dat_i, m4_we_i, m4_cyc_i, m4_stb_i};
	endcase
end

// !!!! This breaks WISHBONE combinatorial feedback. Don't use it !!!!
reg [5:0] slave_sel_r;
always @(posedge sys_clk)
	slave_sel_r <= slave_sel;
// !!!! This breaks WISHBONE combinatorial feedback. Don't use it !!!!

assign i_dat_s =
		 ({32{slave_sel_r[0]}} & s0_dat_i)
		|({32{slave_sel_r[1]}} & s1_dat_i)
		|({32{slave_sel_r[2]}} & s2_dat_i)
		|({32{slave_sel_r[3]}} & s3_dat_i)
		|({32{slave_sel_r[4]}} & s4_dat_i)
		|({32{slave_sel_r[5]}} & s5_dat_i);

wire [4:0] req = {m4_cyc_i, m3_cyc_i, m2_cyc_i, m1_cyc_i, m0_cyc_i};

conbus_arb5 arb(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.req(req),
	.gnt(gnt)
);

assign slave_sel[0] = (i_bus_m[`mbusw_ls-2 : `mbusw_ls-3-1] == s0_addr);
assign slave_sel[1] = (i_bus_m[`mbusw_ls-2 : `mbusw_ls-3-1] == s1_addr);
assign slave_sel[2] = (i_bus_m[`mbusw_ls-2 : `mbusw_ls-3-1] == s2_addr);
assign slave_sel[3] = (i_bus_m[`mbusw_ls-2 : `mbusw_ls-3-1] == s3_addr);
assign slave_sel[4] = (i_bus_m[`mbusw_ls-2 : `mbusw_ls-2-1] == s4_addr);
assign slave_sel[5] = (i_bus_m[`mbusw_ls-2 : `mbusw_ls-2-1] == s5_addr);

endmodule
