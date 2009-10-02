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

module tmu_ctlif #(
	parameter csr_addr = 4'h0,
	parameter fml_depth = 26
) (
	input sys_clk,
	input sys_rst,
	
	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output reg [31:0] csr_do,

	output reg irq,

	output reg start,
	input busy,

	output reg [6:0] hmesh_last,
	output reg [6:0] vmesh_last,

	output reg [5:0] brightness,
	output reg chroma_key_en,
	output reg [15:0] chroma_key,

	output reg [29:0] src_mesh, /* in 32-bit words */
	output reg [fml_depth-1-1:0] src_fbuf, /* in 16-bit words */
	output reg [10:0] src_hres,
	output reg [10:0] src_vres,

	output reg [29:0] dst_mesh, /* in 32-bit words */
	output reg [fml_depth-1-1:0] dst_fbuf, /* in 16-bit words */
	output reg [10:0] dst_hres,
	output reg [10:0] dst_vres,

	input [31:0] perf_pixels,
	input [31:0] perf_clocks,
	input [31:0] perf_stall1,
	input [31:0] perf_complete1,
	input [31:0] perf_stall2,
	input [31:0] perf_complete2,
	input [31:0] perf_misses
);

reg old_busy;
always @(posedge sys_clk) begin
	if(sys_rst)
		old_busy <= 1'b0;
	else
		old_busy <= busy;
end

wire trigger_irq = old_busy & ~busy;

wire csr_selected = csr_a[13:10] == csr_addr;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		csr_do <= 32'd0;
		irq <= 1'b0;
		start <= 1'b0;

		hmesh_last <= 7'd32;
		vmesh_last <= 7'd24;

		brightness <= 6'd63;
		chroma_key_en <= 1'b0;
		chroma_key <= 16'd0;

		src_mesh <= 30'd0;
		src_fbuf <= {fml_depth{1'b0}};
		src_hres <= 11'd640;
		src_vres <= 11'd480;

		dst_mesh <= 30'd0;
		dst_fbuf <= {fml_depth{1'b0}};
		dst_hres <= 11'd640;
		dst_vres <= 11'd480;
	end else begin
		if(trigger_irq) irq <= 1'b1;
		
		csr_do <= 32'd0;
		start <= 1'b0;
		if(csr_selected) begin
			if(csr_we) begin
				case(csr_a[3:0])
					4'b0000: begin
						start <= csr_di[0];
						irq <= 1'b0;
						chroma_key_en <= csr_di[2];
					end

					4'b0001: hmesh_last <= csr_di[6:0];
					4'b0010: vmesh_last <= csr_di[6:0];

					4'b0011: brightness <= csr_di[5:0];
					4'b0100: chroma_key <= csr_di[15:0];

					4'b0101: src_mesh <= csr_di[31:2];
					4'b0110: src_fbuf <= csr_di[fml_depth-1:1];
					4'b0111: src_hres <= csr_di[10:0];
					4'b1000: src_vres <= csr_di[10:0];

					4'b1001: dst_mesh <= csr_di[31:2];
					4'b1010: dst_fbuf <= csr_di[fml_depth-1:1];
					4'b1011: dst_hres <= csr_di[10:0];
					4'b1100: dst_vres <= csr_di[10:0];
					default:;
				endcase
			end
			case(csr_a[4:0])
				5'b00000: csr_do <= {chroma_key_en, irq, busy};
				
				5'b00001: csr_do <= hmesh_last;
				5'b00010: csr_do <= vmesh_last;

				5'b00011: csr_do <= brightness;
				5'b00100: csr_do <= chroma_key;

				5'b00101: csr_do <= {src_mesh, 2'b00};
				5'b00110: csr_do <= {src_fbuf, 1'b0};
				5'b00111: csr_do <= src_hres;
				5'b01000: csr_do <= src_vres;

				5'b01001: csr_do <= {dst_mesh, 2'b00};
				5'b01010: csr_do <= {dst_fbuf, 1'b0};
				5'b01011: csr_do <= dst_hres;
				5'b01100: csr_do <= dst_vres;

				/* Performance counters */
				5'b01101: csr_do <= perf_pixels;
				5'b01110: csr_do <= perf_clocks;

				5'b01111: csr_do <= perf_stall1;
				5'b10000: csr_do <= perf_complete1;
				5'b10001: csr_do <= perf_stall2;
				5'b10010: csr_do <= perf_complete2;

				5'b10011: csr_do <= perf_misses;
				default: csr_do <= 32'bx;
			endcase
		end
	end
end

endmodule
