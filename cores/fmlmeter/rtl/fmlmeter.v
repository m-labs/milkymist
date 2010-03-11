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

module fmlmeter #(
	parameter csr_addr = 4'h0
) (
	input sys_clk,
	input sys_rst,

	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output reg [31:0] csr_do,

	input fml_stb,
	input fml_ack
);

/* Register the signals we probe to have a minimal impact on timing */
reg fml_stb_r;
reg fml_ack_r;
always @(posedge sys_clk) begin
	fml_stb_r <= fml_stb;
	fml_ack_r <= fml_ack;
end

reg en;			// @ 00
reg [31:0] stb_count;	// @ 04
reg [31:0] ack_count;	// @ 08

wire csr_selected = csr_a[13:10] == csr_addr;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		en <= 1'b0;
		stb_count <= 32'd0;
		ack_count <= 32'd0;

		csr_do <= 32'd0;
	end else begin
		if(en) begin
			if(fml_stb_r)
				stb_count <= stb_count + 32'd1;
			if(fml_ack_r)
				ack_count <= ack_count + 32'd1;
		end

		csr_do <= 32'd0;
		if(csr_selected) begin
			if(csr_we) begin
				/* Assume all writes are for the ENABLE register
				 * (others are read-only)
				 */
				en <= csr_di[0];
				if(csr_di[0]) begin
					stb_count <= 32'd0;
					ack_count <= 32'd0;
				end
			end

			case(csr_a[1:0])
				2'b00: csr_do <= en;
				2'b01: csr_do <= stb_count;
				2'b10: csr_do <= ack_count;
			endcase
		end
	end
end

endmodule
