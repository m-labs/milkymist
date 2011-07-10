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

module tb_bt656cap();

parameter fml_depth = 26;

reg sys_clk;
reg sys_rst;

reg [13:0] csr_a;
reg csr_we;
reg [31:0] csr_di;
wire [31:0] csr_do;

wire irq;

wire [fml_depth-1:0] fml_adr;
wire fml_stb;
reg fml_ack;
wire [63:0] fml_do;

reg vid_clk;
reg [7:0] p;

/* 100MHz system clock */
initial sys_clk = 1'b0;
always #5 sys_clk = ~sys_clk;

/* ~27MHz video clock */
initial vid_clk = 1'b0;
always #19 vid_clk = ~vid_clk;

reg field;
reg [19:0] inc;
initial field = 1'b0;
initial inc = 20'd0;
always @(posedge vid_clk) begin
	inc <= inc + 20'd1;
	case(inc[1:0])
		2'd0: p <= inc % 720;
		2'd1: p <= 8'hfe;
		2'd2: p <= inc/720;
		2'd3: p <= 8'hfe;
	endcase
	if(inc == 20'd414720) begin
		field <= ~field;
		p <= 8'hff;
	end
	if(inc == 20'd414721) p <= 8'h00;
	if(inc == 20'd414722) p <= 8'h00;
	if(inc == 20'd414723) begin
		p <= {1'b1, field, 6'b00_0000};
		inc <= 20'd0;
		$display("** end of frame");
	end
end

bt656cap #(
	.fml_depth(fml_depth)
) dut (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_di),
	.csr_do(csr_do),
	
	.irq(irq),
	
	.fml_adr(fml_adr),
	.fml_stb(fml_stb),
	.fml_ack(fml_ack),
	.fml_do(fml_do),

	.vid_clk(vid_clk),
	.p(p),
	.sda(),
	.sdc()
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

/* Handle FML master for pixel writes */
integer write_burstcount;
integer write_addr;

task handle_write;
integer write_addr2;
integer x;
integer y;
begin
	write_addr2 = write_addr[20:0]/2;
	x = write_addr2 % 720;
	y = write_addr2 / 720;
	$display("W: %d %d", x, y);
	$image_set(x + 0, y, fml_do[63:48]);
	$image_set(x + 1, y, fml_do[47:32]);
	$image_set(x + 2, y, fml_do[31:16]);
	$image_set(x + 3, y, fml_do[15:0]);
end
endtask

initial write_burstcount = 0;
always @(posedge sys_clk) begin
	fml_ack = 1'b0;
	if(write_burstcount == 0) begin
		if(fml_stb & (($random % 5) == 0)) begin
			write_burstcount = 1;
			write_addr = fml_adr;
			
			$display("Starting   FML burst WRITE at address %x data=%x", write_addr, fml_do);
			handle_write;
			
			fml_ack = 1'b1;
		end
	end else begin
		write_addr = write_addr + 8;
		write_burstcount = write_burstcount + 1;
		
		$display("Continuing FML burst WRITE at address %x data=%x", write_addr, fml_do);
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

	fml_ack = 1'b0;
	
	waitclock;
	
	sys_rst = 1'b0;
	
	waitclock;

	/* Setup */
	$display("Configuring DUT...");
	csrwrite(32'h04, 32'h03);
	csrread(32'h04);
	@(posedge irq);
	csrread(32'h04);
	@(posedge irq);
	csrread(32'h04);
	@(posedge irq);

	$image_close;
	$finish;
end

endmodule
