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

module tmu #(
	parameter csr_addr = 4'h0,
	parameter fml_depth = 26,
	parameter pixin_cache_depth = 12 /* 4kb cache */
) (
	/* Global clock and reset signals */
	input sys_clk,
	input sys_rst,
	
	/* Control interface */
	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output [31:0] csr_do,
	
	output irq,
	
	/* WB master - Mesh read. */
	output [31:0] wbm_adr_o,
	output [2:0] wbm_cti_o,
	output wbm_cyc_o,
	output wbm_stb_o,
	input wbm_ack_i,
	input [31:0] wbm_dat_i,
	
	/* FML master - Pixel read. fml_we=0 is assumed. */
	output [fml_depth-1:0] fmlr_adr,
	output fmlr_stb,
	input fmlr_ack,
	input [63:0] fmlr_di,
	
	/* FML master - Pixel write. fml_we=1 is assumed. */
	output [fml_depth-1:0] fmlw_adr,
	output fmlw_stb,
	input fmlw_ack,
	output [7:0] fmlw_sel,
	output [63:0] fmlw_do
);

wire start;
reg busy;
wire [6:0] hmesh_last;
wire [6:0] vmesh_last;
wire [5:0] brightness;
wire chroma_key_en;
wire [15:0] chroma_key;
wire [29:0] src_mesh;
wire [fml_depth-1-1:0] src_fbuf;
wire [10:0] src_hres;
wire [10:0] src_vres;
wire [29:0] dst_mesh;
wire [fml_depth-1-1:0] dst_fbuf;
wire [10:0] dst_hres;
wire [10:0] dst_vres;
wire [31:0] perf_pixels;
wire [31:0] perf_clocks;
wire [31:0] perf_stall1;
wire [31:0] perf_complete1;
wire [31:0] perf_stall2;
wire [31:0] perf_complete2;
wire [31:0] perf_misses;

tmu_ctlif #(
	.csr_addr(csr_addr),
	.fml_depth(fml_depth)
) ctlif (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_di),
	.csr_do(csr_do),
	
	.irq(irq),
	
	.start(start),
	.busy(busy),
	.hmesh_last(hmesh_last),
	.vmesh_last(vmesh_last),
	.brightness(brightness),
	.chroma_key_en(chroma_key_en),
	.chroma_key(chroma_key),
	.src_mesh(src_mesh),
	.src_fbuf(src_fbuf),
	.src_hres(src_hres),
	.src_vres(src_vres),
	.dst_mesh(dst_mesh),
	.dst_fbuf(dst_fbuf),
	.dst_hres(dst_hres),
	.dst_vres(dst_vres),

	.perf_pixels(perf_pixels),
	.perf_clocks(perf_clocks),
	.perf_stall1(perf_stall1),
	.perf_complete1(perf_complete1),
	.perf_stall2(perf_stall2),
	.perf_complete2(perf_complete2),
	.perf_misses(perf_misses)
);

/* Stage 1 - Fetch vertexes */
wire meshgen_busy;
wire meshgen_pipe_stb;
wire meshgen_pipe_ack;
wire signed [11:0] A0_S_X;
wire signed [11:0] A0_S_Y;
wire signed [11:0] B0_S_X;
wire signed [11:0] B0_S_Y;
wire signed [11:0] C0_S_X;
wire signed [11:0] C0_S_Y;
wire signed [11:0] A0_D_X;
wire signed [11:0] A0_D_Y;
wire signed [11:0] B0_D_X;
wire signed [11:0] B0_D_Y;
wire signed [11:0] C0_D_X;
wire signed [11:0] C0_D_Y;

