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

module bt656cap_colorspace(
	input vid_clk,

	input stb_i,
	input field_i,
	input [31:0] ycc422,

	output reg stb_o,
	output reg field_o,
	output [31:0] rgb565
);

/* Datapath */
wire signed [7:0] cb = ycc422[31:24] - 8'd128;
wire signed [7:0] y0 = ycc422[23:16] - 8'd128;
wire signed [7:0] cr = ycc422[15: 8] - 8'd128;
wire signed [7:0] y1 = ycc422[ 7: 0] - 8'd128;

reg mult_sela;
reg [1:0] mult_selb;

wire signed [7:0] mult_opa = mult_sela ? cr : cb;
reg signed [9:0] mult_opb;
always @(*) begin
	case(mult_selb)
		2'd0: mult_opb = 10'd359; // 1.402
		2'd1: mult_opb = 10'd454; // 1.772
		2'd2: mult_opb = 10'd88;  // 0.344
		2'd3: mult_opb = 10'd183; // 0.714
	endcase
end

reg signed [17:0] mult_result;
wire signed [9:0] mult_result_t = mult_result[17:8];
always @(posedge vid_clk) mult_result <= mult_opa*mult_opb;

reg signed [9:0] int_r0;
reg signed [9:0] int_g0;
reg signed [9:0] int_b0;
reg signed [9:0] int_r1;
reg signed [9:0] int_g1;
reg signed [9:0] int_b1;

reg load_y;
reg add_r;
reg sub_g;
reg add_b;
always @(posedge vid_clk) begin
	if(load_y) begin
		int_r0 <= y0;
		int_g0 <= y0;
		int_b0 <= y0;
		int_r1 <= y1;
		int_g1 <= y1;
		int_b1 <= y1;
	end
	if(add_r) begin
		int_r0 <= int_r0 + mult_result_t;
		int_r1 <= int_r1 + mult_result_t;
	end
	if(sub_g) begin
		int_g0 <= int_g0 - mult_result_t;
		int_g1 <= int_g1 - mult_result_t;
	end
	if(add_b) begin
		int_b0 <= int_b0 + mult_result_t;
		int_b1 <= int_b1 + mult_result_t;
	end
end

/* Output generator */
reg fsm_stb;
reg fsm_field;
wire signed [9:0] fsm_r0 = int_r0;
wire signed [9:0] fsm_g0 = int_g0 - mult_result_t;
wire signed [9:0] fsm_b0 = int_b0;
wire signed [9:0] fsm_r1 = int_r1;
wire signed [9:0] fsm_g1 = int_g1 - mult_result_t;
wire signed [9:0] fsm_b1 = int_b1;
reg [7:0] out_r0;
reg [7:0] out_g0;
reg [7:0] out_b0;
reg [7:0] out_r1;
reg [7:0] out_g1;
reg [7:0] out_b1;
always @(posedge vid_clk) begin
	stb_o <= 1'b0;
	if(fsm_stb) begin
		stb_o <= 1'b1;
		field_o <= fsm_field;
		out_r0 <= (fsm_r0[7:0] | {8{fsm_r0[8]}}) & {8{~fsm_r0[9]}};
		out_g0 <= (fsm_g0[7:0] | {8{fsm_g0[8]}}) & {8{~fsm_g0[9]}};
		out_b0 <= (fsm_b0[7:0] | {8{fsm_b0[8]}}) & {8{~fsm_b0[9]}};
		out_r1 <= (fsm_r1[7:0] | {8{fsm_r1[8]}}) & {8{~fsm_r1[9]}};
		out_g1 <= (fsm_g1[7:0] | {8{fsm_g1[8]}}) & {8{~fsm_g1[9]}};
		out_b1 <= (fsm_b1[7:0] | {8{fsm_b1[8]}}) & {8{~fsm_b1[9]}};
	end
end

assign rgb565 = {out_r0[7:3], out_g0[7:2], out_b0[7:3],
	out_r1[7:3], out_g1[7:2], out_b1[7:3]};

/* Forward field */
always @(posedge vid_clk) begin
	if(stb_i)
		fsm_field <= field_i;
end

/* Controller */
reg [2:0] state;
reg [2:0] next_state;

parameter S1 = 3'd0;
parameter S2 = 3'd1;
parameter S3 = 3'd2;
parameter S4 = 3'd3;
parameter S5 = 3'd4;

initial state = S1;
always @(posedge vid_clk) begin
	state <= next_state;
	//$display("state: %d->%d (%d)", state, next_state, stb_i);
end

always @(*) begin
	mult_sela = 1'bx;
	mult_selb = 2'bx;
	
	load_y = 1'b0;
	add_r = 1'b0;
	sub_g = 1'b0;
	add_b = 1'b0;

	fsm_stb = 1'b0;

	next_state = state;

	case(state)
		S1: begin
			load_y = 1'b1;
			mult_sela = 1'b1; // 1.402*Cr
			mult_selb = 2'd0;
			if(stb_i)
				next_state = S2;
		end
		S2: begin
			add_r = 1'b1;
			mult_sela = 1'b0; // 1.772*Cb
			mult_selb = 2'd1;
			next_state = S3;
		end
		S3: begin
			add_b = 1'b1;
			mult_sela = 1'b0; // 0.344*Cb
			mult_selb = 2'd2;
			next_state = S4;
		end
		S4: begin
			sub_g = 1'b1;
			mult_sela = 1'b1; // 0.714*Cr
			mult_selb = 2'd3;
			next_state = S5;
		end
		S5: begin
			fsm_stb = 1'b1;
			load_y = 1'b1;
			mult_sela = 1'b1; // 1.402*Cr
			mult_selb = 2'd0;
			if(stb_i)
				next_state = S2;
			else
				next_state = S1;
		end
	endcase
end

endmodule
