/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009, 2010 Sebastien Bourdeauducq
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
 
module xbar(
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

	// Master 6 Interface
	input	[31:0]	m6_dat_i,
	output	[31:0]	m6_dat_o,
	input	[31:0]	m6_adr_i,
	input	[2:0]	m6_cti_i,
	input	[3:0]	m6_sel_i,
	input		m6_we_i,
	input		m6_cyc_i,
	input		m6_stb_i,
	output		m6_ack_o,

	
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
	input		s4_ack_i
);

// internal CPU to RAM bus
wire [31:0] ctr_dat_r;
wire [31:0] ctr_dat_w;
wire [31:0] ctr_adr;
wire [2:0] ctr_cti;
wire [3:0] ctr_sel;
wire ctr_we;
wire ctr_cyc;
wire ctr_stb;
wire ctr_ack;

// norflash     0x00000000 (shadow @0x80000000)
// debug        0x10000000 (shadow @0x90000000)
// USB          0x20000000 (shadow @0xa0000000)
// SDRAM        0x40000000 (shadow @0xc0000000)
// CSR bridge   0x60000000 (shadow @0xe0000000)

// MSB (Bit 31) is ignored for slave address decoding
conbus2x5 #(
	.s0_addr(3'b000), // norflash
	.s1_addr(3'b001), // debug
	.s2_addr(2'b01),  // USB
	.s3_addr(2'b11),  // CSR
	.s4_addr(2'b10)   // to second arbiter (SDRAM)
) con1 (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	// Master 0
	.m0_dat_i(m0_dat_i),
	.m0_dat_o(m0_dat_o),
	.m0_adr_i(m0_adr_i),
	.m0_cti_i(m0_cti_i),
	.m0_we_i(m0_we_i),
	.m0_sel_i(m0_sel_i),
	.m0_cyc_i(m0_cyc_i),
	.m0_stb_i(m0_stb_i),
	.m0_ack_o(m0_ack_o),
	// Master 1
	.m1_dat_i(m1_dat_i),
	.m1_dat_o(m1_dat_o),
	.m1_adr_i(m1_adr_i),
	.m1_cti_i(m1_cti_i),
	.m1_we_i(m1_we_i),
	.m1_sel_i(m1_sel_i),
	.m1_cyc_i(m1_cyc_i),
	.m1_stb_i(m1_stb_i),
	.m1_ack_o(m1_ack_o),
	
	// Slave 0
	.s0_dat_i(s0_dat_i),
	.s0_dat_o(s0_dat_o),
	.s0_adr_o(s0_adr_o),
	.s0_cti_o(s0_cti_o),
	.s0_sel_o(s0_sel_o),
	.s0_we_o(s0_we_o),
	.s0_cyc_o(s0_cyc_o),
	.s0_stb_o(s0_stb_o),
	.s0_ack_i(s0_ack_i),
	// Slave 1
	.s1_dat_i(s1_dat_i),
	.s1_dat_o(s1_dat_o),
	.s1_adr_o(s1_adr_o),
	.s1_cti_o(s1_cti_o),
	.s1_sel_o(s1_sel_o),
	.s1_we_o(s1_we_o),
	.s1_cyc_o(s1_cyc_o),
	.s1_stb_o(s1_stb_o),
	.s1_ack_i(s1_ack_i),
	// Slave 2
	.s2_dat_i(s2_dat_i),
	.s2_dat_o(s2_dat_o),
	.s2_adr_o(s2_adr_o),
	.s2_cti_o(s2_cti_o),
	.s2_sel_o(s2_sel_o),
	.s2_we_o(s2_we_o),
	.s2_cyc_o(s2_cyc_o),
	.s2_stb_o(s2_stb_o),
	.s2_ack_i(s2_ack_i),
	// Slave 3
	.s3_dat_i(s3_dat_i),
	.s3_dat_o(s3_dat_o),
	.s3_adr_o(s3_adr_o),
	.s3_cti_o(s3_cti_o),
	.s3_sel_o(s3_sel_o),
	.s3_we_o(s3_we_o),
	.s3_cyc_o(s3_cyc_o),
	.s3_stb_o(s3_stb_o),
	.s3_ack_i(s3_ack_i),
	// Slave 4
	.s4_dat_i(ctr_dat_r),
	.s4_dat_o(ctr_dat_w),
	.s4_adr_o(ctr_adr),
	.s4_cti_o(ctr_cti),
	.s4_sel_o(ctr_sel),
	.s4_we_o(ctr_we),
	.s4_cyc_o(ctr_cyc),
	.s4_stb_o(ctr_stb),
	.s4_ack_i(ctr_ack)
);

conbus6x1 con2(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	// Master 0
	.m0_dat_i(ctr_dat_w),
	.m0_dat_o(ctr_dat_r),
	.m0_adr_i(ctr_adr),
	.m0_cti_i(ctr_cti),
	.m0_we_i(ctr_we),
	.m0_sel_i(ctr_sel),
	.m0_cyc_i(ctr_cyc),
	.m0_stb_i(ctr_stb),
	.m0_ack_o(ctr_ack),
	// Master 1
	.m1_dat_i(m2_dat_i),
	.m1_dat_o(m2_dat_o),
	.m1_adr_i(m2_adr_i),
	.m1_cti_i(m2_cti_i),
	.m1_we_i(m2_we_i),
	.m1_sel_i(m2_sel_i),
	.m1_cyc_i(m2_cyc_i),
	.m1_stb_i(m2_stb_i),
	.m1_ack_o(m2_ack_o),
	// Master 2
	.m2_dat_i(m3_dat_i),
	.m2_dat_o(m3_dat_o),
	.m2_adr_i(m3_adr_i),
	.m2_cti_i(m3_cti_i),
	.m2_we_i(m3_we_i),
	.m2_sel_i(m3_sel_i),
	.m2_cyc_i(m3_cyc_i),
	.m2_stb_i(m3_stb_i),
	.m2_ack_o(m3_ack_o),
	// Master 3
	.m3_dat_i(m4_dat_i),
	.m3_dat_o(m4_dat_o),
	.m3_adr_i(m4_adr_i),
	.m3_cti_i(m4_cti_i),
	.m3_we_i(m4_we_i),
	.m3_sel_i(m4_sel_i),
	.m3_cyc_i(m4_cyc_i),
	.m3_stb_i(m4_stb_i),
	.m3_ack_o(m4_ack_o),
	// Master 4
	.m4_dat_i(m5_dat_i),
	.m4_dat_o(m5_dat_o),
	.m4_adr_i(m5_adr_i),
	.m4_cti_i(m5_cti_i),
	.m4_we_i(m5_we_i),
	.m4_sel_i(m5_sel_i),
	.m4_cyc_i(m5_cyc_i),
	.m4_stb_i(m5_stb_i),
	.m4_ack_o(m5_ack_o),
	// Master 5
	.m5_dat_i(m6_dat_i),
	.m5_dat_o(m6_dat_o),
	.m5_adr_i(m6_adr_i),
	.m5_cti_i(m6_cti_i),
	.m5_we_i(m6_we_i),
	.m5_sel_i(m6_sel_i),
	.m5_cyc_i(m6_cyc_i),
	.m5_stb_i(m6_stb_i),
	.m5_ack_o(m6_ack_o),
	
	// Slave
	.s_dat_i(s4_dat_i),
	.s_dat_o(s4_dat_o),
	.s_adr_o(s4_adr_o),
	.s_cti_o(s4_cti_o),
	.s_sel_o(s4_sel_o),
	.s_we_o(s4_we_o),
	.s_cyc_o(s4_cyc_o),
	.s_stb_o(s4_stb_o),
	.s_ack_i(s4_ack_i)
);

endmodule