tmu_meshgen meshgen(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.wbm_adr_o(wbm_adr_o),
	.wbm_cti_o(wbm_cti_o),
	.wbm_cyc_o(wbm_cyc_o),
	.wbm_stb_o(wbm_stb_o),
	.wbm_ack_i(wbm_ack_i),
	.wbm_dat_i(wbm_dat_i),
	
	.start(start),
	.busy(meshgen_busy),
	
	.hmesh_last(hmesh_last),
	.vmesh_last(vmesh_last),

	.src_mesh(src_mesh),
	.dst_mesh(dst_mesh),
	
	.pipe_stb(meshgen_pipe_stb),
	.pipe_ack(meshgen_pipe_ack),
	.A_S_X(A0_S_X),
	.A_S_Y(A0_S_Y),
	.B_S_X(B0_S_X),
	.B_S_Y(B0_S_Y),
	.C_S_X(C0_S_X),
	.C_S_Y(C0_S_Y),
	.A_D_X(A0_D_X),
	.A_D_Y(A0_D_Y),
	.B_D_X(B0_D_X),
	.B_D_Y(B0_D_Y),
	.C_D_X(C0_D_X),
	.C_D_Y(C0_D_Y)
);

/* Stage 2 - Vertex reordering (A_D_Y <= B_D_Y <= C_D_Y) */
wire reorder_busy;
wire reorder_pipe_stb;
wire reorder_pipe_ack;
wire signed [11:0] A_S_X;
wire signed [11:0] A_S_Y;
wire signed [11:0] B_S_X;
wire signed [11:0] B_S_Y;
wire signed [11:0] C_S_X;
wire signed [11:0] C_S_Y;
wire signed [11:0] A_D_X;
wire signed [11:0] A_D_Y;
wire signed [11:0] B_D_X;
wire signed [11:0] B_D_Y;
wire signed [11:0] C_D_X;
wire signed [11:0] C_D_Y;

tmu_reorder reorder(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.busy(reorder_busy),
	
	.pipe_stb_i(meshgen_pipe_stb),
	.pipe_ack_o(meshgen_pipe_ack),
	.A0_S_X(A0_S_X),
	.A0_S_Y(A0_S_Y),
	.B0_S_X(B0_S_X),
	.B0_S_Y(B0_S_Y),
	.C0_S_X(C0_S_X),
	.C0_S_Y(C0_S_Y),
	.A0_D_X(A0_D_X),
	.A0_D_Y(A0_D_Y),
	.B0_D_X(B0_D_X),
	.B0_D_Y(B0_D_Y),
	.C0_D_X(C0_D_X),
	.C0_D_Y(C0_D_Y),
	
	.pipe_stb_o(reorder_pipe_stb),
	.pipe_ack_i(reorder_pipe_ack),
	.A_S_X(A_S_X),
	.A_S_Y(A_S_Y),
	.B_S_X(B_S_X),
	.B_S_Y(B_S_Y),
	.C_S_X(C_S_X),
	.C_S_Y(C_S_Y),
	.A_D_X(A_D_X),
	.A_D_Y(A_D_Y),
	.B_D_X(B_D_X),
	.B_D_Y(B_D_Y),
	.C_D_X(C_D_X),
	.C_D_Y(C_D_Y)
);

/* Stage 3 - Compute edge division operands */
wire edgedivops_busy;
wire edgedivops_pipe_stb;
wire edgedivops_pipe_ack;
wire signed [11:0] A1_S_X;
wire signed [11:0] A1_S_Y;
wire signed [11:0] A1_D_X;
wire signed [11:0] A1_D_Y;
wire signed [11:0] B1_D_Y;
wire signed [11:0] C1_D_Y;
wire dx10_positive;
wire [10:0] dx10;
wire dx20_positive;
wire [10:0] dx20;
wire dx30_positive;
wire [10:0] dx30;
wire du10_positive;
wire [10:0] du10;
wire du20_positive;
wire [10:0] du20;
wire du30_positive;
wire [10:0] du30;
wire dv10_positive;
wire [10:0] dv10;
wire dv20_positive;
wire [10:0] dv20;
wire dv30_positive;
wire [10:0] dv30;
wire [10:0] divisor10;
wire [10:0] divisor20;
wire [10:0] divisor30;

