/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
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

module vgafb_pixelfeed #(
	parameter fml_depth = 26
) (
	input sys_clk,
	/* We must take into account both resets :
	 * VGA reset should not interrupt a pending FML request
	 * but system reset should.
	 */
	input sys_rst,
	input vga_rst,
	
	input [17:0] nbursts,
	input [fml_depth-1:0] baseaddress,
	output baseaddress_ack,
	
	output reg [fml_depth-1:0] fml_adr,
	output reg fml_stb,
	input fml_ack,
	input [63:0] fml_di,
	
	output pixel_valid,
	output [15:0] pixel,
	input pixel_ack
);

/* FIFO that stores the 64-bit bursts and slices it in 16-bit words */

reg fifo_stb;
wire fifo_valid;

vgafb_fifo64to16 fifo64to16(
	.sys_clk(sys_clk),
	.vga_rst(vga_rst),
	
	.stb(fifo_stb),
	.di(fml_di),
	
	.do_valid(fifo_valid),
	.do(pixel),
	.next(pixel_ack)
);

assign pixel_valid = fifo_valid;

/* BURST COUNTER */
reg sof;
wire counter_en;

reg [17:0] bcounter;

always @(posedge sys_clk) begin
	if(vga_rst) begin
		bcounter <= 18'd1;
		sof <= 1'b1;
	end else begin
		if(counter_en) begin
			if(bcounter == nbursts) begin
				bcounter <= 18'd1;
				sof <= 1'b1;
			end else begin
				bcounter <= bcounter + 18'd1;
				sof <= 1'b0;
			end
		end
	end
end

/* FML ADDRESS GENERATOR */
wire next_address;

assign baseaddress_ack = sof & next_address;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		fml_adr <= {fml_depth{1'b0}};
	end else begin
		if(next_address) begin
			if(sof)
				fml_adr <= baseaddress;
			else
				fml_adr <= fml_adr + {{fml_depth-6{1'b0}}, 6'd32};
		end
	end
end

/* CONTROLLER */
reg [2:0] state;
reg [2:0] next_state;

parameter IDLE		= 3'd0;
parameter WAIT		= 3'd1;
parameter FETCH2	= 3'd2;
parameter FETCH3	= 3'd3;
parameter FETCH4	= 3'd4;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= IDLE;
	else
		state <= next_state;
end

/*
 * Do not put spurious data into the FIFO if the VGA reset
 * is asserted and released during the FML access. Getting
 * the FIFO out of sync would result in distorted pictures
 * we really want to avoid.
 */

reg ignore;
reg ignore_clear;

always @(posedge sys_clk) begin
	if(vga_rst)
		ignore <= 1'b1;
	else if(ignore_clear)
		ignore <= 1'b0;
end

reg next_burst;

assign counter_en = next_burst;
assign next_address = next_burst;

always @(*) begin
	next_state = state;
	
	fifo_stb = 1'b0;
	next_burst = 1'b0;
	
	fml_stb = 1'b0;
	ignore_clear = 1'b0;
	
	case(state)
		IDLE: begin
			if(~fifo_valid & ~vga_rst) begin
				/* We're in need of pixels ! */
				next_burst = 1'b1;
				ignore_clear = 1'b1;
				next_state = WAIT;
			end
		end
		WAIT: begin
			fml_stb = 1'b1;
			if(fml_ack) begin
				if(~ignore) fifo_stb = 1'b1;
				next_state = FETCH2;
 			end
		end
		FETCH2: begin
			if(~ignore) fifo_stb = 1'b1;
			next_state = FETCH3;
		end
		FETCH3: begin
			if(~ignore) fifo_stb = 1'b1;
			next_state = FETCH4;
		end
		FETCH4: begin
			if(~ignore) fifo_stb = 1'b1;
			next_state = IDLE;
		end
	endcase
end

endmodule
