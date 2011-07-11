/*
 * Milkymist SoC
 * Copyright (C) 2007, 2008, 2009, 2010, 2011 Sebastien Bourdeauducq
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

module fmlmeter #(
	parameter csr_addr = 4'h0,
	parameter fml_depth = 26
) (
	input sys_clk,
	input sys_rst,

	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output reg [31:0] csr_do,

	input fml_stb,
	input fml_ack,
	input fml_we,
	input [fml_depth-1:0] fml_adr
);

/* Register the signals we probe to have a minimal impact on timing */
reg fml_stb_r;
reg fml_ack_r;
reg fml_we_r;
reg [fml_depth-1:0] fml_adr_r;
always @(posedge sys_clk) begin
	fml_stb_r <= fml_stb;
	fml_ack_r <= fml_ack;
	fml_we_r <= fml_we;
	fml_adr_r <= fml_adr;
end

reg counters_en;		// @ 00
reg [31:0] stb_count;		// @ 04
reg [31:0] ack_count;		// @ 08
reg [12:0] capture_wadr;	// @ 0c
reg [11:0] capture_radr;	// @ 10
reg [fml_depth:0] capture_do;	// @ 14

reg [fml_depth:0] capture_mem[0:4095];
wire capture_en = ~capture_wadr[12];
wire capture_we = capture_en & fml_stb_r & fml_ack_r;
wire [11:0] capture_adr = capture_we ? capture_wadr[11:0] : capture_radr;
wire [fml_depth:0] capture_di = {fml_we_r, fml_adr_r};

always @(posedge sys_clk) begin
	if(capture_we)
		capture_mem[capture_adr] <= capture_di;
	capture_do <= capture_mem[capture_adr];
end

wire csr_selected = csr_a[13:10] == csr_addr;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		counters_en <= 1'b0;
		stb_count <= 32'd0;
		ack_count <= 32'd0;
		
		capture_wadr <= 13'd4096;
		capture_radr <= 12'd0;

		csr_do <= 32'd0;
	end else begin
		if(counters_en) begin
			if(fml_stb_r)
				stb_count <= stb_count + 32'd1;
			if(fml_ack_r)
				ack_count <= ack_count + 32'd1;
		end
		
		if(capture_we)
			capture_wadr <= capture_wadr + 13'd1;

		csr_do <= 32'd0;
		if(csr_selected) begin
			if(csr_we) begin
				case(csr_a[2:0])
					3'b000: begin
						counters_en <= csr_di[0];
						if(csr_di[0]) begin
							stb_count <= 32'd0;
							ack_count <= 32'd0;
						end
					end
					// 3'b001 stb_count is read-only
					// 3'b010 ack_count is read-only
					3'b011: capture_wadr <= 13'd0;
					3'b100: capture_radr <= csr_di[11:0];
					// 3'b101 capture_do is read-only
				endcase
			end

			case(csr_a[3:0])
				3'b000: csr_do <= counters_en;
				3'b001: csr_do <= stb_count;
				3'b010: csr_do <= ack_count;
				3'b011: csr_do <= capture_wadr;
				3'b100: csr_do <= capture_radr;
				3'b101: csr_do <= capture_do;
			endcase
		end
	end
end

endmodule