tmu_edgedivops edgedivops(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.busy(edgedivops_busy),
	
	.pipe_stb_i(reorder_pipe_stb),
	.pipe_ack_o(reorder_pipe_ack),
	.A0_S_X(A_S_X),
	.A0_S_Y(A_S_Y),
	.B0_S_X(B_S_X),
	.B0_S_Y(B_S_Y),
	.C0_S_X(C_S_X),
	.C0_S_Y(C_S_Y),
	.A0_D_X(A_D_X),
	.A0_D_Y(A_D_Y),
	.B0_D_X(B_D_X),
	.B0_D_Y(B_D_Y),
	.C0_D_X(C_D_X),
	.C0_D_Y(C_D_Y),
	
	.pipe_stb_o(edgedivops_pipe_stb),
	.pipe_ack_i(edgedivops_pipe_ack),
	.A_S_X(A1_S_X),
	.A_S_Y(A1_S_Y),
	.A_D_X(A1_D_X),
	.A_D_Y(A1_D_Y),
	.B_D_Y(B1_D_Y),
	.C_D_Y(C1_D_Y),
	.dx1_positive(dx10_positive),
	.dx1(dx10),
	.dx2_positive(dx20_positive),
	.dx2(dx20),
	.dx3_positive(dx30_positive),
	.dx3(dx30),
	.du1_positive(du10_positive),
	.du1(du10),
	.du2_positive(du20_positive),
	.du2(du20),
	.du3_positive(du30_positive),
	.du3(du30),
	.dv1_positive(dv10_positive),
	.dv1(dv10),
	.dv2_positive(dv20_positive),
	.dv2(dv20),
	.dv3_positive(dv30_positive),
	.dv3(dv30),
	.divisor1(divisor10),
	.divisor2(divisor20),
	.divisor3(divisor30)
);

/* Stage 4 - Edge division */
wire edgediv_busy;
wire edgediv_pipe_stb;
wire edgediv_pipe_ack;
wire signed [11:0] A2_S_X;
wire signed [11:0] A2_S_Y;
wire signed [11:0] A2_D_X;
wire signed [11:0] A2_D_Y;
wire signed [11:0] B2_D_Y;
wire signed [11:0] C2_D_Y;
wire dx1_positive;
wire [10:0] dx1_q;
wire [10:0] dx1_r;
wire dx2_positive;
wire [10:0] dx2_q;
wire [10:0] dx2_r;
wire dx3_positive;
wire [10:0] dx3_q;
wire [10:0] dx3_r;
wire du1_positive;
wire [10:0] du1_q;
wire [10:0] du1_r;
wire du2_positive;
wire [10:0] du2_q;
wire [10:0] du2_r;
wire du3_positive;
wire [10:0] du3_q;
wire [10:0] du3_r;
wire dv1_positive;
wire [10:0] dv1_q;
wire [10:0] dv1_r;
wire dv2_positive;
wire [10:0] dv2_q;
wire [10:0] dv2_r;
wire dv3_positive;
wire [10:0] dv3_q;
wire [10:0] dv3_r;
wire [10:0] divisor1;
wire [10:0] divisor2;
wire [10:0] divisor3;

