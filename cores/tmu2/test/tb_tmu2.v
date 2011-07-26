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

wire [fml_depth-1:0] fmlr_adr;
wire fmlr_stb;
reg fmlr_ack;
reg [63:0] fmlr_di;

wire [fml_depth-1:0] fmldr_adr;
wire fmldr_stb;
reg fmldr_ack;
reg [63:0] fmldr_di;

wire [fml_depth-1:0] fmlw_adr;
wire fmlw_stb;
reg fmlw_ack;
wire [7:0] fmlw_sel;
wire [63:0] fmlw_do;

/* 100MHz system clock */
initial sys_clk = 1'b0;
always #5 sys_clk = ~sys_clk;

tmu2 #(
	.fml_depth(fml_depth),
	.texel_cache_depth(13)
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
	
	.fmlr_adr(fmlr_adr),
	.fmlr_stb(fmlr_stb),
	.fmlr_ack(fmlr_ack),
	.fmlr_di(fmlr_di),

	.fmldr_adr(fmldr_adr),
	.fmldr_stb(fmldr_stb),
	.fmldr_ack(fmldr_ack),
	.fmldr_di(fmldr_di),
	
	.fmlw_adr(fmlw_adr),
	.fmlw_stb(fmlw_stb),
	.fmlw_ack(fmlw_ack),
	.fmlw_sel(fmlw_sel),
	.fmlw_do(fmlw_do)
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
	$display("CSR write: %x=%x", address, data);
	csr_we = 1'b0;
end
endtask

task csrread;
input [31:0] address;
begin
	csr_a = address[16:2];
	waitclock;
	$display("CSR read : %x=%x", address, csr_do);
end
endtask

`define TEST_COPY

/* Handle WB master for texture coordinates reads */
reg [6:0] x;
reg [6:0] y;
always @(posedge sys_clk) begin
	if(wbm_stb_o & ~wbm_ack_i) begin
		x = wbm_adr_o[9:3];
		y = wbm_adr_o[16:10];

`ifdef TEST_COPY
		if(wbm_adr_o[2])
			wbm_dat_i = y*16*64;
		else
			wbm_dat_i = x*16*64;
`endif
`ifdef TEST_ZOOMIN
		if(wbm_adr_o[2])
			wbm_dat_i = y*10*64;
		else
			wbm_dat_i = x*10*64;
`endif
`ifdef TEST_ZOOMOUT
		if(wbm_adr_o[2])
			wbm_dat_i = y*40*64;
		else
			wbm_dat_i = x*40*64;
`endif
`ifdef TEST_ROTOZOOM
		// 73*cos(pi/8) ~ 67
		// 73*sin(pi/8) ~ 28
		if(wbm_adr_o[2])
			wbm_dat_i = (x*16-256)*28 + (y*16-256)*67 + 256*64;
		else
			wbm_dat_i = (x*16-256)*67 - (y*16-256)*28 + 256*64;
