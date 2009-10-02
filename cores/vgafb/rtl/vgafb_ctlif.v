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

module vgafb_ctlif #(
	parameter csr_addr = 4'h0,
	parameter fml_depth = 26
) (
	input sys_clk,
	input sys_rst,
	
	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output reg [31:0] csr_do,
	
	output reg vga_rst,
	
	output reg [10:0] hres,
	output reg [10:0] hsync_start,
	output reg [10:0] hsync_end,
	output reg [10:0] hscan,
	
	output reg [10:0] vres,
	output reg [10:0] vsync_start,
	output reg [10:0] vsync_end,
	output reg [10:0] vscan,
	
	output reg [fml_depth-1:0] baseaddress,
	input baseaddress_ack,
	
	output reg [17:0] nbursts
);

reg [fml_depth-1:0] baseaddress_act;

always @(posedge sys_clk) begin
	if(sys_rst)
		baseaddress_act <= {fml_depth{1'b0}};
	else if(baseaddress_ack)
		baseaddress_act <= baseaddress;
end

wire csr_selected = csr_a[13:10] == csr_addr;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		csr_do <= 32'd0;
		
		vga_rst <= 1'b1;
		
		hres <= 10'd640;
		hsync_start <= 10'd656;
		hsync_end <= 10'd752;
		hscan <= 10'd799;
		
		vres <= 10'd480;
		vsync_start <= 10'd491;
		vsync_end <= 10'd493;
		vscan <= 10'd523;
		
		baseaddress <= {fml_depth{1'b0}};
		
		nbursts <= 18'd19200;
	end else begin
		csr_do <= 32'd0;
		if(csr_selected) begin
			if(csr_we) begin
				case(csr_a[3:0])
					4'd0: vga_rst <= csr_di[0];
					4'd1: hres <= csr_di[10:0];
					4'd2: hsync_start <= csr_di[10:0];
					4'd3: hsync_end <= csr_di[10:0];
					4'd4: hscan <= csr_di[10:0];
					4'd5: vres <= csr_di[10:0];
					4'd6: vsync_start <= csr_di[10:0];
					4'd7: vsync_end <= csr_di[10:0];
					4'd8: vscan <= csr_di[10:0];
					4'd9: baseaddress <= csr_di[fml_depth-1:0];
					// 10: baseaddress_act is read-only for Wishbone
					4'd11: nbursts <= csr_di[17:0];
				endcase
			end
			
			case(csr_a[3:0])
				4'd0: csr_do <= vga_rst;
				4'd1: csr_do <= hres;
				4'd2: csr_do <= hsync_start;
				4'd3: csr_do <= hsync_end;
				4'd4: csr_do <= hscan;
				4'd5: csr_do <= vres;
				4'd6: csr_do <= vsync_start;
				4'd7: csr_do <= vsync_end;
				4'd8: csr_do <= vscan;
				4'd9: csr_do <= baseaddress;
				4'd10: csr_do <= baseaddress_act;
				4'd11: csr_do <= nbursts;
			endcase
		end
	end
end

endmodule