tmu_edgediv edgediv(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.busy(edgediv_busy),
	
	.pipe_stb_i(edgedivops_pipe_stb),
	.pipe_ack_o(edgedivops_pipe_ack),
	.A0_S_X(A1_S_X),
	.A0_S_Y(A1_S_Y),
	.A0_D_X(A1_D_X),
	.A0_D_Y(A1_D_Y),
	.B0_D_Y(B1_D_Y),
	.C0_D_Y(C1_D_Y),
	.dx10_positive(dx10_positive),
	.dx10(dx10),
	.dx20_positive(dx20_positive),
	.dx20(dx20),
	.dx30_positive(dx30_positive),
	.dx30(dx30),
	.du10_positive(du10_positive),
	.du10(du10),
	.du20_positive(du20_positive),
	.du20(du20),
	.du30_positive(du30_positive),
	.du30(du30),
	.dv10_positive(dv10_positive),
	.dv10(dv10),
	.dv20_positive(dv20_positive),
	.dv20(dv20),
	.dv30_positive(dv30_positive),
	.dv30(dv30),
	.divisor10(divisor10),
	.divisor20(divisor20),
	.divisor30(divisor30),
	
	.pipe_stb_o(edgediv_pipe_stb),
	.pipe_ack_i(edgediv_pipe_ack),
	.A_S_X(A2_S_X),
	.A_S_Y(A2_S_Y),
	.A_D_X(A2_D_X),
	.A_D_Y(A2_D_Y),
	.B_D_Y(B2_D_Y),
	.C_D_Y(C2_D_Y),
	.dx1_positive(dx1_positive),
	.dx1_q(dx1_q),
	.dx1_r(dx1_r),
	.dx2_positive(dx2_positive),
	.dx2_q(dx2_q),
	.dx2_r(dx2_r),
	.dx3_positive(dx3_positive),
	.dx3_q(dx3_q),
	.dx3_r(dx3_r),
	.du1_positive(du1_positive),
	.du1_q(du1_q),
	.du1_r(du1_r),
	.du2_positive(du2_positive),
	.du2_q(du2_q),
	.du2_r(du2_r),
	.du3_positive(du3_positive),
	.du3_q(du3_q),
	.du3_r(du3_r),
	.dv1_positive(dv1_positive),
	.dv1_q(dv1_q),
	.dv1_r(dv1_r),
	.dv2_positive(dv2_positive),
	.dv2_q(dv2_q),
	.dv2_r(dv2_r),
	.dv3_positive(dv3_positive),
	.dv3_q(dv3_q),
	.dv3_r(dv3_r),
	.divisor1(divisor1),
	.divisor2(divisor2),
	.divisor3(divisor3)
);

/* Stage 5 - Edge trace */
wire edgetrace_busy;
wire edgetrace_pipe_stb;
wire edgetrace_pipe_ack;
wire signed [11:0] Y0;
wire signed [11:0] S_X0;
wire signed [11:0] S_U0;
wire signed [11:0] S_V0;
wire signed [11:0] E_X0;
wire signed [11:0] E_U0;
wire signed [11:0] E_V0;

tmu_edgetrace edgetrace(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.busy(edgetrace_busy),
	
	.pipe_stb_i(edgediv_pipe_stb),
	.pipe_ack_o(edgediv_pipe_ack),
	.A_S_X(A2_S_X),
	.A_S_Y(A2_S_Y),
	.A_D_X(A2_D_X),
	.A_D_Y(A2_D_Y),
	.B_D_Y(B2_D_Y),
	.C_D_Y(C2_D_Y),
	.dx1_positive(dx1_positive),
	.dx1_q(dx1_q),
	.dx1_r(dx1_r),
	.dx2_positive(dx2_positive),
	.dx2_q(dx2_q),
	.dx2_r(dx2_r),
	.dx3_positive(dx3_positive),
	.dx3_q(dx3_q),
	.dx3_r(dx3_r),
	.du1_positive(du1_positive),
	.du1_q(du1_q),
	.du1_r(du1_r),
	.du2_positive(du2_positive),
	.du2_q(du2_q),
	.du2_r(du2_r),
	.du3_positive(du3_positive),
	.du3_q(du3_q),
	.du3_r(du3_r),
	.dv1_positive(dv1_positive),
	.dv1_q(dv1_q),
	.dv1_r(dv1_r),
	.dv2_positive(dv2_positive),
	.dv2_q(dv2_q),
	.dv2_r(dv2_r),
	.dv3_positive(dv3_positive),
	.dv3_q(dv3_q),
	.dv3_r(dv3_r),
	.divisor1(divisor1),
	.divisor2(divisor2),
	.divisor3(divisor3),
	
	.pipe_stb_o(edgetrace_pipe_stb),
	.pipe_ack_i(edgetrace_pipe_ack),
	.Y(Y0),
	.S_X(S_X0),
	.S_U(S_U0),
	.S_V(S_V0),
	.E_X(E_X0),
	.E_U(E_U0),
	.E_V(E_V0)
);

