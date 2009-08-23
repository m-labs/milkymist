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

module norflash8 #(
	parameter adr_width = 22,
	parameter timing = 4'd13
) (
	input sys_clk,
	input sys_rst,

	input [31:0] wb_adr_i,
	output reg [31:0] wb_dat_o,
	input wb_stb_i,
	input wb_cyc_i,
	output reg wb_ack_o,
	
	output [adr_width-1:0] flash_adr,
	input [7:0] flash_d
);

reg [adr_width-1-2:0] flash_adr_msb;
reg [1:0] flash_adr_lsb;

assign flash_adr = {flash_adr_msb, flash_adr_lsb};

reg load;
reg reset_flash_adr_lsb;
always @(posedge sys_clk) begin
	/* Use IOB registers to prevent glitches on address lines */
	if(wb_cyc_i & wb_stb_i) /* register only when needed to reduce EMI */
		flash_adr_msb <= wb_adr_i[adr_width-1:2];
	if(load) begin
		case(flash_adr_lsb[1:0])
			2'b00: wb_dat_o[31:24] <= flash_d;
			2'b01: wb_dat_o[23:16] <= flash_d;
			2'b10: wb_dat_o[15:8] <= flash_d;
			2'b11: wb_dat_o[7:0] <= flash_d;
		endcase
		flash_adr_lsb <= flash_adr_lsb + 2'd1;
	end
	if(reset_flash_adr_lsb)
		flash_adr_lsb <= 2'd0;
end

/*
 * Timing of the flash chips is typically 110ns.
 */
reg [3:0] counter;
reg counter_en;
wire counter_done = (counter == timing);
always @(posedge sys_clk) begin
	if(sys_rst)
		counter <= 4'd0;
	else begin
		if(counter_en & ~counter_done)
			counter <= counter + 4'd1;
		else
			counter <= 4'd0;
	end
end

reg [1:0] state;
reg [1:0] next_state;
always @(posedge sys_clk) begin
	if(sys_rst)
		state <= 1'b0;
	else
		state <= next_state;
end

always @(*) begin
	next_state = state;
	reset_flash_adr_lsb = 1'b0;
	counter_en = 1'b0;
	load = 1'b0;
	wb_ack_o = 1'b0;

	case(state)
		2'd0: begin
			reset_flash_adr_lsb = 1'b1;
			if(wb_cyc_i & wb_stb_i)
				next_state = 2'd1;
		end

		2'd1: begin
			counter_en = 1'b1;
			if(counter_done) begin
				load = 1'b1;
				if(flash_adr_lsb == 2'b11)
					next_state = 2'd2;
			end
		end

		2'd2: begin
			wb_ack_o = 1'b1;
			next_state = 2'd0;
		end
	endcase
end

endmodule
