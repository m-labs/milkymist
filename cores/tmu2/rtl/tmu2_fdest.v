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

module tmu2_fdest #(
	parameter fml_depth = 26
) (
	input sys_clk,
	input sys_rst,

	output [fml_depth-1:0] fml_adr,
	output reg fml_stb,
	input fml_ack,
	input [63:0] fml_di,

	input flush,
	output busy,

	input fetch_en,

	input pipe_stb_i,
	output reg pipe_ack_o,
	input [15:0] color,
	input [fml_depth-1-1:0] dadr, /* in 16-bit words */

	output pipe_stb_o,
	input pipe_ack_i,
	output reg [15:0] color_f,
	output [fml_depth-1-1:0] dadr_f, /* in 16-bit words */
	output reg [15:0] dcolor
);

/* Hit detection */
reg valid;
reg [fml_depth-1-1-4:0] tag;

reg [fml_depth-1-1:0] dadr_r;

reg hit;

reg tag_we;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		valid <= 1'b0;
		hit <= 1'b0;
		dadr_r <= {fml_depth-1{1'b0}};
	end else begin
		if(tag_we)
			valid <= 1'b1;
		if(flush)
			valid <= 1'b0;
		if(pipe_stb_i & pipe_ack_o) begin
			hit <= valid & (tag == dadr[fml_depth-1-1:4]);
			dadr_r <= dadr;
		end
	end
end

always @(posedge sys_clk) begin
	if(sys_rst)
		tag <= {fml_depth-1-4{1'b0}};
	else if(tag_we)
		tag <= dadr_r[fml_depth-1-1:4];
end

/* Forward */
always @(posedge sys_clk) begin
	if(sys_rst)
		color_f <= 16'd0;
	else if(pipe_stb_i & pipe_ack_o)
		color_f <= color;
end

assign dadr_f = dadr_r;

/* Storage */
reg [63:0] storage[0:3];

// synthesis translate_off
initial begin
	storage[0] = 64'd0;
	storage[1] = 64'd0;
	storage[2] = 64'd0;
	storage[3] = 64'd0;
end
// synthesis translate_on

wire [63:0] storage_do = storage[dadr_r[3:2]];
always @(*) begin
	case(dadr_r[1:0])
		2'd0: dcolor = storage_do[63:48];
		2'd1: dcolor = storage_do[47:32];
		2'd2: dcolor = storage_do[31:16];
		2'd3: dcolor = storage_do[15:0];
	endcase
end

reg [1:0] storage_wa;
reg storage_we;
always @(posedge sys_clk) begin
	if(storage_we)
		storage[storage_wa] = fml_di;
end

/* Control & bus master */

assign fml_adr = {dadr_r[fml_depth-1-1:4], 5'd0};

reg wanted;
always @(posedge sys_clk) begin
	if(sys_rst)
		wanted <= 1'b0;
	else if(pipe_ack_o)
		wanted <= pipe_stb_i;
end

reg stb_after_fetch;

reg [2:0] state;
reg [2:0] next_state;

parameter IDLE =	3'd0;
parameter FETCH1 =	3'd1;
parameter FETCH2 =	3'd2;
parameter FETCH3 =	3'd3;
parameter FETCH4 =	3'd4;
parameter OUT =		3'd5;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= IDLE;
	else
		state <= next_state;
end

always @(*) begin
	next_state = state;

	tag_we = 1'b0;
	
	storage_we = 1'b0;
	storage_wa = 2'bx;

	fml_stb = 1'b0;

	pipe_ack_o = 1'b0;
	stb_after_fetch = 1'b0;

	case(state)
		IDLE: begin
			pipe_ack_o = pipe_ack_i | ~wanted;
			if(wanted & ~hit & fetch_en) begin
				pipe_ack_o = 1'b0;
				next_state = FETCH1;
			end
		end
		FETCH1: begin
			fml_stb = 1'b1;
			storage_we = 1'b1;
			storage_wa = 2'd0;
			if(fml_ack)
				next_state = FETCH2;
		end
		FETCH2: begin
			storage_we = 1'b1;
			storage_wa = 2'd1;
			next_state = FETCH3;
		end
		FETCH3: begin
			storage_we = 1'b1;
			storage_wa = 2'd2;
			next_state = FETCH4;
		end
		FETCH4: begin
			storage_we = 1'b1;
			storage_wa = 2'd3;
			tag_we = 1'b1;
			next_state = OUT;
		end
		OUT: begin
			stb_after_fetch = 1'b1;
			pipe_ack_o = pipe_ack_i;
			if(pipe_ack_i)
				next_state = IDLE;
		end
	endcase
end

assign pipe_stb_o = stb_after_fetch | (wanted & (hit | ~fetch_en));
assign busy = wanted;

endmodule
