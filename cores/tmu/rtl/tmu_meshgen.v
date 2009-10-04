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

module tmu_meshgen(
	input sys_clk,
	input sys_rst,
	
	output reg [31:0] wbm_adr_o,
	output [2:0] wbm_cti_o,
	output wbm_cyc_o,
	output reg wbm_stb_o,
	input wbm_ack_i,
	input [31:0] wbm_dat_i,
	
	input start,
	output reg busy,
	
	input [6:0] hmesh_last,
	input [6:0] vmesh_last,

	input [29:0] src_mesh, /* in 32-bit words */
	input [29:0] dst_mesh, /* in 32-bit words */

	output reg pipe_stb,
	input pipe_ack,
	output reg signed [11:0] A_S_X,
	output reg signed [11:0] A_S_Y,
	output reg signed [11:0] B_S_X,
	output reg signed [11:0] B_S_Y,
	output reg signed [11:0] C_S_X,
	output reg signed [11:0] C_S_Y,
	output reg signed [11:0] A_D_X,
	output reg signed [11:0] A_D_Y,
	output reg signed [11:0] B_D_X,
	output reg signed [11:0] B_D_Y,
	output reg signed [11:0] C_D_X,
	output reg signed [11:0] C_D_Y
);

/* Burst support for later */
assign wbm_cti_o = 3'b000;

assign wbm_cyc_o = wbm_stb_o;

/* DATAPATH: Logo-like graphics in Verilog. */

/* move turtle to the origin */
reg move_origin;
/* move turtle to the beginning of the line */
reg move_linestart;
/* move turtle to the right */
reg move_right;
/* move turtle down */
reg move_down;
/* move turtle diagonally to the left and down */
reg move_leftdown;
/* move turtle diagonally to the right and up */
reg move_rightup;

/* position of the turtle on the meshes */
reg [6:0] turtle_ix;
reg [6:0] turtle_iy;

/* Register the control signals as they tend to be in the critical
 * path because of the delay in the ack signal of the bus.
 */
reg move_origin_r;
reg move_linestart_r;
reg move_right_r;
reg move_down_r;
reg move_leftdown_r;
reg move_rightup_r;

always @(posedge sys_clk) begin
	move_origin_r <= move_origin;
	move_linestart_r <= move_linestart;
	move_right_r <= move_right;
	move_down_r <= move_down;
	move_leftdown_r <= move_leftdown;
	move_rightup_r <= move_rightup;
end

always @(posedge sys_clk) begin
	case({move_origin_r, move_linestart_r, move_right_r, move_down_r, move_leftdown_r, move_rightup_r})
		6'b100000: begin /* move_origin */
			turtle_ix <= 7'd0;
			turtle_iy <= 7'd0;
		end
		6'b010000: /* move_linestart */
			turtle_ix <= 7'd0;
		6'b001000: /* move_right */
			turtle_ix <= turtle_ix + 7'd1;
		6'b000100: /* move_down */
			turtle_iy <= turtle_iy + 7'd1;
		6'b000010: begin /* move_leftdown */
			turtle_ix <= turtle_ix - 7'd1;
			turtle_iy <= turtle_iy + 7'd1;
		end
		6'b000001: begin /* move_rightup */
			turtle_ix <= turtle_ix + 7'd1;
			turtle_iy <= turtle_iy - 7'd1;
		end
		default:;
	endcase
end

/* Detect mesh boundaries */
wire hlast = turtle_ix == hmesh_last;
wire vlast = turtle_iy == vmesh_last;

