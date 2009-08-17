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

/* Simple FML interface for HPDMC */

module hpdmc_busif #(
	parameter sdram_depth = 26
) (
	input sys_clk,
	input sdram_rst,
	
	input [sdram_depth-1:0] fml_adr,
	input fml_stb,
	input fml_we,
	output fml_ack,
	
	output mgmt_stb,
	output mgmt_we,
	output [sdram_depth-3-1:0] mgmt_address, /* in 64-bit words */
	input mgmt_ack,
	
	input data_ack
);

reg mgmt_stb_en;

assign mgmt_stb = fml_stb & mgmt_stb_en;
assign mgmt_we = fml_we;
assign mgmt_address = fml_adr[sdram_depth-1:3];

assign fml_ack = data_ack;

always @(posedge sys_clk) begin
	if(sdram_rst)
		mgmt_stb_en = 1'b1;
	else begin
		if(mgmt_ack)
			mgmt_stb_en = 1'b0;
		if(data_ack)
			mgmt_stb_en = 1'b1;
	end
end

endmodule
