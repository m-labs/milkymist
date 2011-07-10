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

/*
 * This file is based on "Asynchronous FIFO" by Alex Claros F.,
 * itself based on the article "Asynchronous FIFO in Virtex-II FPGAs"
 * by Peter Alfke.
 */

module asfifo #(
	parameter data_width = 8,
	parameter address_width = 4,
	parameter fifo_depth = (1 << address_width)
) (
	/* Read port */
	output [data_width-1:0] data_out,
	output reg empty,
	input read_en,
	input clk_read,
	
	/* Write port */
	input [data_width-1:0] data_in,
	output reg full,
	input write_en,
	input clk_write,
	
	/* Asynchronous reset */
	input rst
);

reg [data_width-1:0] mem[fifo_depth-1:0];
wire [address_width-1:0] write_index, read_index;
wire equal_addresses;
wire write_en_safe, read_en_safe;
wire set_status, clear_status;
reg status;
wire preset_full, preset_empty;

assign data_out = mem[read_index];

always @(posedge clk_write) begin
	if(write_en & !full)
		mem[write_index] <= data_in;
end

assign write_en_safe = write_en & ~full;
assign read_en_safe = read_en & ~empty;

asfifo_graycounter #(
	.width(address_width)
) counter_write (
	.gray_count(write_index),
	.ce(write_en_safe),
	.rst(rst),
	.clk(clk_write)
);

asfifo_graycounter #(
	.width(address_width)
) counter_read (
	.gray_count(read_index),
	.ce(read_en_safe),
	.rst(rst),
	.clk(clk_read)
);

assign equal_addresses = (write_index == read_index);

assign set_status = (write_index[address_width-2] ~^ read_index[address_width-1]) &
	(write_index[address_width-1] ^ read_index[address_width-2]);

assign clear_status = ((write_index[address_width-2] ^ read_index[address_width-1]) &
	(write_index[address_width-1] ~^ read_index[address_width-2]))
	| rst;

always @(posedge clear_status, posedge set_status) begin
	if(clear_status)
		status <= 1'b0;
	else
		status <= 1'b1;
end

assign preset_full = status & equal_addresses;

always @(posedge clk_write, posedge preset_full) begin
	if(preset_full)
		full <= 1'b1;
	else
		full <= 1'b0;
end

assign preset_empty = ~status & equal_addresses;

always @(posedge clk_read, posedge preset_empty) begin
	if(preset_empty)
		empty <= 1'b1;
	else
		empty <= 1'b0;
end

endmodule
