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

module bt656cap_ctlif #(
	parameter csr_addr = 4'h0,
	parameter fml_depth = 27
) (
	input sys_clk,
	input sys_rst,

	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output reg [31:0] csr_do,

	output reg irq,

	output reg [1:0] field_filter,
	input in_frame,
	output reg [fml_depth-1-5:0] fml_adr_base,
	input start_of_frame,
	input next_burst,
	output reg last_burst,

	inout sda,
	output reg sdc
);

/* I2C */
reg sda_1;
reg sda_2;
reg sda_oe;
reg sda_o;

always @(posedge sys_clk) begin
	sda_1 <= sda;
	sda_2 <= sda_1;
end

assign sda = (sda_oe & ~sda_o) ? 1'b0 : 1'bz;

/* CSR IF */

wire csr_selected = csr_a[13:10] == csr_addr;

reg [14:0] max_bursts;
reg [14:0] done_bursts;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		csr_do <= 32'd0;

		field_filter <= 2'd0;
		fml_adr_base <= {fml_depth-5{1'b0}};
		max_bursts <= 15'd12960;

		sda_oe <= 1'b0;
		sda_o <= 1'b0;
		sdc <= 1'b0;
	end else begin
		csr_do <= 32'd0;

		if(csr_selected) begin
			if(csr_we) begin
				case(csr_a[2:0])
					3'd0: begin
						sda_o <= csr_di[1];
						sda_oe <= csr_di[2];
						sdc <= csr_di[3];
					end
					3'd1: field_filter <= csr_di[1:0];
					3'd2: fml_adr_base <= csr_di[fml_depth-1:5];
					3'd3: max_bursts <= csr_di[14:0];
				endcase
			end

			case(csr_a[2:0])
				3'd0: csr_do <= {sdc, sda_oe, sda_o, sda_2};
				3'd1: csr_do <= {in_frame, field_filter};
				3'd2: csr_do <= {fml_adr_base, 5'd0};
				3'd3: csr_do <= max_bursts;
				3'd4: csr_do <= done_bursts;
			endcase
		end
	end
end

reg in_frame_r;
always @(posedge sys_clk) begin
	if(sys_rst) begin
		in_frame_r <= 1'b0;
		irq <= 1'b0;
	end else begin
		in_frame_r <= in_frame;
		irq <= in_frame_r & ~in_frame;
	end
end

reg [14:0] burst_counter;
always @(posedge sys_clk) begin
	if(sys_rst) begin
		last_burst <= 1'b0;
		burst_counter <= 15'd0;
	end else begin
		if(start_of_frame) begin
			last_burst <= 1'b0;
			burst_counter <= 15'd0;
			done_bursts <= burst_counter;
		end
		if(next_burst) begin
			burst_counter <= burst_counter + 15'd1;
			last_burst <= (burst_counter + 15'd1) == max_bursts;
		end
	end
end

endmodule