`endif

		$display("Vertex read: %d,%d (y:%b)", x, y, wbm_adr_o[2]);
		wbm_ack_i = 1'b1;
	end else
		wbm_ack_i = 1'b0;
end

/* Handle FML master for pixel reads */
task handle_read;
input img;
input [fml_depth-1:0] addr;
integer read_addr2;
integer x;
integer y;
reg [15:0] p1; /* work around bugs/problems if we assign */
reg [15:0] p2; /* directly to fmlr_di[xx:xx] in $image_get... */
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
	if(img != 0)
		fmldr_di = {p1, p2, p3, p4};
	else
		fmlr_di = {p1, p2, p3, p4};
end
endtask

/* Texture */
integer read_burstcount;
integer read_addr;
initial read_burstcount = 0;
always @(posedge sys_clk) begin
	fmlr_ack = 1'b0;
	if(read_burstcount == 0) begin
		if(fmlr_stb & (($random % 5) == 0)) begin
			read_burstcount = 1;
			read_addr = fmlr_adr;
			
			handle_read(0, read_addr);

			//$display("Starting   FML burst READ at address %x, data=%x", read_addr, fmlr_di);
			
			fmlr_ack = 1'b1;
		end
	end else begin
		read_addr = read_addr + 8;
		read_burstcount = read_burstcount + 1;
		
		handle_read(0, read_addr);

		//$display("Continuing FML burst READ at address %x, data=%x", read_addr, fmlr_di);
		
		if(read_burstcount == 4)
			read_burstcount = 0;
	end
end

/* Destination */
integer dread_burstcount;
integer dread_addr;
initial dread_burstcount = 0;
always @(posedge sys_clk) begin
	fmldr_ack = 1'b0;
	if(dread_burstcount == 0) begin
		if(fmldr_stb & (($random % 5) == 0)) begin
			dread_burstcount = 1;
			dread_addr = fmldr_adr;

			handle_read(1, dread_addr);

			//$display("Starting   FML burst read at address %x, data=%x [dest]", dread_addr, fmldr_di);

			fmldr_ack = 1'b1;
		end
	end else begin
		dread_addr = dread_addr + 8;
		dread_burstcount = dread_burstcount + 1;

		handle_read(1, dread_addr);

		//$display("Continuing FML burst read at address %x, data=%x [dest]", dread_addr, fmldr_di);

		if(dread_burstcount == 4)
			dread_burstcount = 0;
	end
end

/* Handle FML master for pixel writes */
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
	if(fmlw_sel[7])
		$image_set(1, x + 0, y, fmlw_do[63:48]);
	if(fmlw_sel[5])
		$image_set(1, x + 1, y, fmlw_do[47:32]);
	if(fmlw_sel[3])
		$image_set(1, x + 2, y, fmlw_do[31:16]);
	if(fmlw_sel[1])
		$image_set(1, x + 3, y, fmlw_do[15:0]);
end
endtask

initial write_burstcount = 0;
always @(posedge sys_clk) begin
	fmlw_ack = 1'b0;
	if(write_burstcount == 0) begin
		if(fmlw_stb & (($random % 5) == 0)) begin
			write_burstcount = 1;
			write_addr = fmlw_adr;
			
			//$display("Starting   FML burst WRITE at address %x data=%x mask=%b", write_addr, fmlw_do, fmlw_sel);
			handle_write;
			
			fmlw_ack = 1'b1;
		end
	end else begin
		write_addr = write_addr + 8;
		write_burstcount = write_burstcount + 1;
		
		//$display("Continuing FML burst WRITE at address %x data=%x mask=%b", write_addr, fmlw_do, fmlw_sel);
		handle_write;
		
		if(write_burstcount == 4)
			write_burstcount = 0;
	end
end

always begin
	$display("Opening input picture...");
	$image_open;
	
	/* Reset / Initialize our logic */
	sys_rst = 1'b1;
	
	csr_a = 14'd0;
	csr_di = 32'd0;
	csr_we = 1'b0;
	
	fmlr_di = 64'd0;
	fmlr_ack = 1'b0;

	fmldr_di = 64'd0;
	fmldr_ack = 1'b0;
	
	fmlw_ack = 1'b0;
	
	waitclock;
	
	sys_rst = 1'b0;
	
	waitclock;

	/* Setup */
	$display("Configuring TMU...");
	csrwrite(32'h2C, 32'h01000000); /* dst framebuffer */

	csrwrite(32'h04, 32); /* hmeshlast */
	csrwrite(32'h08, 32); /* vmeshlast */
	csrwrite(32'h1C, 512); /* texhres */
	csrwrite(32'h20, 512); /* texvres */
	csrwrite(32'h30, 512); /* dsthres */
	csrwrite(32'h34, 512); /* dstvres */
	csrwrite(32'h40, 16); /* squarew */
	csrwrite(32'h44, 16); /* squareh */

	csrwrite(32'h24, 32'h7fff); /* hmask, enable 512x512 wrapping */
	csrwrite(32'h28, 32'h7fff); /* vmask */

	csrwrite(32'h48, 63); /* alpha */

	/* Start */
	$display("Starting TMU...");
	csrwrite(32'h00, 32'd1);

	@(posedge irq);
	$display("Received DONE IRQ from TMU!");

	$display("Writing output picture...");
	$image_close;
	$display("All done!");
	$finish;
end

endmodule
