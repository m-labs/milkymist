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

module tb_writebuffer();

parameter fml_depth = 26;

reg sys_clk;
reg sys_rst;

wire busy;
reg flush;

reg pipe_stb_i;
wire pipe_ack_o;
reg [15:0] color;
reg [fml_depth-1-1:0] dadr;

wire [fml_depth-1:0] fmlw_adr;
wire fmlw_stb;
reg fmlw_ack;
wire [7:0] fmlw_sel;
wire [63:0] fmlw_do;

/* 100MHz system clock */
initial sys_clk = 1'b0;
always #5 sys_clk = ~sys_clk;

tmu2_writebuffer #(
	.fml_depth(fml_depth)
) dut (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.busy(busy),
	.flush(flush),

	.pipe_stb_i(pipe_stb_i),
	.pipe_ack_o(pipe_ack_o),
	.color(color),
	.dadr(dadr),

	.fml_adr(fmlw_adr),
	.fml_stb(fmlw_stb),
	.fml_ack(fmlw_ack),
	.fml_sel(fmlw_sel),
	.fml_do(fmlw_do)
);

task waitclock;
begin
	@(posedge sys_clk);
	#1;
end
endtask

task pwrite;
input [fml_depth-1:0] address;
input [15:0] data;
integer wcycles;
begin
	dadr = address/2;
	color = data;
	pipe_stb_i = 1'b1;
	wcycles = 0;
	while(~pipe_ack_o) begin
		wcycles = wcycles + 1;
		waitclock;
	end
	$display("pwrite: %x->%x [w: %d]", data, address+0, wcycles);
	waitclock;
	pipe_stb_i = 1'b0;
end
endtask

/* Handle FML master  */
integer write_burstcount;
integer write_addr;

task check;
input [31:0] adr;
input [31:0] got;
input [31:0] expected;
begin
	if(got !== expected) begin
		$display("err! at address %x, expected %x got %x", adr, expected, got);
		$finish;
	end
end
endtask

task handle_write;
integer write_addr2;
integer x;
integer y;
reg [15:0] starti;
begin
	$display("write: %x %x [%b]", write_addr, fmlw_do, fmlw_sel);
	starti = write_addr[20:0];
	if(fmlw_sel[7]) check(starti, fmlw_do[63:48], starti);
	if(fmlw_sel[5]) check(starti, fmlw_do[47:32], starti+2);
	if(fmlw_sel[3]) check(starti, fmlw_do[31:16], starti+4);
	if(fmlw_sel[1]) check(starti, fmlw_do[15: 0], starti+6);
end
endtask

initial write_burstcount = 0;
always @(posedge sys_clk) begin
	fmlw_ack = 1'b0;
	if(write_burstcount == 0) begin
		if(fmlw_stb & (($random % 35) == 0)) begin
			write_burstcount = 1;
			write_addr = fmlw_adr;
			
			//$display("Starting   FML burst WRITE at address %x data=%x", write_addr, fmlw_do);
			handle_write;
			
			fmlw_ack = 1'b1;
		end
	end else begin
		write_addr = write_addr + 8;
		write_burstcount = write_burstcount + 1;
		
		//$display("Continuing FML burst WRITE at address %x data=%x", write_addr, fmlw_do);
		handle_write;
		
		if(write_burstcount == 4)
			write_burstcount = 0;
	end
end

integer i;
integer r;
always begin
	/* Reset / Initialize our logic */
	sys_rst = 1'b1;
	fmlw_ack = 1'b0;
	flush = 1'b0;
	pipe_stb_i = 1'b0;
	color = 15'h0000;
	dadr = 26'd0;
	waitclock;
	sys_rst = 1'b0;
	waitclock;

	for(i=0;i<3000;i=i+1) begin
		r = $random;
		pwrite(r*2, r*2);
		if(($random % 2) == 0)
			pwrite(r*2+2, r*2+2);
		if(($random % 2) == 0)
			pwrite(r*2+4, r*2+4);
		if(($random % 2) == 0)
			pwrite(r*2+6, r*2+6);
	end

	while(busy) waitclock;

	$display("done, flushing");

	flush = 1'b1;
	waitclock;
	flush = 1'b0;

	while(busy) waitclock;
	
	$finish;
end

endmodule
