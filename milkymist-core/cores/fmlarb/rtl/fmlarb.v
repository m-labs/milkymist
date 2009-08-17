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

module fmlarb #(
	parameter fml_depth = 26
) (
	input sys_clk,
	input sys_rst,
	
	/* Interface 0 has higher priority than the others */
	input [fml_depth-1:0] m0_adr,
	input m0_stb,
	input m0_we,
	output m0_ack,
	input [7:0] m0_sel,
	input [63:0] m0_di,
	output [63:0] m0_do,
	
	input [fml_depth-1:0] m1_adr,
	input m1_stb,
	input m1_we,
	output m1_ack,
	input [7:0] m1_sel,
	input [63:0] m1_di,
	output [63:0] m1_do,
	
	input [fml_depth-1:0] m2_adr,
	input m2_stb,
	input m2_we,
	output m2_ack,
	input [7:0] m2_sel,
	input [63:0] m2_di,
	output [63:0] m2_do,
	
	input [fml_depth-1:0] m3_adr,
	input m3_stb,
	input m3_we,
	output m3_ack,
	input [7:0] m3_sel,
	input [63:0] m3_di,
	output [63:0] m3_do,
	
	output reg [fml_depth-1:0] s_adr,
	output reg s_stb,
	output reg s_we,
	input s_ack,
	output reg [7:0] s_sel,
	input [63:0] s_di,
	output reg [63:0] s_do
);

assign m0_do = s_di;
assign m1_do = s_di;
assign m2_do = s_di;
assign m3_do = s_di;

reg [1:0] master;
reg [1:0] next_master;

always @(posedge sys_clk) begin
	if(sys_rst)
		master <= 2'd0;
	else
		master <= next_master;
end

reg write_lock; /* see below */

/* Decide the next master */
always @(*) begin
	/* By default keep our current master */
	next_master = master;
	
	case(master)
		2'b00: if(~m0_stb & ~write_lock) begin
			if(m1_stb) next_master = 2'd1;
			else if(m2_stb) next_master = 2'd2;
			else if(m3_stb) next_master = 2'd3;
		end
		2'b01: if(~m1_stb & ~write_lock) begin
			if(m0_stb) next_master = 2'd0;
			else if(m3_stb) next_master = 2'd3;
			else if(m2_stb) next_master = 2'd2;
		end
		2'b10: if(~m2_stb & ~write_lock) begin
			if(m0_stb) next_master = 2'd0;
			else if(m3_stb) next_master = 2'd3;
			else if(m1_stb) next_master = 2'd1;
		end
		2'b11: if(~m3_stb & ~write_lock) begin
			if(m0_stb) next_master = 2'd0;
			else if(m1_stb) next_master = 2'd1;
			else if(m2_stb) next_master = 2'd2;
		end
	endcase
end

/* Mux the masters */
assign m0_ack = (master == 2'd0) & s_ack;
assign m1_ack = (master == 2'd1) & s_ack;
assign m2_ack = (master == 2'd2) & s_ack;
assign m3_ack = (master == 2'd3) & s_ack;

always @(*) begin
	case(master)
		2'b00: begin
			s_adr = m0_adr;
			s_stb = m0_stb;
			s_we = m0_we;
			s_sel = m0_sel;
			s_do = m0_di;
		end
		2'b01: begin
			s_adr = m1_adr;
			s_stb = m1_stb;
			s_we = m1_we;
			s_sel = m1_sel;
			s_do = m1_di;
		end
		2'b10: begin
			s_adr = m2_adr;
			s_stb = m2_stb;
			s_we = m2_we;
			s_sel = m2_sel;
			s_do = m2_di;
		end
		2'b11: begin
			s_adr = m3_adr;
			s_stb = m3_stb;
			s_we = m3_we;
			s_sel = m3_sel;
			s_do = m3_di;
		end
	endcase
end

/* Generate the write lock signal:
 * when writing, the bus ownership must remain
 * to the same master until the end of the burst.
 * So the write lock signal gets asserted on the cycle
 * after the ack (when the master releases its strobe)
 * and remains asserted for 2 cycles, taking into account
 * the latency cycle of the arbiter.
 * Thus, if another master requests the bus, it will only
 * be granted access right after the last burst word
 * has been transferred.
 */
wire write_burst_start = s_we & s_ack;
reg write_lock_release;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		write_lock <= 1'b0;
		write_lock_release <= 1'b0;
	end else begin
		if(write_burst_start) begin
			write_lock <= 1'b1;
			write_lock_release <= 1'b0;
		end else begin
			if(write_lock) begin
				if(write_lock_release)
					write_lock <= 1'b0;
				else
					write_lock_release <= 1'b1;
			end
		end
	end
end

endmodule
