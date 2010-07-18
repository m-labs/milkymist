/*
 * Milkymist VJ SoC
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

module softusb_navre #(
	parameter pmem_width = 8
) (
	input sys_clk,
	input sys_rst,

	output pmem_ce,
	output [pmem_width-1:0] pmem_a,
	input [15:0] pmem_d,

	output io_we,
	output [5:0] io_a,
	output [7:0] io_do,
	input [7:0] io_di
);

/* Register file */
reg [pmem_width-1:0] PC;
reg [7:0] GPR[0:31];
reg T, H, S, V, N, Z, C;

/* Register operations */
reg PC_inc_en;
wire [pmem_width-1:0] PC_inc = PC + 1;
always @(posedge sys_clk) begin
	if(sys_rst) begin
		PC <= 0;
	end else begin
		if(PC_inc_en)
			PC <= PC_inc;
	end
end
assign pmem_a = PC_inc;
assign pmem_ce = PC_inc_en;

wire immediate = pmem_d[14];
wire [4:0] Rd = {immediate | pmem_d[8]}, pmem_d[7:4];
wire [4:0] Rr = {pmem_d[9], pmem_d[3:0]};
wire [7:0] K = {pmem_d[11:8], pmem_d[3:0]};
wire [2:0] b = pmem_d[2:0];

wire [7:0] GPR_Rd = GPR[Rd];
wire [7:0] GPR_Rr = GPR[Rr];

reg normal_en;