/* Stage 6 - Compute scanline division operands */
wire scandivops_busy;
wire scandivops_pipe_stb;
wire scandivops_pipe_ack;
wire signed [11:0] Y;
wire signed [11:0] S_X;
wire signed [11:0] S_U;
wire signed [11:0] S_V;
wire signed [11:0] E_X;
wire du0_positive;
wire [10:0] du0;
wire dv0_positive;
wire [10:0] dv0;
wire [10:0] divisor0;

tmu_scandivops scandivops(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.busy(scandivops_busy),
	
	.pipe_stb_i(edgetrace_pipe_stb),
	.pipe_ack_o(edgetrace_pipe_ack),
	.Y0(Y0),
	.S_X0(S_X0),
	.S_U0(S_U0),
	.S_V0(S_V0),
	.E_X0(E_X0),
	.E_U0(E_U0),
	.E_V0(E_V0),
	
	.pipe_stb_o(scandivops_pipe_stb),
	.pipe_ack_i(scandivops_pipe_ack),
	.Y(Y),
	.S_X(S_X),
	.S_U(S_U),
	.S_V(S_V),
	.E_X(E_X),
	.du_positive(du0_positive),
	.du(du0),
	.dv_positive(dv0_positive),
	.dv(dv0),
	.divisor(divisor0)
);

/* Stage 7 - Scanline division */
wire scandiv_busy;
wire scandiv_pipe_stb;
wire scandiv_pipe_ack;
wire signed [11:0] Y1;
wire signed [11:0] S_X1;
wire signed [11:0] S_U1;
wire signed [11:0] S_V1;
wire signed [11:0] E_X1;
wire du_positive;
wire [10:0] du_q;
wire [10:0] du_r;
wire dv_positive;
wire [10:0] dv_q;
wire [10:0] dv_r;
wire [10:0] divisor;

tmu_scandiv scandiv(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.busy(scandiv_busy),
	
	.pipe_stb_i(scandivops_pipe_stb),
	.pipe_ack_o(scandivops_pipe_ack),
	.Y0(Y),
	.S_X0(S_X),
	.S_U0(S_U),
	.S_V0(S_V),
	.E_X0(E_X),
	.du0_positive(du0_positive),
	.du0(du0),
	.dv0_positive(dv0_positive),
	.dv0(dv0),
	.divisor0(divisor0),
	
	.pipe_stb_o(scandiv_pipe_stb),
	.pipe_ack_i(scandiv_pipe_ack),
	.Y(Y1),
	.S_X(S_X1),
	.S_U(S_U1),
	.S_V(S_V1),
	.E_X(E_X1),
	.du_positive(du_positive),
	.du_q(du_q),
	.du_r(du_r),
	.dv_positive(dv_positive),
	.dv_q(dv_q),
	.dv_r(dv_r),
	.divisor(divisor)
);

/* Stage 8 - Scanline trace */
wire scantrace_busy;
wire scantrace_pipe_stb;
wire scantrace_pipe_ack;
wire signed [11:0] P_X;
wire signed [11:0] P_Y;
wire signed [11:0] P_U;
wire signed [11:0] P_V;

tmu_scantrace scantrace(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.busy(scantrace_busy),
	
	.pipe_stb_i(scandiv_pipe_stb),
	.pipe_ack_o(scandiv_pipe_ack),
	.Y(Y1),
	.S_X(S_X1),
	.S_U(S_U1),
	.S_V(S_V1),
	.E_X(E_X1),
	.du_positive(du_positive),
	.du_q(du_q),
	.du_r(du_r),
	.dv_positive(dv_positive),
	.dv_q(dv_q),
	.dv_r(dv_r),
	.divisor(divisor),
	
	.pipe_stb_o(scantrace_pipe_stb),
	.pipe_ack_i(scantrace_pipe_ack),
	.P_X(P_X),
	.P_Y(P_Y),
	.P_U(P_U),
	.P_V(P_V)
);

