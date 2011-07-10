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

module bt656cap_input(
	input sys_clk,
	input sys_rst,
	input vid_clk,

	input [7:0] p,

	output stb,
	input ack,
	output field,
	output [31:0] rgb565
);

wire decoder_stb;
wire decoder_field;
wire [31:0] decoder_ycc422;
bt656cap_decoder decoder(
	.vid_clk(vid_clk),
	.p(p),

	.stb(decoder_stb),
	.field(decoder_field),
	.ycc422(decoder_ycc422)
);

wire colorspace_stb;
wire colorspace_field;
wire [31:0] colorspace_rgb565;
bt656cap_colorspace colorspace(
	.vid_clk(vid_clk),

	.stb_i(decoder_stb),
	.field_i(decoder_field),
	.ycc422(decoder_ycc422),

	.stb_o(colorspace_stb),
	.field_o(colorspace_field),
	.rgb565(colorspace_rgb565)
);

wire empty;
asfifo #(
	.data_width(33),
	.address_width(6)
) fifo (
	.data_out({field, rgb565}),
	.empty(empty),
	.read_en(ack),
	.clk_read(sys_clk),

	.data_in({colorspace_field, colorspace_rgb565}),
	.full(),
	.write_en(colorspace_stb),
	.clk_write(vid_clk),

	.rst(sys_rst)
);
assign stb = ~empty;

endmodule
