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

module vgafb #(
	parameter csr_addr = 4'h0,
	parameter fml_depth = 26
) (
	input sys_clk,
	input sys_rst,
	
	/* Configuration interface */
	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output [31:0] csr_do,
	
	/* Framebuffer FML 4x64 interface */
	output [fml_depth-1:0] fml_adr,
	output fml_stb,
	input fml_ack,
	input [63:0] fml_di,
	
	/* VGA pixel clock */
	input vga_clk,
	
	/* VGA signal pads */
	output vga_psave_n,
	output reg vga_hsync_n,
	output reg vga_vsync_n,
	output vga_sync_n,
	output vga_blank_n,
	output reg [7:0] vga_r,
	output reg [7:0] vga_g,
	output reg [7:0] vga_b,
	output [1:0] vga_clk_sel
);

/*
 * Control interface
 */
wire vga_rst;

wire [10:0] hres;
wire [10:0] hsync_start;
wire [10:0] hsync_end;
wire [10:0] hscan;

wire [10:0] vres;
wire [10:0] vsync_start;
wire [10:0] vsync_end;
wire [10:0] vscan;

wire [fml_depth-1:0] baseaddress;
wire baseaddress_ack;

wire [17:0] nbursts;

vgafb_ctlif #(
	.csr_addr(csr_addr),
	.fml_depth(fml_depth)
) ctlif (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_di),
	.csr_do(csr_do),
	
	.vga_rst(vga_rst),
	
	.hres(hres),
	.hsync_start(hsync_start),
	.hsync_end(hsync_end),
	.hscan(hscan),
	
	.vres(vres),
	.vsync_start(vsync_start),
	.vsync_end(vsync_end),
	.vscan(vscan),
	
	.baseaddress(baseaddress),
	.baseaddress_ack(baseaddress_ack),
	
	.nbursts(nbursts),

	.vga_clk_sel(vga_clk_sel)
);

/*
 * Generate signal data
 */
reg hsync_n;
reg vsync_n;
wire pixel_valid;
wire [15:0] pixel_fb;
wire pixel_ack;
wire [15:0] pixel;

wire fifo_full;

reg hactive;
reg vactive;
wire active = hactive & vactive;
assign pixel = active ? pixel_fb : 16'h0000;

wire generate_en;

reg [10:0] hcounter;
reg [10:0] vcounter;

always @(posedge sys_clk) begin
	if(vga_rst) begin
		hcounter <= 10'd0;
		vcounter <= 10'd0;
		hactive <= 1'b0;
		hsync_n <= 1'b1;
		vactive <= 1'b0;
		vsync_n <= 1'b1;
	end else begin
		if(generate_en) begin
			hcounter <= hcounter + 10'd1;
			
			if(hcounter == 10'd0) hactive <= 1'b1;
			if(hcounter == hres) hactive <= 1'b0;
			if(hcounter == hsync_start) hsync_n <= 1'b0;
			if(hcounter == hsync_end) hsync_n <= 1'b1;
			if(hcounter == hscan) begin
				hcounter <= 10'd0;
				if(vcounter == vscan)
					vcounter <= 10'd0;
				else
					vcounter <= vcounter + 10'd1;
			end
			
			if(vcounter == 10'd0) vactive <= 1'b1;
			if(vcounter == vres) vactive <= 1'b0;
			if(vcounter == vsync_start) vsync_n <= 1'b0;
			if(vcounter == vsync_end) vsync_n <= 1'b1;
		end
	end
end

assign generate_en = ~fifo_full & (~active | pixel_valid);
assign pixel_ack = ~fifo_full & active & pixel_valid;

vgafb_pixelfeed #(
	.fml_depth(fml_depth)
) pixelfeed (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.vga_rst(vga_rst),
	
	.nbursts(nbursts),
	.baseaddress(baseaddress),
	.baseaddress_ack(baseaddress_ack),
	
	.fml_adr(fml_adr),
	.fml_stb(fml_stb),
	.fml_ack(fml_ack),
	.fml_di(fml_di),
	
	.pixel_valid(pixel_valid),
	.pixel(pixel_fb),
	.pixel_ack(pixel_ack)
);

/*
 * System clock to VGA clock domain crossing is
 * acheived by an asynchronous FIFO.
 *
 * Bits 0-15 are RGB565 pixel data
 * Bit 16 is negated Horizontal Sync
 * Bit 17 is negated Verical Sync
 */
wire [17:0] fifo_do;

vgafb_asfifo #(
	.DATA_WIDTH(18),
	.ADDRESS_WIDTH(6)
) fifo (
	.Data_out(fifo_do),
	.Empty_out(),
	.ReadEn_in(1'b1),
	.RClk(vga_clk),
	
	.Data_in({vsync_n, hsync_n, pixel}),
	.Full_out(fifo_full),
	.WriteEn_in(generate_en),
	.WClk(sys_clk),
	
	.Clear_in(vga_rst)
);

/*
 * Drive the VGA pads.
 * RGB565 -> RGB888 color space conversion is also performed here
 * by bit shifting and replicating the most significant bits of
 * the input into the least significant bits of the output left
 * undefined by the shifting.
 */

assign vga_sync_n = 1'b0; /* Sync-on-Green is not implemented */
assign vga_psave_n = 1'b1;
assign vga_blank_n = 1'b1;

always @(posedge vga_clk) begin
	vga_vsync_n <= fifo_do[17];
	vga_hsync_n <= fifo_do[16];
	vga_r <= {fifo_do[15:11], fifo_do[15:13]};
	vga_g <= {fifo_do[10:5], fifo_do[10:9]};
	vga_b <= {fifo_do[4:0], fifo_do[4:2]};
end

endmodule
