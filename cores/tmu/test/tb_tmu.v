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

module tb_tmu();

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

wire [fml_depth-1:0] fmlw_adr;
wire fmlw_stb;
reg fmlw_ack;
wire [7:0] fmlw_sel;
wire [63:0] fmlw_do;

/* 100MHz system clock */
initial sys_clk = 1'b0;
always #5 sys_clk = ~sys_clk;

tmu #(
	.fml_depth(fml_depth),
	.pixin_cache_depth(12)
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

/* Handle WB master for mesh reads */
reg [6:0] x;
reg [6:0] y;
always @(posedge sys_clk) begin
	if(wbm_stb_o & ~wbm_ack_i) begin
		x = wbm_adr_o[8:2];
		y = wbm_adr_o[15:9];
		if(wbm_adr_o[31]) begin
			wbm_dat_i[15:0] = x*20+y*7+1;
			wbm_dat_i[31:16] = y*20;
			$display("Mesh Read[d]: %d,%d", x, y);
		end else begin
			wbm_dat_i[15:0] = x*20;
			wbm_dat_i[31:16] = y*20;
			$display("Mesh Read[s]: %d,%d", x, y);
		end
		wbm_ack_i = 1'b1;
	end else
		wbm_ack_i = 1'b0;
end

/* Handle FML master for pixel reads */
integer read_burstcount;
integer read_addr;

task handle_read;
integer read_addr2;
integer x;
integer y;
reg [15:0] p1; /* work around bugs/problems if we assign */
reg [15:0] p2; /* directly to fmlr_di[xx:xx] in $image_get... */
reg [15:0] p3;
reg [15:0] p4;
begin
	read_addr2 = read_addr[20:0]/2;
	x = read_addr2 % 640;
	y = read_addr2 / 640;
	$image_get(x + 0, y, p1);
	$image_get(x + 1, y, p2);
	$image_get(x + 2, y, p3);
	$image_get(x + 3, y, p4);
	fmlr_di = {p1, p2, p3, p4};
end
endtask

initial read_burstcount = 0;
always @(posedge sys_clk) begin
	fmlr_ack = 1'b0;
	if(read_burstcount == 0) begin
		if(fmlr_stb) begin
			read_burstcount = 1;
			read_addr = fmlr_adr;
			
			handle_read;
			
			//$display("Starting   FML burst READ at address %x", read_addr);
			
			fmlr_ack = 1'b1;
		end
	end else begin
		read_addr = read_addr + 8;
		read_burstcount = read_burstcount + 1;
		
		handle_read;
		
		//$display("Continuing FML burst READ at address %x", read_addr);
		
		if(read_burstcount == 4)
			read_burstcount = 0;
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
	x = write_addr2 % 640;
	y = write_addr2 / 640;
	if(fmlw_sel[7])
		$image_set(x + 0, y, fmlw_do[63:48]);
	if(fmlw_sel[5])
		$image_set(x + 1, y, fmlw_do[47:32]);
	if(fmlw_sel[3])
		$image_set(x + 2, y, fmlw_do[31:16]);
	if(fmlw_sel[1])
		$image_set(x + 3, y, fmlw_do[15:0]);
end
endtask

initial write_burstcount = 0;
always @(posedge sys_clk) begin
	fmlw_ack = 1'b0;
	if(write_burstcount == 0) begin
		if(fmlw_stb) begin
			write_burstcount = 1;
			write_addr = fmlw_adr;
			
			//$display("Starting   FML burst WRITE at address %x", write_addr);
			handle_write;
			
			fmlw_ack = 1'b1;
		end
	end else begin
		write_addr = write_addr + 8;
		write_burstcount = write_burstcount + 1;
		
		//$display("Continuing FML burst WRITE at address %x", write_addr);
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
	
	fmlr_di = 64'd0;
	fmlr_ack = 1'b0;
	
	fmlw_ack = 1'b0;
	
	waitclock;
	
	sys_rst = 1'b0;
	
	waitclock;
	
	/* Setup */
	csrwrite(32'h20, 32'h80000000); /* dst mesh */
	csrwrite(32'h24, 32'h01000000); /* dst framebuffer */

	//csrwrite(32'h04, 2); /* hmeshlast */
	//csrwrite(32'h08, 2); /* vmeshlast */

	/* Start */
	csrwrite(32'h00, 32'd1);
	
	@(posedge irq);
	
	$image_close;
	$finish;
end

endmodule
