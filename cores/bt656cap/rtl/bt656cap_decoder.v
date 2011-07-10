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
 * This module takes the BT.656 stream and puts out 32-bit
 * chunks coded in YCbCr 4:2:2 that correspond to 2 pixels.
 * Only pixels from the active video area are taken into account.
 * The field signal indicates the current field used for interlacing.
 * Transitions on this signal should be monitored to detect the start
 * of frames.
 * When the input signal is stable, this modules puts out no more
 * than one chunk every 4 clocks.
 */

module bt656cap_decoder(
	input vid_clk,
	input [7:0] p,

	output reg stb,
	output reg field,
	output reg [31:0] ycc422
);

reg [7:0] ioreg;
always @(posedge vid_clk) ioreg <= p;

reg [1:0] byten;
reg [31:0] inreg;
initial begin
	byten <= 2'd0;
	inreg <= 32'd0;
end
always @(posedge vid_clk) begin
	if(&ioreg) begin
		/* sync word */
		inreg[31:24] <= ioreg;
		byten <= 2'd1;
	end else begin
		byten <= byten + 2'd1;
		case(byten)
			2'd0: inreg[31:24] <= ioreg;
			2'd1: inreg[23:16] <= ioreg;
			2'd2: inreg[15: 8] <= ioreg;
			2'd3: inreg[ 7: 0] <= ioreg;
		endcase
	end
end

reg in_field;
reg in_hblank;
reg in_vblank;

initial begin
	in_field <= 1'b0;
	in_hblank <= 1'b0;
	in_vblank <= 1'b0;
	stb <= 1'b0;
end
always @(posedge vid_clk) begin
	stb <= 1'b0;
	if(byten == 2'd0) begin
		/* just transferred a new 32-bit word */
		if(inreg[31:8] == 24'hff0000) begin
			/* timing code */
			in_hblank <= inreg[4];
			in_vblank <= inreg[5];
			in_field <= inreg[6];
		end else begin
			/* data */
			if(~in_hblank && ~in_vblank) begin
				stb <= 1'b1;
				field <= in_field;
				ycc422 <= inreg;
			end
		end
	end
end

endmodule