integer i_rst_regf;
reg [7:0] R;
reg writeback;
reg update_nzv;
always @(posedge sys_clk) begin
	R = 8'hxx;
	writeback = 1'b1;
	update_nzv = 1'b1;
	if(sys_rst) begin
		for(i_rst_regf=0;i_rst_regf<32;i_rst_regf=i_rst_regf+1)
			GPR[i_rst_regf] = 8'd0;
		T = 1'b0;
		H = 1'b0;
		S = 1'b0;
		V = 1'b0;
		N = 1'b0;
		Z = 1'b0;
		C = 1'b0;
	end else begin
		if(normal_en) begin
			casex(pmem_d[15:10])
				6'b000x11: begin
					/* ADD - ADC */
					{C, R} = GPR_Rd + GPR_Rr + (pmem_d[12] & C);
					H = (GPR_Rd[3] & GPR_Rr[3])|(GPR_Rr[3] & ~R[3])|(~R[3] & GPR_Rd[3]);
					V = (GPR_Rd[7] & GPR_Rr[7] & ~R[7])|(~GPR_Rd[7] & ~GPR_Rr[7] & R[7]);
				6'b000x10, /* subtract */
				6'b000x01: /* compare  */ begin
					/* SUB - SBC / CP - CPC */
					{C, R} = GPR_Rd - GPR_Rr - (~pmem_d[12] & C);
					H = (~GPR_Rd[3] & GPR_Rr[3])|(GPR_Rr[3] & R[3])|(R[3] & ~GPR_Rd[3]);
					V = (GPR_Rd[7] & ~GPR_Rr[7] & ~R[7])|(~GPR_Rd[7] & GPR_Rr[7] & R[7]);
					writeback = pmem_d[11];
				end
				6'b010xxx, /* subtract */
				6'b0011xx: /* compare  */ begin
					/* SUBI - SBCI / CPI */
					{C, R} = GPR_Rd - K - (~pmem_d[12] & C);
					H = (~GPR_Rd[3] & K[3])|(K[3] & R[3])|(R[3] & ~GPR_Rd[3]);
					V = (GPR_Rd[7] & ~K[7] & ~R[7])|(~GPR_Rd[7] & K[7] & R[7]);
					writeback = pmem_d[14];
				end
				6'b001000: begin
					/* AND */
					R = GPR_Rd & GPR_Rr;
					V = 1'b0;
				end
				6'b0111xx: begin
					/* ANDI */
					R = GPR_Rd & K;
					V = 1'b0;
				end
				6'b001010: begin
					/* OR */
					R = GPR_Rd | GPR_Rr;
					V = 1'b0;
				end
				6'b0110xx: begin
					/* ORI */
					R = GPR_Rd | K;
					V = 1'b0;
				end
				6'b001001: begin
					/* EOR */
					R = GPR_Rd ^ GPR_Rr;
					V = 1'b0;
				end
				6'b100101: begin
					case(Rr)
						5'b00000: begin
							/* COM */
							R = ~GPR_Rd;
							V = 1'b0;
							C = 1'b1;
						end
						5'b00001: begin
							/* NEG */
							{C, R} = 8'h00 - GPR_Rd;
							H = R[3] | GPR_Rd[3];
							V = R == 8'h80;
						end
						5'b00011: begin
							/* INC */
							R = GPR_Rd + 8'd1;
							V = R == 8'h80;
						end
						5'b01010: begin
							/* DEC */
							R = GPR_Rd + 8'd1;
							V = R == 8'h7f;
						end
						5'b0011x: begin
							/* LSR - ROR */
							R = {pmem_d[10] & C, GPR_Rd[7:1]};
							C = GPR_Rd[0];
							V = R[7] ^ GPR_Rd[0];
						end
						5'b00101: begin
							/* ASR */
							R = {GPR_Rd[7], GPR_Rd[7:1]};
							C = GPR_Rd[0];
							V = R[7] ^ GPR_Rd[0];
						end
						5'b00010: begin
							/* SWAP */
							R = {GPR_Rd[3:0], GPR_Rd[7:4]};
							update_nzv = 1'b0;
						end
						5'b01000: begin
							/* BSET - BCLR */
							case(pmem_d[7:4])
								4'b0000: C = 1'b1;
								4'b0001: Z = 1'b1;
								4'b0010: N = 1'b1;
								4'b0011: V = 1'b1;
								4'b0100: S = 1'b1;
								4'b0101: H = 1'b1;
								4'b0110: T = 1'b1;
								4'b1000: C = 1'b0;
								4'b1001: Z = 1'b0;
								4'b1010: N = 1'b0;
								4'b1011: V = 1'b0;
								4'b1100: S = 1'b0;
								4'b1101: H = 1'b0;
								4'b1110: T = 1'b0;
							endcase
							update_nzv = 1'b0;
							writeback = 1'b0;
						end
					endcase
				end
				/* SBR and CBR are replaced with ORI and ANDI */
				/* TST is replaced with AND */
				/* CLR and SER are replaced with EOR and LDI */
				6'b001011: begin
					/* MOV */
					R = GPR_Rr;
					update_nzv = 1'b0;
				end
				6'b1110xx: begin
					/* LDI */
					R = K;
					update_nzv = 1'b0;
				end
				/* LSL is implemented with ADD */
				/* ROL is implemented with ADC */
				6'b111110: begin
					if(pmem_d[9]) begin
						/* BST */
						T = GPR_Rd[b];
						writeback = 1'b0;
					end else begin
						/* BLD */
						case(b)
							3'd0: R = {GPR_Rd[7:1], T};
							3'd1: R = {GPR_Rd[7:2], T, GPR_Rd[0]};
							3'd2: R = {GPR_Rd[7:3], T, GPR_Rd[1:0]};
							3'd3: R = {GPR_Rd[7:4], T, GPR_Rd[2:0]};
							3'd4: R = {GPR_Rd[7:5], T, GPR_Rd[3:0]};
							3'd5: R = {GPR_Rd[7:6], T, GPR_Rd[4:0]};
							3'd6: R = {GPR_Rd[7], T, GPR_Rd[5:0]};
							3'd7: R = {T, GPR_Rd[6:0]};
						endcase
					end
					update_nzv = 1'b0;
				end
				/* SEC, CLC, SEN, CLN, SEZ, CLZ, SEI, CLI, SES, CLS, SEV, CLV, SET, CLT, SEH, CLH
				 * are implemented with BSET and BCLR */
				6'b000000: begin
					/* NOP */
					update_nzv = 1'b0;
					writeback = 1'b0;
				end
				/* SLEEP is not implemented */
				/* WDR is not implemented */
			endcase
			if(update_nzv) begin
				N = R[7];
				S = N ^ V;
				Z = R == 8'h00;
			end
			if(writeback)
				GPR[Rd] = R;
		end
	end
end

/* Multi-cycle operation sequencer */

always @(*) begin
	next_state = state;
	
	PC_inc_en = 1'b0;
	normal_en = 1'b0;
	
	case(state)
		NORMAL: begin
			PC_inc_en = 1'b1;
			normal_en = 1'b1;
		end
	endcase
end


endmodule