/* Stage 9 - Clamp source coordinates */
wire clamp_busy;
wire clamp_pipe_stb;
wire clamp_pipe_ack;
wire [10:0] P_Xc;
wire [10:0] P_Yc;
wire [10:0] P_Uc;
wire [10:0] P_Vc;

tmu_clamp clamp(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.busy(clamp_busy),
	
	.src_hres(src_hres),
	.src_vres(src_vres),
	.dst_hres(dst_hres),
	.dst_vres(dst_vres),
	
	.pipe_stb_i(scantrace_pipe_stb),
	.pipe_ack_o(scantrace_pipe_ack),
	.P_X(P_X),
	.P_Y(P_Y),
	.P_U(P_U),
	.P_V(P_V),
	
	.pipe_stb_o(clamp_pipe_stb),
	.pipe_ack_i(clamp_pipe_ack),
	.P_Xc(P_Xc),
	.P_Yc(P_Yc),
	.P_Uc(P_Uc),
	.P_Vc(P_Vc)
);

/* Stage 10 - Compute memory addresses */
wire addresses_busy;
wire addresses_pipe_stb;
wire addresses_pipe_ack;
wire [fml_depth-1-1:0] src_addr;
wire [fml_depth-1-1:0] dst_addr;

tmu_addresses #(
	.fml_depth(fml_depth)
) addresses (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.busy(addresses_busy),
	
	.src_fbuf(src_fbuf),
	.src_hres(src_hres),
	.dst_fbuf(dst_fbuf),
	.dst_hres(dst_hres),
	
	.pipe_stb_i(clamp_pipe_stb),
	.pipe_ack_o(clamp_pipe_ack),
	.P_X(P_Xc),
	.P_Y(P_Yc),
	.P_U(P_Uc),
	.P_V(P_Vc),
	
	.pipe_stb_o(addresses_pipe_stb),
	.pipe_ack_i(addresses_pipe_ack),
	.src_addr(src_addr),
	.dst_addr(dst_addr)
);

/* Stage 11 - Pixel input */
wire pixin_busy;
wire pixin_pipe_stb;
wire pixin_pipe_ack;
wire [15:0] src_pixel;
wire [fml_depth-1-1:0] dst_addr1;
wire inc_misses;

tmu_pixin #(
	.fml_depth(fml_depth),
	.cache_depth(pixin_cache_depth)
) pixin (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.fml_adr(fmlr_adr),
	.fml_stb(fmlr_stb),
	.fml_ack(fmlr_ack),
	.fml_di(fmlr_di),
	
	.flush(start),
	.busy(pixin_busy),
	
	.pipe_stb_i(addresses_pipe_stb),
	.pipe_ack_o(addresses_pipe_ack),
	.src_addr(src_addr),
	.dst_addr(dst_addr),
	
	.pipe_stb_o(pixin_pipe_stb),
	.pipe_ack_i(pixin_pipe_ack),
	.src_pixel(src_pixel),
	.dst_addr1(dst_addr1),
	
	.inc_misses(inc_misses)
);

/* Stage 12 - Apply decay effect. Chroma key filtering is also applied here. */
wire decay_busy;
wire decay_pipe_stb;
wire decay_pipe_ack;
wire [15:0] src_pixel_d;
wire [fml_depth-1-1:0] dst_addr2;

tmu_decay #(
	.fml_depth(fml_depth)
) decay (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.busy(decay_busy),
	
	.brightness(brightness),
	.chroma_key_en(chroma_key_en),
	.chroma_key(chroma_key),
	
	.pipe_stb_i(pixin_pipe_stb),
	.pipe_ack_o(pixin_pipe_ack),
	.src_pixel(src_pixel),
	.dst_addr(dst_addr1),
	
	.pipe_stb_o(decay_pipe_stb),
	.pipe_ack_i(decay_pipe_ack),
	.src_pixel_d(src_pixel_d),
	.dst_addr1(dst_addr2)
);

