/*
 * Milkymist SoC
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

module tb_tmu2();

parameter fml_depth = 26;
parameter wbm_depth = 26;

reg sys_clk;
reg sys_rst;

reg [13:0] csr_a;
reg csr_we;
reg [31:0] csr_di;
wire [31:0] csr_do;

wire irq;

wire [31:0] wbm_adr_o;
wire [2:0] wbm_cti_o;
wire wbm_cyc_o;
wire wbm_stb_o;
reg wbm_ack_i;
reg [31:0] wbm_dat_i;

wire [fml_depth-1:0]	fml_tmur_adr,
			fml_tmudr_adr,
			fml_tmuw_adr;

wire			fml_tmur_stb,
			fml_tmudr_stb,
			fml_tmuw_stb;

wire			fml_tmur_ack,
			fml_tmudr_ack,
			fml_tmuw_ack;

wire [7:0]		fml_tmuw_sel;

wire [63:0]		fml_tmuw_dw;

wire [63:0]		fml_tmur_dr,
			fml_tmudr_dr;

/* 100MHz system clock */
initial sys_clk = 1'b0;
always #5 sys_clk = ~sys_clk;

tmu2 #(
	.fml_depth(fml_depth),
	.texel_cache_depth(12)
) dut (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_di),
	.csr_do(csr_do),
	
	.irq(irq),
	
	.wbm_adr_o(wbm_adr_o),
	.wbm_cti_o(wbm_cti_o),
	.wbm_cyc_o(wbm_cyc_o),
	.wbm_stb_o(wbm_stb_o),
	.wbm_ack_i(wbm_ack_i),
	.wbm_dat_i(wbm_dat_i),
	
	.fmlr_adr(fml_tmur_adr),
	.fmlr_stb(fml_tmur_stb),
	.fmlr_ack(fml_tmur_ack),
	.fmlr_di(fml_tmur_dr),

	.fmldr_adr(fml_tmudr_adr),
	.fmldr_stb(fml_tmudr_stb),
	.fmldr_ack(fml_tmudr_ack),
	.fmldr_di(fml_tmudr_dr),

	.fmlw_adr(fml_tmuw_adr),
	.fmlw_stb(fml_tmuw_stb),
	.fmlw_ack(fml_tmuw_ack),
	.fmlw_sel(fml_tmuw_sel),
	.fmlw_do(fml_tmuw_dw)
);

wire [fml_depth-1:0] fml_adr;
wire fml_stb;
wire fml_we;
reg fml_ack;
wire [7:0] fml_sel;
wire [63:0] fml_dw;
reg [63:0] fml_dr;

