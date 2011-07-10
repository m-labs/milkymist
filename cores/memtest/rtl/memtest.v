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

module memtest #(
	parameter csr_addr = 4'h0,
	parameter fml_depth = 26
) (
	input sys_clk,
	input sys_rst,

	/* Configuration interface */
	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output reg [31:0] csr_do,

	/* Framebuffer FML 4x64 interface */
	output [fml_depth-1:0] fml_adr,
	output reg fml_stb,
	output reg fml_we,
	input fml_ack,
	input [63:0] fml_di,
	output [7:0] fml_sel,
	output [63:0] fml_do
);

wire rand_ce;
wire [63:0] rand;

wire csr_selected = csr_a[13:10] == csr_addr;
wire load_nbursts = csr_selected & (csr_a[2:0] == 3'd0) & csr_we;
wire load_address = csr_selected & (csr_a[2:0] == 3'd2) & csr_we;

memtest_prng64 prng_data(
	.clk(sys_clk),
	.rst(load_nbursts),
	.ce(rand_ce),
	.rand(rand)
);

wire [19:0] fml_adr_bot;
memtest_prng20 prng_address(
	.clk(sys_clk),
	.rst(load_address),
	.ce(fml_ack),
	.rand(fml_adr_bot)
);

assign fml_sel = 8'hff;
assign fml_do = rand;

reg nomatch;
always @(posedge sys_clk)
	nomatch <= fml_di != rand;

reg [31:0] remaining_bursts;
always @(posedge sys_clk) begin
	if(sys_rst) begin
		remaining_bursts <= 32'd0;
		fml_stb <= 1'b0;
	end else begin
		if(load_nbursts) begin
			remaining_bursts <= csr_di;
			fml_stb <= 1'b1;
		end else begin
			if(fml_ack) begin
				remaining_bursts <= remaining_bursts - 32'd1;
				if(remaining_bursts == 32'd1)
					fml_stb <= 1'b0;
			end
		end
	end
end

reg [1:0] burst_counter;
always @(posedge sys_clk) begin
	if(sys_rst)
		burst_counter <= 2'd0;
	else begin
		if(fml_ack)
			burst_counter <= 2'd3;
		else if(|burst_counter)
			burst_counter <= burst_counter - 2'd1;
	end
end
assign rand_ce = |burst_counter | fml_ack;

reg rand_ce_r;
reg [31:0] errcount;
always @(posedge sys_clk) begin
	rand_ce_r <= rand_ce;
	if(sys_rst)
		errcount <= 32'd0;
	else if(csr_selected & (csr_a[2:0] == 3'd1) & csr_we)
		errcount <= 32'd0;
	else if(rand_ce_r & nomatch)
		errcount <= errcount + 32'd1;
end

reg [fml_depth-1-25:0] fml_adr_top;
always @(posedge sys_clk) begin
	if(sys_rst)
		fml_adr_top <= 0;
	else if(load_address)
		fml_adr_top <= csr_di[fml_depth-1:25];
end
assign fml_adr = {fml_adr_top, fml_adr_bot, 5'd0};

always @(posedge sys_clk) begin
	if(csr_selected & (csr_a[2:0] == 3'd3) & csr_we)
		fml_we <= csr_di[0];
end

always @(posedge sys_clk) begin
	if(sys_rst)
		csr_do <= 32'd0;
	else begin
		csr_do <= 32'd0;
		if(csr_selected) begin
			case(csr_a[2:0])
				3'd0: csr_do <= remaining_bursts;
				3'd1: csr_do <= errcount;
				3'd2: csr_do <= fml_adr;
				3'd3: csr_do <= fml_we;
			endcase
		end
	end
end

endmodule
