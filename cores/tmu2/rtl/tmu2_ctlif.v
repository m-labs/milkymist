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

module tmu2_ctlif #(
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

	output reg [6:0] vertex_hlast,
	output reg [6:0] vertex_vlast,
	output reg [5:0] brightness,
	output reg chroma_key_en,
	output reg additive_en,
	output reg [15:0] chroma_key,
	output reg [28:0] vertex_adr,
	output reg [fml_depth-1-1:0] tex_fbuf,
	output reg [10:0] tex_hres,
	output reg [10:0] tex_vres,
	output reg [17:0] tex_hmask,
	output reg [17:0] tex_vmask,
	output reg [fml_depth-1-1:0] dst_fbuf,
	output reg [10:0] dst_hres,
	output reg [10:0] dst_vres,
	output reg signed [11:0] dst_hoffset,
	output reg signed [11:0] dst_voffset,
	output reg [10:0] dst_squarew,
	output reg [10:0] dst_squareh,
	output reg alpha_en,
	output reg [5:0] alpha
);

reg old_busy;
always @(posedge sys_clk) begin
	if(sys_rst)
		old_busy <= 1'b0;
	else
		old_busy <= busy;
end

wire csr_selected = csr_a[13:10] == csr_addr;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		csr_do <= 32'd0;
		irq <= 1'b0;
		start <= 1'b0;

		vertex_hlast <= 7'd32;
		vertex_vlast <= 7'd24;

		brightness <= 6'd63;
		chroma_key_en <= 1'b0;
		additive_en <= 1'b0;
		chroma_key <= 16'd0;
		
		vertex_adr <= 29'd0;
		
		tex_fbuf <= {fml_depth{1'b0}};
		tex_hres <= 11'd512;
		tex_vres <= 11'd512;
		tex_hmask <= {18{1'b1}};
		tex_vmask <= {18{1'b1}};
		
		dst_fbuf <= {fml_depth{1'b0}};
		dst_hres <= 11'd640;
		dst_vres <= 11'd480;
		dst_hoffset <= 12'd0;
		dst_voffset <= 12'd0;
		dst_squarew <= 11'd16;
		dst_squareh <= 11'd16;

		alpha_en <= 1'b0;
		alpha <= 6'd63;
	end else begin
		irq <= old_busy & ~busy;
		
		csr_do <= 32'd0;
		start <= 1'b0;
		if(csr_selected) begin
			if(csr_we) begin
				case(csr_a[4:0])
					5'b00000: begin
						start <= csr_di[0];
						chroma_key_en <= csr_di[1];
						additive_en <= csr_di[2];
					end

					5'b00001: vertex_hlast <= csr_di[6:0];
					5'b00010: vertex_vlast <= csr_di[6:0];

					5'b00011: brightness <= csr_di[5:0];
					5'b00100: chroma_key <= csr_di[15:0];

					5'b00101: vertex_adr <= csr_di[31:3];
					
					5'b00110: tex_fbuf <= csr_di[fml_depth-1:1];
					5'b00111: tex_hres <= csr_di[10:0];
					5'b01000: tex_vres <= csr_di[10:0];
					5'b01001: tex_hmask <= csr_di[17:0];
					5'b01010: tex_vmask <= csr_di[17:0];

					5'b01011: dst_fbuf <= csr_di[fml_depth-1:1];
					5'b01100: dst_hres <= csr_di[10:0];
					5'b01101: dst_vres <= csr_di[10:0];
					5'b01110: dst_hoffset <= csr_di[11:0];
					5'b01111: dst_voffset <= csr_di[11:0];
					5'b10000: dst_squarew <= csr_di[10:0];
					5'b10001: dst_squareh <= csr_di[10:0];

					5'b10010: begin
						alpha_en <= csr_di[5:0] != 6'd63;
						alpha <= csr_di[5:0];
					end
					default:;
				endcase
			end
			case(csr_a[4:0])
				5'b00000: csr_do <= {chroma_key_en, busy};
				
				5'b00001: csr_do <= vertex_hlast;
				5'b00010: csr_do <= vertex_vlast;

				5'b00011: csr_do <= brightness;
				5'b00100: csr_do <= chroma_key;

				5'b00101: csr_do <= {vertex_adr, 3'd0};

				5'b00110: csr_do <= {tex_fbuf, 1'd0};
				5'b00111: csr_do <= tex_hres;
				5'b01000: csr_do <= tex_vres;
				5'b01001: csr_do <= tex_hmask;
				5'b01010: csr_do <= tex_vmask;

				5'b01011: csr_do <= {dst_fbuf, 1'd0};
				5'b01100: csr_do <= dst_hres;
				5'b01101: csr_do <= dst_vres;
				5'b01110: csr_do <= dst_hoffset;
				5'b01111: csr_do <= dst_voffset;
				5'b10000: csr_do <= dst_squarew;
				5'b10001: csr_do <= dst_squareh;

				5'b10010: csr_do <= alpha;

				default: csr_do <= 32'bx;
			endcase
		end
	end
end

endmodule