fmlarb #(
	.fml_depth(fml_depth)
) arb (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.m0_adr(),
	.m0_stb(1'b0),
	.m0_we(),
	.m0_ack(),
	.m0_sel(),
	.m0_di(),
	.m0_do(),

	/* WISHBONE bridge */
	.m1_adr(),
	.m1_stb(1'b0),
	.m1_we(),
	.m1_ack(),
	.m1_sel(),
	.m1_di(),
	.m1_do(),

	/* TMU, pixel read DMA (texture) */
	.m2_adr(fml_tmur_adr),
	.m2_stb(fml_tmur_stb),
	.m2_we(1'b0),
	.m2_ack(fml_tmur_ack),
	.m2_sel(8'bx),
	.m2_di(64'bx),
	.m2_do(fml_tmur_dr),

	/* TMU, pixel read DMA (destination) */
	.m3_adr(fml_tmudr_adr),
	.m3_stb(fml_tmudr_stb),
	.m3_we(1'b0),
	.m3_ack(fml_tmudr_ack),
	.m3_sel(8'bx),
	.m3_di(64'bx),
	.m3_do(fml_tmudr_dr),

	/* TMU, pixel write DMA */
	.m4_adr(fml_tmuw_adr),
	.m4_stb(fml_tmuw_stb),
	.m4_we(1'b1),
	.m4_ack(fml_tmuw_ack),
	.m4_sel(fml_tmuw_sel),
	.m4_di(fml_tmuw_dw),
	.m4_do(),

	.s_adr(fml_adr),
	.s_stb(fml_stb),
	.s_we(fml_we),
	.s_ack(fml_ack),
	.s_sel(fml_sel),
	.s_di(fml_dr),
	.s_do(fml_dw)
);

task waitclock;
begin
	@(posedge sys_clk);
	#1;
end
endtask

task csrwrite;
input [31:0] address;
input [31:0] data;
begin
	csr_a = address[16:2];
	csr_di = data;
	csr_we = 1'b1;
	waitclock;
	$display("Configuration Write: %x=%x", address, data);
	csr_we = 1'b0;
end
endtask

task csrread;
input [31:0] address;
begin
	csr_a = address[16:2];
	waitclock;
	$display("Configuration Read : %x=%x", address, csr_do);
end
endtask

/* Handle WB master for texture coordinates reads */
reg [6:0] x;
reg [6:0] y;
always @(posedge sys_clk) begin
	if(wbm_stb_o & ~wbm_ack_i) begin
		x = wbm_adr_o[9:3];
		y = wbm_adr_o[16:10];

		if(wbm_adr_o[2])
			wbm_dat_i = y*16*64;
		else
			wbm_dat_i = x*16*64;
		//$display("Vertex read: %d,%d (y:%b)", x, y, wbm_adr_o[2]);
		wbm_ack_i = 1'b1;
	end else
		wbm_ack_i = 1'b0;
end

/* FML */
task handle_read;
input img;
input [fml_depth-1:0] addr;
integer read_addr2;
integer x;
integer y;
reg [15:0] p1; /* work around bugs/problems if we assign */
reg [15:0] p2; /* directly to fml_dr[xx:xx] in $image_get... */
reg [15:0] p3;
reg [15:0] p4;
begin
	read_addr2 = addr[20:0]/2;
	x = read_addr2 % 512;
	y = read_addr2 / 512;

	$image_get(img, x + 0, y, p1);
	$image_get(img, x + 1, y, p2);
	$image_get(img, x + 2, y, p3);
	$image_get(img, x + 3, y, p4);
	fml_dr = {p1, p2, p3, p4};
end
endtask

integer write_burstcount;
integer write_addr;

task handle_write;
integer write_addr2;
integer x;
integer y;
begin
	write_addr2 = write_addr[20:0]/2;
	x = write_addr2 % 512;
	y = write_addr2 / 512;
	if(fml_sel[7])
		$image_set(1, x + 0, y, fml_dw[63:48]);
	if(fml_sel[5])
		$image_set(1, x + 1, y, fml_dw[47:32]);
	if(fml_sel[3])
		$image_set(1, x + 2, y, fml_dw[31:16]);
	if(fml_sel[1])
		$image_set(1, x + 3, y, fml_dw[15:0]);
end
endtask

/* Source read */
integer read_burstcount;
integer read_addr;
initial read_burstcount = 0;
/* Destination read */
integer dread_burstcount;
integer dread_addr;
initial dread_burstcount = 0;
/* Destination write */
initial write_burstcount = 0;
always @(posedge sys_clk) begin
	fml_ack = 1'b0;
	/* Start transactions */
	if((read_burstcount == 0) && (dread_burstcount == 0) && (write_burstcount == 0)) begin
		if(fml_stb & ~fml_we & ~fml_adr[24] & (($random % 5) == 0)) begin
			read_burstcount = 1;
			read_addr = fml_adr;
			
			handle_read(0, read_addr);

			$display("Starting   FML burst READ at address %x, data=%x", read_addr, fml_dr);
			
			fml_ack = 1'b1;
		end
		if(fml_stb & ~fml_we & fml_adr[24] & (($random % 5) == 0)) begin
			dread_burstcount = 1;
			dread_addr = fml_adr;

			handle_read(1, dread_addr);

			$display("Starting   FML burst read at address %x, data=%x [dest]", dread_addr, fml_dr);

			fml_ack = 1'b1;
		end
		if(fml_stb & fml_we & (($random % 5) == 0)) begin
			write_burstcount = 1;
			write_addr = fml_adr;

			$display("Starting   FML burst WRITE at address %x data=%x", write_addr, fml_dw);
			handle_write;

			fml_ack = 1'b1;
		end
	end
	/* Continue transactions */
	if(read_burstcount != 0) begin
		read_addr = read_addr + 8;
		read_burstcount = read_burstcount + 1;
		
		handle_read(0, read_addr);

		$display("Continuing FML burst READ at address %x, data=%x", read_addr, fml_dr);
		
		if(read_burstcount == 4)
			read_burstcount = 0;
	end
	if(dread_burstcount != 0) begin
		dread_addr = dread_addr + 8;
		dread_burstcount = dread_burstcount + 1;

		handle_read(1, dread_addr);

		$display("Continuing FML burst read at address %x, data=%x [dest]", dread_addr, fml_dr);

		if(dread_burstcount == 4)
			dread_burstcount = 0;
	end
	if(write_burstcount != 0) begin
		write_addr = write_addr + 8;
		write_burstcount = write_burstcount + 1;

		$display("Continuing FML burst WRITE at address %x data=%x", write_addr, fml_dw);
		handle_write;

		if(write_burstcount == 4)
			write_burstcount = 0;
	end
end

always begin
	$image_open;
	
	/* Reset / Initialize our logic */
	sys_rst = 1'b1;
	
	csr_a = 14'd0;
	csr_di = 32'd0;
	csr_we = 1'b0;
	
	fml_dr = 64'd0;
	fml_ack = 1'b0;
	
	waitclock;
	
	sys_rst = 1'b0;
	
	waitclock;

	/* Setup */
	csrwrite(32'h18, 32'h00000000); /* src framebuffer */
	csrwrite(32'h2C, 32'h01000000); /* dst framebuffer */

	csrwrite(32'h04, 10); /* hmeshlast */
	csrwrite(32'h08, 10); /* vmeshlast */
	csrwrite(32'h1C, 512); /* texhres */
	csrwrite(32'h20, 512); /* texhres */
	csrwrite(32'h30, 512); /* dsthres */
	csrwrite(32'h34, 512); /* dstvres */
	csrwrite(32'h40, 16); /* squarew */
	csrwrite(32'h44, 16); /* squareh */

	csrwrite(32'h48, 63); /* alpha */

	/* Start */
	csrwrite(32'h00, 32'd1);

	@(posedge irq);
	
	$image_close;
	$finish;
end

endmodule