/* DATAPATH: registered computation of the WB mesh address */
wire [31:0] src_mesh32 = {src_mesh, 2'b00};
wire [31:0] dst_mesh32 = {dst_mesh, 2'b00};
reg on_dst;
reg next_dst;
always @(posedge sys_clk) begin
	wbm_adr_o <= (on_dst ? dst_mesh32 : src_mesh32) + {turtle_iy, turtle_ix, 2'b00};
	on_dst <= next_dst;
end

reg loadA;
reg loadB;
reg loadC;
always @(posedge sys_clk) begin
	if(loadA) begin
		if(on_dst) begin
			A_D_X = wbm_dat_i[11:0];
			A_D_Y = wbm_dat_i[27:16];
		end else begin
			A_S_X = wbm_dat_i[11:0];
			A_S_Y = wbm_dat_i[27:16];
		end
	end
	if(loadB) begin
		if(on_dst) begin
			B_D_X = wbm_dat_i[11:0];
			B_D_Y = wbm_dat_i[27:16];
		end else begin
			B_S_X = wbm_dat_i[11:0];
			B_S_Y = wbm_dat_i[27:16];
		end
	end
	if(loadC) begin
		if(on_dst) begin
			C_D_X = wbm_dat_i[11:0];
			C_D_Y = wbm_dat_i[27:16];
		end else begin
			C_S_X = wbm_dat_i[11:0];
			C_S_Y = wbm_dat_i[27:16];
		end
	end
end

/* THE FSM FROM HELL */

parameter IDLE			= 6'd0;

parameter LS_WAIT_AADR		= 6'd1;
parameter LS_WAIT2_AADR		= 6'd2;
parameter LS_LOAD_A		= 6'd3;
parameter LS_WAIT_BADR		= 6'd4;
parameter LS_WAIT2_BADR		= 6'd5;
parameter LS_LOAD_B		= 6'd6;
parameter LS_WAIT_CADR		= 6'd7;
parameter LS_WAIT2_CADR		= 6'd8;
parameter LS_LOAD_C		= 6'd9;

parameter IL1T_WAIT_BADR	= 6'd10;
parameter IL1T_WAIT2_BADR	= 6'd11;
parameter IL1T_LOAD_B		= 6'd12;
parameter IL1T_PIPEOUT		= 6'd13;

parameter IL1B_WAIT_AADR	= 6'd14;
parameter IL1B_WAIT2_AADR	= 6'd15;
parameter IL1B_LOAD_A		= 6'd16;
parameter IL1B_PIPEOUT		= 6'd17;

parameter IL2T_WAIT_CADR	= 6'd18;
parameter IL2T_WAIT2_CADR	= 6'd19;
parameter IL2T_LOAD_C		= 6'd20;
parameter IL2T_PIPEOUT		= 6'd21;

parameter IL2B_WAIT_BADR	= 6'd22;
parameter IL2B_WAIT2_BADR	= 6'd23;
parameter IL2B_LOAD_B		= 6'd24;
parameter IL2B_PIPEOUT		= 6'd25;

parameter IL3T_WAIT_AADR	= 6'd26;
parameter IL3T_WAIT2_AADR	= 6'd27;
parameter IL3T_LOAD_A		= 6'd28;
parameter IL3T_PIPEOUT		= 6'd29;

parameter IL3B_WAIT_CADR	= 6'd30;
parameter IL3B_WAIT2_CADR	= 6'd31;
parameter IL3B_LOAD_C		= 6'd32;
parameter IL3B_PIPEOUT		= 6'd33;

reg [5:0] state;
reg [5:0] next_state;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= IDLE;
	else
		state <= next_state;
end

always @(*) begin
	next_state = state;
	
	move_origin = 1'b0;
	move_linestart = 1'b0;
	move_right = 1'b0;
	move_down = 1'b0;
	move_leftdown = 1'b0;
	move_rightup = 1'b0;

	next_dst = on_dst;

	loadA = 1'b0;
	loadB = 1'b0;
	loadC = 1'b0;
	
	wbm_stb_o = 1'b0;
	busy = 1'b1;
	
	pipe_stb = 1'b0;
	
	case(state)
		IDLE: begin
			busy = 1'b0;
			move_origin = 1'b1;
			next_dst = 1'b0;
			if(start)
				next_state = LS_WAIT_AADR;
		end
		
		/* Line Start */
		/* wait for the registered computation of WB address to complete */
		LS_WAIT_AADR: next_state = LS_WAIT2_AADR;
		LS_WAIT2_AADR: next_state = LS_LOAD_A;
		LS_LOAD_A: begin
			wbm_stb_o = 1'b1;
			loadA = 1'b1;
			if(wbm_ack_i) begin
				if(on_dst) begin
					next_dst = 1'b0;
					move_right = 1'b1;
					next_state = LS_WAIT_BADR;
				end else begin
					next_dst = 1'b1;
					next_state = LS_WAIT2_AADR;
				end
			end
		end
		LS_WAIT_BADR: next_state = LS_WAIT2_BADR;
		LS_WAIT2_BADR: next_state = LS_LOAD_B;
		LS_LOAD_B: begin
			wbm_stb_o = 1'b1;
			loadB = 1'b1;
			if(wbm_ack_i) begin
				if(on_dst) begin
					next_dst = 1'b0;
					move_leftdown = 1'b1;
					next_state = LS_WAIT_CADR;
				end else begin
					next_dst = 1'b1;
					next_state = LS_WAIT2_BADR;
				end
			end
		end
		LS_WAIT_CADR: next_state = LS_WAIT2_CADR;
		LS_WAIT2_CADR: next_state = LS_LOAD_C;
		LS_LOAD_C: begin
			wbm_stb_o = 1'b1;
			loadC = 1'b1;
			if(wbm_ack_i) begin
				if(on_dst) begin
					next_dst = 1'b0;
					next_state = IL1T_PIPEOUT;
				end else begin
					next_dst = 1'b1;
					next_state = LS_WAIT2_CADR;
				end
			end
		end
		
		/* In Line */
		/* Configuration 1, Top triangle */
		
		/* Enter this state by moving RIGHT-UP to fetch B,
		 * after checking for end-of-line and end-of-picture
		 */
		IL1T_WAIT_BADR: next_state = IL1T_WAIT2_BADR;
		IL1T_WAIT2_BADR: next_state = IL1T_LOAD_B;
		IL1T_LOAD_B: begin
			wbm_stb_o = 1'b1;
			loadB = 1'b1;
			if(wbm_ack_i) begin
				if(on_dst) begin
					next_dst = 1'b0;
					move_leftdown = 1'b1; /* Go to C not to break the cycle */
					next_state = IL1T_PIPEOUT;
				end else begin
					next_dst = 1'b1;
					next_state = IL1T_WAIT2_BADR;
				end
			end
		end
		IL1T_PIPEOUT: begin
			pipe_stb = 1'b1;
			if(pipe_ack) begin
				move_right = 1'b1;
				next_state = IL1B_WAIT_AADR;
			end
		end
		
		/* Configuration 1, Bottom triangle */
		
		/* Enter this state by moving RIGHT to fetch A */
		IL1B_WAIT_AADR: next_state = IL1B_WAIT2_AADR;
		IL1B_WAIT2_AADR: next_state = IL1B_LOAD_A;
		IL1B_LOAD_A: begin
			wbm_stb_o = 1'b1;
			loadA = 1'b1;
			if(wbm_ack_i) begin
				if(on_dst) begin
					next_dst = 1'b0;
					next_state = IL1B_PIPEOUT;
				end else begin
					next_dst = 1'b1;
					next_state = IL1B_WAIT2_AADR;
				end
			end
		end
		IL1B_PIPEOUT: begin
			pipe_stb = 1'b1;
			if(pipe_ack) begin
				if(hlast) begin
					move_linestart = 1'b1;
					if(vlast)
						next_state = IDLE;
					else
						next_state = LS_WAIT_AADR;
				end else begin
					move_rightup = 1'b1;
					next_state = IL2T_WAIT_CADR;
				end
			end
		end
		
		/* Configuration 2, Top triangle */
		
		/* Enter this state by moving RIGHT-UP to fetch C */
		IL2T_WAIT_CADR: next_state = IL2T_WAIT2_CADR;
		IL2T_WAIT2_CADR: next_state = IL2T_LOAD_C;
		IL2T_LOAD_C: begin
			wbm_stb_o = 1'b1;
			loadC = 1'b1;
			if(wbm_ack_i) begin
				if(on_dst) begin
					next_dst = 1'b0;
					next_state = IL2T_PIPEOUT;
				end else begin
					next_dst = 1'b1;
					next_state = IL2T_WAIT2_CADR;
				end
			end
		end
		IL2T_PIPEOUT: begin
			pipe_stb = 1'b1;
			if(pipe_ack) begin
				move_down = 1'b1;
				next_state = IL2B_WAIT_BADR;
			end
		end
		
		/* Configuration 2, Bottom triangle */
		
		/* Enter this state by moving DOWN to fetch B */
		IL2B_WAIT_BADR: next_state = IL2B_WAIT2_BADR;
		IL2B_WAIT2_BADR: next_state = IL2B_LOAD_B;
		IL2B_LOAD_B: begin
			wbm_stb_o = 1'b1;
			loadB = 1'b1;
			if(wbm_ack_i) begin
				if(on_dst) begin
					next_dst = 1'b0;
					next_state = IL2B_PIPEOUT;
				end else begin
					next_dst = 1'b1;
					next_state = IL2B_WAIT2_BADR;
				end
			end
		end
		IL2B_PIPEOUT: begin
			pipe_stb = 1'b1;
			if(pipe_ack) begin
				if(hlast) begin
					move_linestart = 1'b1;
					if(vlast)
						next_state = IDLE;
					else
						next_state = LS_WAIT_AADR;
				end else begin
					move_rightup = 1'b1;
					next_state = IL3T_WAIT_AADR;
				end
			end
		end
		
		/* Configuration 3, Top triangle */
		
		/* Enter this state by moving RIGHT UP to fetch A */
		IL3T_WAIT_AADR: next_state = IL3T_WAIT2_AADR;
		IL3T_WAIT2_AADR: next_state = IL3T_LOAD_A;
		IL3T_LOAD_A: begin
			wbm_stb_o = 1'b1;
			loadA = 1'b1;
			if(wbm_ack_i) begin
				if(on_dst) begin
					next_dst = 1'b0;
					next_state = IL3T_PIPEOUT;
				end else begin
					next_dst = 1'b1;
					next_state = IL3T_WAIT2_AADR;
				end
			end
		end
		IL3T_PIPEOUT: begin
			pipe_stb = 1'b1;
			if(pipe_ack) begin
				move_down = 1'b1;
				next_state = IL3B_WAIT_CADR;
			end
		end
		
		/* Configuration 3, Bottom triangle */
		
		/* Enter this state by moving DOWN to fetch C */
		IL3B_WAIT_CADR: next_state = IL3B_WAIT2_CADR;
		IL3B_WAIT2_CADR: next_state = IL3B_LOAD_C;
		IL3B_LOAD_C: begin
			wbm_stb_o = 1'b1;
			loadC = 1'b1;
			if(wbm_ack_i) begin
				if(on_dst) begin
					next_dst = 1'b0;
					next_state = IL3B_PIPEOUT;
				end else begin
					next_dst = 1'b1;
					next_state = IL3B_WAIT2_CADR;
				end
			end
		end
		IL3B_PIPEOUT: begin
			pipe_stb = 1'b1;
			if(pipe_ack) begin
				if(hlast) begin
					move_linestart = 1'b1;
					if(vlast)
						next_state = IDLE;
					else
						next_state = LS_WAIT_AADR;
				end else begin
					move_rightup = 1'b1;
					next_state = IL1T_WAIT_BADR;
				end
			end
		end
	endcase
end

endmodule
