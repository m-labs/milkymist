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

module tmu2_fetchvertex(
	input sys_clk,
	input sys_rst,

	input start,
	output reg busy,

	output [31:0] wbm_adr_o,
	output [2:0] wbm_cti_o,
	output wbm_cyc_o,
	output reg wbm_stb_o,
	input wbm_ack_i,
	input [31:0] wbm_dat_i,

	input [6:0] vertex_hlast,
	input [6:0] vertex_vlast,

	input [28:0] vertex_adr,

	input signed [11:0] dst_hoffset,
	input signed [11:0] dst_voffset,
	input [10:0] dst_squarew,
	input [10:0] dst_squareh,

	output reg pipe_stb_o,
	input pipe_ack_i,

	/* Texture coordinates */
	output reg signed [17:0] ax,
	output reg signed [17:0] ay,
	output reg signed [17:0] bx,
	output reg signed [17:0] by,
	output reg signed [17:0] cx,
	output reg signed [17:0] cy,
	output reg signed [17:0] dx,
	output reg signed [17:0] dy,

	/* Upper-left corner of the destination rectangle */
	output reg signed [11:0] drx,
	output reg signed [11:0] dry
);

assign wbm_cti_o = 3'd0;
assign wbm_cyc_o = wbm_stb_o;

/*
 * A B
 * C D
 */

/* Fetch Engine */

/* control signals */
reg [28:0] fetch_base;
reg [1:0] fetch_target;
reg fetch_strobe;
reg fetch_done;
reg shift_points;
/* */

parameter TARGET_A = 2'd0;
parameter TARGET_B = 2'd1;
parameter TARGET_C = 2'd2;
parameter TARGET_D = 2'd3;

reg is_y;
assign wbm_adr_o = {fetch_base, is_y, 2'b00};

always @(posedge sys_clk) begin
	if(wbm_ack_i) begin
		if(is_y) begin
			case(fetch_target)
				TARGET_A: ay <= wbm_dat_i[17:0];
				TARGET_B: by <= wbm_dat_i[17:0];
				TARGET_C: cy <= wbm_dat_i[17:0];
				TARGET_D: dy <= wbm_dat_i[17:0];
			endcase
		end else begin
			case(fetch_target)
				TARGET_A: ax <= wbm_dat_i[17:0];
				TARGET_B: bx <= wbm_dat_i[17:0];
				TARGET_C: cx <= wbm_dat_i[17:0];
				TARGET_D: dx <= wbm_dat_i[17:0];
			endcase
		end
	end
	if(shift_points) begin
		/*
		 * A <- B
		 * C <- D
		 */
		ax <= bx;
		ay <= by;
		cx <= dx;
		cy <= dy;
	end
end

always @(posedge sys_clk) begin
	if(sys_rst) begin
		wbm_stb_o <= 1'b0;
		fetch_done <= 1'b0;
		is_y <= 1'b0;
	end else begin
		wbm_stb_o <= 1'b0;
		fetch_done <= 1'b0;
		if(fetch_strobe & ~fetch_done) begin
			wbm_stb_o <= 1'b1;
			if(wbm_ack_i) begin
				is_y <= ~is_y;
				if(is_y) begin
					fetch_done <= 1'b1;
					wbm_stb_o <= 1'b0;
				end
			end
		end
	end
end

/* Address & Destination coordinates generator */

/* control signals */
reg move_reset;
reg move_x_right;
reg move_x_startline;
reg move_y_down;
reg move_y_up;
/* */

reg [6:0] x;
reg [6:0] y;

always @(posedge sys_clk) begin
	if(move_reset) begin
		/* subtract the square dimensions,
		 * as we are at point D when sending the vertex down the pipeline
		 */
		drx = dst_hoffset - {1'b0, dst_squarew};
		dry = dst_voffset - {1'b0, dst_squareh};
		x = 7'd0;
		y = 7'd0;
	end else begin
		case({move_x_right, move_x_startline})
			2'b10: begin
				drx = drx + {1'b0, dst_squarew};
				x = x + 7'd1;
			end
			2'b01: begin
				drx = dst_hoffset - {1'b0, dst_squarew};
				x = 7'd0;
			end
			default:;
		endcase
		case({move_y_down, move_y_up})
			2'b10: begin
				dry = dry + {1'b0, dst_squareh};
				y = y + 7'd1;
			end
			2'b01: begin
				dry = dry - {1'b0, dst_squareh};
				y = y - 7'd1;
			end
			default:;
		endcase
	end
	fetch_base = vertex_adr + {y, x};
end

/* Controller */

reg [2:0] state;
reg [2:0] next_state;

parameter IDLE		= 3'd0;
parameter FETCH_A	= 3'd1;
parameter FETCH_B	= 3'd2;
parameter FETCH_C	= 3'd3;
parameter FETCH_D	= 3'd4;
parameter PIPEOUT	= 3'd5;
parameter NEXT_SQUARE	= 3'd6;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= IDLE;
	else
		state <= next_state;
end

wire last_col = x == vertex_hlast;
wire last_row = y == vertex_vlast;

always @(*) begin
	fetch_target = 2'bxx;
	fetch_strobe = 1'b0;
	shift_points = 1'b0;

	move_reset = 1'b0;
	move_x_right = 1'b0;
	move_x_startline = 1'b0;
	move_y_down = 1'b0;
	move_y_up = 1'b0;

	busy = 1'b1;

	pipe_stb_o = 1'b0;

	next_state = state;

	case(state)
		IDLE: begin
			busy = 1'b0;
			move_reset = 1'b1;
			if(start)
				next_state = FETCH_A;
		end
		
		FETCH_A: begin
			fetch_target = TARGET_A;
			fetch_strobe = 1'b1;
			if(fetch_done) begin
				move_y_down = 1'b1;
				next_state = FETCH_C;
			end
		end
		FETCH_C: begin
			fetch_target = TARGET_C;
			fetch_strobe = 1'b1;
			if(fetch_done) begin
				move_x_right = 1'b1;
				move_y_up = 1'b1;
				next_state = FETCH_B;
			end
		end
		FETCH_B: begin
			fetch_target = TARGET_B;
			fetch_strobe = 1'b1;
			if(fetch_done) begin
				move_y_down = 1'b1;
				next_state = FETCH_D;
			end
		end
		FETCH_D: begin
			fetch_target = TARGET_D;
			fetch_strobe = 1'b1;
			if(fetch_done)
				next_state = PIPEOUT;
		end

		PIPEOUT: begin
			pipe_stb_o = 1'b1;
			if(pipe_ack_i)
				next_state = NEXT_SQUARE;
		end
		NEXT_SQUARE: begin /* assumes we are on point D */
			if(last_col) begin
				if(last_row)
					next_state = IDLE;
				else begin
					move_x_startline = 1'b1;
					next_state = FETCH_A;
				end
			end else begin
				move_x_right = 1'b1;
				move_y_up = 1'b1;
				shift_points = 1'b1;
				next_state = FETCH_B;
			end
		end
	endcase
end

endmodule