/* Stage 13 - Burst assembler */
reg burst_flush;
wire burst_busy;
wire burst_pipe_stb;
wire burst_pipe_ack;
wire [fml_depth-5-1:0] burst_addr;
wire [15:0] burst_sel;
wire [255:0] burst_do;

tmu_burst #(
	.fml_depth(fml_depth)
) burst (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.flush(burst_flush),
	.busy(burst_busy),
	
	.pipe_stb_i(decay_pipe_stb),
	.pipe_ack_o(decay_pipe_ack),
	.src_pixel_d(src_pixel_d),
	.dst_addr(dst_addr2),
	
	.pipe_stb_o(burst_pipe_stb),
	.pipe_ack_i(burst_pipe_ack),
	.burst_addr(burst_addr),
	.burst_sel(burst_sel),
	.burst_do(burst_do)
);

/* Stage 14 - Pixel output */
wire pixout_busy;

tmu_pixout #(
	.fml_depth(fml_depth)
) pixout (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.busy(pixout_busy),
	
	.pipe_stb_i(burst_pipe_stb),
	.pipe_ack_o(burst_pipe_ack),
	.burst_addr(burst_addr),
	.burst_sel(burst_sel),
	.burst_do(burst_do),
	
	.fml_adr(fmlw_adr),
	.fml_stb(fmlw_stb),
	.fml_ack(fmlw_ack),
	.fml_sel(fmlw_sel),
	.fml_do(fmlw_do)
);

/* FSM to flush the burst assembler at the end */

wire pipeline_busy = meshgen_busy|reorder_busy
	|edgedivops_busy|edgediv_busy|edgetrace_busy
	|scandivops_busy|scandiv_busy|scantrace_busy
	|clamp_busy|addresses_busy|pixin_busy
	|decay_busy|burst_busy|pixout_busy;

parameter IDLE		= 2'd0;
parameter WAIT_PROCESS	= 2'd1;
parameter FLUSH		= 2'd2;
parameter WAIT_FLUSH	= 2'd3;

reg [1:0] state;
reg [1:0] next_state;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= IDLE;
	else
		state <= next_state;
end

always @(*) begin
	next_state = state;

	busy = 1'b1;
	burst_flush = 1'b0;
	
	case(state)
		IDLE: begin
			busy = 1'b0;
			if(start)
				next_state = WAIT_PROCESS;
		end
		WAIT_PROCESS: begin
			if(~pipeline_busy)
				next_state = FLUSH;
		end
		FLUSH: begin
			burst_flush = 1'b1;
			next_state = WAIT_FLUSH;
		end
		WAIT_FLUSH: begin
			if(~pipeline_busy)
				next_state = IDLE;
		end
	endcase
end

/* Performance counters */

tmu_perfcounters perfcounters(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.start(start),
	.busy(busy),
	
	/* When the clamp stage puts out a pixel that is acked,
	 * this pixel will be drawn sooner or later.
	 * So counting the cycles with both these signals
	 * asserted gives the total number of traced pixels.
	 */
	.inc_pixels(clamp_pipe_stb & clamp_pipe_ack),
	
	/* Measure read efficiency */
	.stb1(clamp_pipe_stb),
	.ack1(clamp_pipe_ack),
	
	/* Measure write efficiency */
	.stb2(decay_pipe_stb),
	.ack2(decay_pipe_ack),
	
	.inc_misses(inc_misses),

	.perf_pixels(perf_pixels),
	.perf_clocks(perf_clocks),
	.perf_stall1(perf_stall1),
	.perf_complete1(perf_complete1),
	.perf_stall2(perf_stall2),
	.perf_complete2(perf_complete2),
	.perf_misses(perf_misses)
);

endmodule
