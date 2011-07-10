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

module bt656cap_dma #(
	parameter fml_depth = 27
) (
	input sys_clk,
	input sys_rst,

	/* To/from control interface */
	input [1:0] field_filter,
	output reg in_frame,
	input [fml_depth-1-5:0] fml_adr_base,
	output start_of_frame,
	output reg next_burst,
	input last_burst,

	/* From video input module. */
	input v_stb,
	output reg v_ack,
	input v_field,
	input [31:0] v_rgb565,

	/* FML interface. fml_we=1 and fml_sel=ff are assumed. */
	output [fml_depth-1:0] fml_adr,
	output reg fml_stb,
	input fml_ack,
	output [63:0] fml_do
);

/* Data buffer */
reg data_en;
reg [2:0] v_bcount;
reg burst_7;
always @(posedge sys_clk) begin
	if(sys_rst)
		v_bcount <= 3'd0;
	else if(v_stb & v_ack & data_en) begin
		v_bcount <= v_bcount + 3'd1;
		burst_7 <= v_bcount == 3'd6;
	end
end

reg [1:0] f_bcount;

bt656cap_burstmem burstmem(
	.sys_clk(sys_clk),

	.we(v_stb & v_ack & data_en),
	.wa(v_bcount),
	.wd(v_rgb565),

	.ra(f_bcount),
	.rd(fml_do)
);

/* FML address generator */
reg [fml_depth-1-5:0] fml_adr_b;

always @(posedge sys_clk) begin
	if(start_of_frame)
		fml_adr_b <= fml_adr_base;
	else if(next_burst)
		fml_adr_b <= fml_adr_b + 1'd1;
end

assign fml_adr = {fml_adr_b, 5'd0};

/* Detect start of frames and filter fields */
reg previous_field;
always @(posedge sys_clk) begin
	if(v_stb & v_ack)
		previous_field <= v_field;
end

assign start_of_frame = (v_stb & v_ack) &
	((field_filter[0] & previous_field & ~v_field)
	|(field_filter[1] & ~previous_field & v_field));

/* Controller */
reg [2:0] state;
reg [2:0] next_state;

parameter WAIT_SOF = 3'd0;
parameter WAIT_EOB = 3'd1;
parameter TRANSFER1 = 3'd2;
parameter TRANSFER2 = 3'd3;
parameter TRANSFER3 = 3'd4;
parameter TRANSFER4 = 3'd6;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= WAIT_SOF;
	else
		state <= next_state;
end

always @(*) begin
	v_ack = 1'b0;
	fml_stb = 1'b0;
	in_frame = 1'b1;
	next_burst = 1'b0;

	data_en = 1'b0;

	f_bcount = 2'bx;

	next_state = state;

	case(state)
		WAIT_SOF: begin
			in_frame = 1'b0;
			v_ack = 1'b1;
			data_en = start_of_frame;
			if(start_of_frame)
				next_state = WAIT_EOB;
		end
		WAIT_EOB: begin
			v_ack = 1'b1;
			data_en = 1'b1;
			f_bcount = 2'd0;
			if(burst_7 & v_stb)
				next_state = TRANSFER1;
		end
		TRANSFER1: begin
			fml_stb = 1'b1;
			f_bcount = 2'd0;
			if(fml_ack) begin
				f_bcount = 2'd1;
				next_state = TRANSFER2;
			end
		end
		TRANSFER2: begin
			f_bcount = 2'd2;
			next_burst = 1'b1;
			next_state = TRANSFER3;
		end
		TRANSFER3: begin
			f_bcount = 2'd3;
			next_state = TRANSFER4;
		end
		TRANSFER4: begin
			if(last_burst)
				next_state = WAIT_SOF;
			else
				next_state = WAIT_EOB;
		end
	endcase

end

endmodule
