/*
 * Milkymist SoC
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

module tb_conbus();

reg sys_rst;
reg sys_clk;

//------------------------------------------------------------------
// Wishbone master wires
//------------------------------------------------------------------
wire [31:0]	m0_adr,
		m1_adr,
		m2_adr,
		m3_adr,
		m4_adr;

wire [2:0]	m0_cti,
		m1_cti,
		m2_cti,
		m3_cti,
		m4_cti;

wire [31:0]	m0_dat_r,
		m0_dat_w,
		m1_dat_r,
		m1_dat_w,
		m2_dat_r,
		m2_dat_w,
		m3_dat_r,
		m3_dat_w,
		m4_dat_r,
		m4_dat_w;

wire [3:0]	m0_sel,
		m1_sel,
		m2_sel,
		m3_sel,
		m4_sel;

wire		m0_we,
		m1_we,
		m2_we,
		m3_we,
		m4_we;

wire		m0_cyc,
		m1_cyc,
		m2_cyc,
		m3_cyc,
		m4_cyc;

wire		m0_stb,
		m1_stb,
		m2_stb,
		m3_stb,
		m4_stb;

wire		m0_ack,
		m1_ack,
		m2_ack,
		m3_ack,
		m4_ack;

//------------------------------------------------------------------
// Wishbone slave wires
//------------------------------------------------------------------
wire [31:0]	s0_adr,
		s1_adr,
		s2_adr,
		s3_adr,
		s4_adr;

wire [2:0]	s0_cti,
		s1_cti,
		s2_cti,
		s3_cti,
		s4_cti;

wire [31:0]	s0_dat_r,
		s0_dat_w,
		s1_dat_r,
		s1_dat_w,
		s2_dat_r,
		s2_dat_w,
		s3_dat_r,
		s3_dat_w,
		s4_dat_r,
		s4_dat_w;

wire [3:0]	s0_sel,
		s1_sel,
		s2_sel,
		s3_sel,
		s4_sel;

wire		s0_we,
		s1_we,
		s2_we,
		s3_we,
		s4_we;

wire		s0_cyc,
		s1_cyc,
		s2_cyc,
		s3_cyc,
		s4_cyc;

wire		s0_stb,
		s1_stb,
		s2_stb,
		s3_stb,
		s4_stb;

wire		s0_ack,
		s1_ack,
		s2_ack,
		s3_ack,
		s4_ack;

//---------------------------------------------------------------------------
// Wishbone switch
//---------------------------------------------------------------------------
conbus #(
	.s_addr_w(3),
	.s0_addr(3'b000),	// 0x00000000
	.s1_addr(3'b001),	// 0x20000000
	.s2_addr(3'b010),	// 0x40000000
	.s3_addr(3'b011),	// 0x60000000
	.s4_addr(3'b100)	// 0x80000000
) dut (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	// Master 0
	.m0_dat_i(m0_dat_w),
	.m0_dat_o(m0_dat_r),
	.m0_adr_i(m0_adr),
	.m0_cti_i(m0_cti),
	.m0_we_i(m0_we),
	.m0_sel_i(m0_sel),
	.m0_cyc_i(m0_cyc),
	.m0_stb_i(m0_stb),
	.m0_ack_o(m0_ack),
	// Master 1
	.m1_dat_i(m1_dat_w),
	.m1_dat_o(m1_dat_r),
	.m1_adr_i(m1_adr),
	.m1_cti_i(m1_cti),
	.m1_we_i(m1_we),
	.m1_sel_i(m1_sel),
	.m1_cyc_i(m1_cyc),
	.m1_stb_i(m1_stb),
	.m1_ack_o(m1_ack),
	// Master 2
	.m2_dat_i(m2_dat_w),
	.m2_dat_o(m2_dat_r),
	.m2_adr_i(m2_adr),
	.m2_cti_i(m2_cti),
	.m2_we_i(m2_we),
	.m2_sel_i(m2_sel),
	.m2_cyc_i(m2_cyc),
	.m2_stb_i(m2_stb),
	.m2_ack_o(m2_ack),
	// Master 3
	.m3_dat_i(m3_dat_w),
	.m3_dat_o(m3_dat_r),
	.m3_adr_i(m3_adr),
	.m3_cti_i(m3_cti),
	.m3_we_i(m3_we),
	.m3_sel_i(m3_sel),
	.m3_cyc_i(m3_cyc),
	.m3_stb_i(m3_stb),
	.m3_ack_o(m3_ack),
	// Master 4
	.m4_dat_i(m4_dat_w),
	.m4_dat_o(m4_dat_r),
	.m4_adr_i(m4_adr),
	.m4_cti_i(m4_cti),
	.m4_we_i(m4_we),
	.m4_sel_i(m4_sel),
	.m4_cyc_i(m4_cyc),
	.m4_stb_i(m4_stb),
	.m4_ack_o(m4_ack),

	// Slave 0
	.s0_dat_i(s0_dat_r),
	.s0_dat_o(s0_dat_w),
	.s0_adr_o(s0_adr),
	.s0_cti_o(s0_cti),
	.s0_sel_o(s0_sel),
	.s0_we_o(s0_we),
	.s0_cyc_o(s0_cyc),
	.s0_stb_o(s0_stb),
	.s0_ack_i(s0_ack),
	// Slave 1
	.s1_dat_i(s1_dat_r),
	.s1_dat_o(s1_dat_w),
	.s1_adr_o(s1_adr),
	.s1_cti_o(s1_cti),
	.s1_sel_o(s1_sel),
	.s1_we_o(s1_we),
	.s1_cyc_o(s1_cyc),
	.s1_stb_o(s1_stb),
	.s1_ack_i(s1_ack),
	// Slave 2
	.s2_dat_i(s2_dat_r),
	.s2_dat_o(s2_dat_w),
	.s2_adr_o(s2_adr),
	.s2_cti_o(s2_cti),
	.s2_sel_o(s2_sel),
	.s2_we_o(s2_we),
	.s2_cyc_o(s2_cyc),
	.s2_stb_o(s2_stb),
	.s2_ack_i(s2_ack),
	// Slave 3
	.s3_dat_i(s3_dat_r),
	.s3_dat_o(s3_dat_w),
	.s3_adr_o(s3_adr),
	.s3_cti_o(s3_cti),
	.s3_sel_o(s3_sel),
	.s3_we_o(s3_we),
	.s3_cyc_o(s3_cyc),
	.s3_stb_o(s3_stb),
	.s3_ack_i(s3_ack),
	// Slave 4
	.s4_dat_i(s4_dat_r),
	.s4_dat_o(s4_dat_w),
	.s4_adr_o(s4_adr),
	.s4_cti_o(s4_cti),
	.s4_sel_o(s4_sel),
	.s4_we_o(s4_we),
	.s4_cyc_o(s4_cyc),
	.s4_stb_o(s4_stb),
	.s4_ack_i(s4_ack)
);

//---------------------------------------------------------------------------
// Masters
//---------------------------------------------------------------------------

wire m0_end;
master #(
	.id(0)
) m0 (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.dat_w(m0_dat_w),
	.dat_r(m0_dat_r),
	.adr(m0_adr),
	.cti(m0_cti),
	.we(m0_we),
	.sel(m0_sel),
	.cyc(m0_cyc),
	.stb(m0_stb),
	.ack(m0_ack),
	
	.tend(m0_end)
);

wire m1_end;
master #(
	.id(1)
) m1 (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.dat_w(m1_dat_w),
	.dat_r(m1_dat_r),
	.adr(m1_adr),
	.cti(m1_cti),
	.we(m1_we),
	.sel(m1_sel),
	.cyc(m1_cyc),
	.stb(m1_stb),
	.ack(m1_ack),
	
	.tend(m1_end)
);

wire m2_end;
master #(
	.id(2)
) m2 (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.dat_w(m2_dat_w),
	.dat_r(m2_dat_r),
	.adr(m2_adr),
	.cti(m2_cti),
	.we(m2_we),
	.sel(m2_sel),
	.cyc(m2_cyc),
	.stb(m2_stb),
	.ack(m2_ack),
	
	.tend(m2_end)
);

wire m3_end;
master #(
	.id(3)
) m3 (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.dat_w(m3_dat_w),
	.dat_r(m3_dat_r),
	.adr(m3_adr),
	.cti(m3_cti),
	.we(m3_we),
	.sel(m3_sel),
	.cyc(m3_cyc),
	.stb(m3_stb),
	.ack(m3_ack),
	
	.tend(m3_end)
);

wire m4_end;
master #(
	.id(4)
) m4 (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.dat_w(m4_dat_w),
	.dat_r(m4_dat_r),
	.adr(m4_adr),
	.cti(m4_cti),
	.we(m4_we),
	.sel(m4_sel),
	.cyc(m4_cyc),
	.stb(m4_stb),
	.ack(m4_ack),
	
	.tend(m4_end)
);

//---------------------------------------------------------------------------
// Slaves
//---------------------------------------------------------------------------

slave #(
	.id(0)
) s0 (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.dat_w(s0_dat_w),
	.dat_r(s0_dat_r),
	.adr(s0_adr),
	.cti(s0_cti),
	.we(s0_we),
	.sel(s0_sel),
	.cyc(s0_cyc),
	.stb(s0_stb),
	.ack(s0_ack)
);

slave #(
	.id(1)
) s1 (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.dat_w(s1_dat_w),
	.dat_r(s1_dat_r),
	.adr(s1_adr),
	.cti(s1_cti),
	.we(s1_we),
	.sel(s1_sel),
	.cyc(s1_cyc),
	.stb(s1_stb),
	.ack(s1_ack)
);

slave #(
	.id(2)
) s2 (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.dat_w(s2_dat_w),
	.dat_r(s2_dat_r),
	.adr(s2_adr),
	.cti(s2_cti),
	.we(s2_we),
	.sel(s2_sel),
	.cyc(s2_cyc),
	.stb(s2_stb),
	.ack(s2_ack)
);

slave #(
	.id(3)
) s3 (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.dat_w(s3_dat_w),
	.dat_r(s3_dat_r),
	.adr(s3_adr),
	.cti(s3_cti),
	.we(s3_we),
	.sel(s3_sel),
	.cyc(s3_cyc),
	.stb(s3_stb),
	.ack(s3_ack)
);

slave #(
	.id(4)
) s4 (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.dat_w(s4_dat_w),
	.dat_r(s4_dat_r),
	.adr(s4_adr),
	.cti(s4_cti),
	.we(s4_we),
	.sel(s4_sel),
	.cyc(s4_cyc),
	.stb(s4_stb),
	.ack(s4_ack)
);

initial sys_clk = 1'b0;
always #5 sys_clk = ~sys_clk;

wire all_end = m0_end & m1_end & m2_end & m3_end & m4_end;

always begin
	sys_rst = 1'b1;
	@(posedge sys_clk);
	#1 sys_rst = 1'b0;
	@(posedge all_end);
	$finish;
end

endmodule

