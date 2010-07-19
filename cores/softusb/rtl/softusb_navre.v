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
	parameter pmem_width = 9,
	parameter dmem_width = 9
) (
	input sys_clk,
	input sys_rst,

	output reg pmem_ce,
	output [pmem_width-1:0] pmem_a,
	input [15:0] pmem_d,

	output reg dmem_we,
	output reg [dmem_width-1:0] dmem_a,
	input [7:0] dmem_di,
	output reg [7:0] dmem_do,

	output reg io_re,
	output reg io_we,
	output [5:0] io_a,
	output [7:0] io_do,
	input [7:0] io_di
);

/* Register file */
reg [pmem_width-1:0] PC;
reg [7:0] GPR[0:31];
reg [15:0] pZ;
reg T, H, S, V, N, Z, C;

/* Stack */
reg io_use_stack;
reg [7:0] io_sp;
reg [15:0] SP;
reg push;
reg pop;
always @(posedge sys_clk) begin
	if(sys_rst) begin
		io_use_stack <= 1'b0;
		io_sp <= 8'd0;
		SP <= 16'd0;
	end else begin
		io_use_stack <= 1'b0;
		io_sp <= io_a[0] ? SP[7:0] : SP[15:8];
		if((io_a == 6'b111101) | (io_a == 6'b111110)) begin
			io_use_stack <= 1'b1;
			if(io_we) begin
				if(io_a[0])
					SP[7:0] <= io_do;
				else
					SP[15:8] <= io_do;
			end
		end
		if(push)
			SP <= SP - 16'd1;
		if(pop)
			SP <= SP + 16'd1;
	end
end

/* Register operations */
wire immediate = (pmem_d[14]
	| (pmem_d[15:12] == 4'b0011))		/* CPI */
	& (pmem_d[15:10] != 6'b111111);		/* SBRC - SBRS */
reg lpm_en;
wire [4:0] Rd = lpm_en ? 5'd0 : {immediate | pmem_d[8], pmem_d[7:4]};
wire [4:0] Rr = {pmem_d[9], pmem_d[3:0]};
wire [7:0] K = {pmem_d[11:8], pmem_d[3:0]};
wire [2:0] b = pmem_d[2:0];
wire signed [11:0] Kl = pmem_d[11:0];
wire signed [6:0] Ks = pmem_d[9:3];

wire [7:0] GPR_Rd = GPR[Rd];
wire [7:0] GPR_Rr = GPR[Rr];
wire GPR_Rd_b = GPR_Rd[b];

reg [2:0] pc_sel;

parameter PC_SEL_NOP		= 3'd0;
parameter PC_SEL_INC		= 3'd1;
parameter PC_SEL_KL		= 3'd2;
parameter PC_SEL_KS		= 3'd3;
parameter PC_SEL_DMEML		= 3'd4;
parameter PC_SEL_DMEMH		= 3'd6;
parameter PC_SEL_DEC		= 3'd7;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		PC <= 0;
	end else begin
		case(pc_sel)
			PC_SEL_NOP:;
			PC_SEL_INC: PC <= PC + 1;
			PC_SEL_KL: PC <= PC + Kl;
			PC_SEL_KS: PC <= PC + Ks;
			PC_SEL_DMEML: PC[7:0] <= dmem_di;
			PC_SEL_DMEMH: PC[pmem_width-1:8] <= dmem_di;
			PC_SEL_DEC: PC <= PC - 1;
		endcase
	end
end
reg pmem_selz;
assign pmem_a = sys_rst ? 0 : (pmem_selz ? pZ : PC + 1);

reg normal_en;

// synthesis translate_off
integer i_rst_regf;
// synthesis translate_on
reg [7:0] R;
reg writeback;
reg update_nzv;
always @(posedge sys_clk) begin
	R = 8'hxx;
	writeback = 1'b0;
	update_nzv = 1'b0;
	if(sys_rst) begin
		/*
		 * Not resetting the register file enables the use of more efficient
		 * distributed block RAM.
		 */
		// synthesis translate_off
		for(i_rst_regf=0;i_rst_regf<31;i_rst_regf=i_rst_regf+1)
			GPR[i_rst_regf] = 8'd0;
		pZ = 16'd0;
		// synthesis translate_on
		T = 1'b0;
		H = 1'b0;
		S = 1'b0;
		V = 1'b0;
		N = 1'b0;
		Z = 1'b0;
		C = 1'b0;
	end else begin
		if(normal_en) begin
			writeback = 1'b1;
			update_nzv = 1'b1;
			casex(pmem_d[15:10])
				6'b000x11: begin
					/* ADD - ADC */
					{C, R} = GPR_Rd + GPR_Rr + (pmem_d[12] & C);
					H = (GPR_Rd[3] & GPR_Rr[3])|(GPR_Rr[3] & ~R[3])|(~R[3] & GPR_Rd[3]);
					V = (GPR_Rd[7] & GPR_Rr[7] & ~R[7])|(~GPR_Rd[7] & ~GPR_Rr[7] & R[7]);
				end
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
					casex(Rr)
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
							R = GPR_Rd - 8'd1;
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
				/* LSL is replaced with ADD */
				/* ROL is replaced with ADC */
				6'b111110: begin
					if(pmem_d[9]) begin
						/* BST */
						T = GPR_Rd_b;
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
				 * are replaced with BSET and BCLR */
				6'b000000: begin
					/* NOP */
					update_nzv = 1'b0;
					writeback = 1'b0;
				end
				/* SLEEP is not implemented */
				/* WDR is not implemented */
				6'b100100,
				6'b100000: begin
					/* LD - POP (run from state WRITEBACK) */
					R = dmem_di;
					update_nzv = 1'b0;
				end
				6'b10110x: begin
					/* IN (run from state WRITEBACK) */
					R = io_use_stack ? io_sp : io_di;
					update_nzv = 1'b0;
				end
			endcase
		end
		if(lpm_en) begin
			R = dmem_di;
			writeback = 1'b1;
		end
		if(update_nzv) begin
				N = R[7];
				S = N ^ V;
				Z = R == 8'h00;
		end
		if(writeback) begin
			// synthesis translate_off
			//$display("REG WRITE: %d < %d", Rd, R);
			// synthesis translate_on
			case(Rd)
				5'd30: pZ[7:0] = R;
				5'd31: pZ[15:8] = R;
			endcase
			GPR[Rd] = R;
		end
	end
end

/* I/O port */
assign io_a = {pmem_d[10:9], pmem_d[3:0]};
assign io_do = GPR_Rd;

/* Data memory */
reg [1:0] dmem_sel;

parameter DMEM_SEL_UNDEFINED	= 2'bxx;
parameter DMEM_SEL_Z		= 2'd0;
parameter DMEM_SEL_SP_R		= 2'd1;
parameter DMEM_SEL_SP_PCL	= 2'd2;
parameter DMEM_SEL_SP_PCH	= 2'd3;

always @(*) begin
	case(dmem_sel)
		DMEM_SEL_Z: dmem_a = pZ;
		DMEM_SEL_SP_R,
		DMEM_SEL_SP_PCL,
		DMEM_SEL_SP_PCH: dmem_a = SP + pop;
		default: dmem_a = {dmem_width{1'bx}};
	endcase
end

wire [pmem_width-1:0] PC_inc = PC + 1;
always @(*) begin
	case(dmem_sel)
		DMEM_SEL_Z,
		DMEM_SEL_SP_R: dmem_do = GPR_Rd;
		DMEM_SEL_SP_PCL: dmem_do = PC_inc[7:0];
		DMEM_SEL_SP_PCH: dmem_do = PC_inc[pmem_width-1:8];
		default: dmem_do = 8'hxx;
	endcase
end

/* Multi-cycle operation sequencer */

wire reg_equal = GPR_Rd == GPR_Rr;

reg sreg_read;
always @(*) begin
	case(b)
		3'd0: sreg_read = C;
		3'd1: sreg_read = Z;
		3'd2: sreg_read = N;
		3'd3: sreg_read = V;
		3'd4: sreg_read = S;
		3'd5: sreg_read = H;
		3'd6: sreg_read = T;
		3'd7: sreg_read = 1'b0;
	endcase
end

reg [3:0] state;
reg [3:0] next_state;

parameter NORMAL	= 4'd0;
parameter RCALL		= 4'd1;
parameter STALL		= 4'd2;
parameter RET1		= 4'd3;
parameter RET2		= 4'd4;
parameter RET3		= 4'd5;
parameter LPM		= 4'd6;
parameter WRITEBACK	= 4'd7;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= NORMAL;
	else
		state <= next_state;
end

always @(*) begin
	next_state = state;

	pmem_ce = sys_rst;

	pc_sel = PC_SEL_NOP;
	normal_en = 1'b0;
	lpm_en = 1'b0;

	io_re = 1'b0;
	io_we = 1'b0;

	dmem_we = 1'b0;
	dmem_sel = DMEM_SEL_UNDEFINED;

	push = 1'b0;
	pop = 1'b0;

	pmem_selz = 1'b0;
	
	case(state)
		NORMAL: begin
			casex(pmem_d[15:10])
				6'b1100xx: begin
					/* RJMP */
					pc_sel = PC_SEL_KL;
					next_state = STALL;
				end
				6'b1101xx: begin
					/* RCALL */
					/* TODO: in which order should we push the bytes? */
					dmem_sel = DMEM_SEL_SP_PCL;
					dmem_we = 1'b1;
					push = 1'b1;
					next_state = RCALL;
				end
				6'b000100: begin
					/* CPSE */
					pc_sel = PC_SEL_INC;
					pmem_ce = 1'b1;
					if(reg_equal)
						next_state = STALL;
				end
				6'b111111: begin
					/* SBRC - SBRS */
					pc_sel = PC_SEL_INC;
					pmem_ce = 1'b1;
					if(GPR_Rd_b == pmem_d[9])
						next_state = STALL;
				end
				/* SBIC, SBIS, SBI, CBI are not implemented */
				6'b11110x: begin
					/* BRBS - BRBC */
					pmem_ce = 1'b1;
					if(sreg_read ^ pmem_d[10]) begin
						pc_sel = PC_SEL_KS;
						next_state = STALL;
					end else
						pc_sel = PC_SEL_INC;
				end
				/* BREQ, BRNE, BRCS, BRCC, BRSH, BRLO, BRMI, BRPL, BRGE, BRLT,
				 * BRHS, BRHC, BRTS, BRTC, BRVS, BRVC, BRIE, BRID are replaced
				 * with BRBS/BRBC */
				6'b100000: begin
					dmem_sel = DMEM_SEL_Z;
					if(pmem_d[9]) begin
						/* ST */
						pc_sel = PC_SEL_INC;
						pmem_ce = 1'b1;
						dmem_we = 1'b1;
					end else begin
						/* LD */
						next_state = WRITEBACK;
					end
				end
				6'b10110x: begin
					/* IN */
					io_re = 1'b1;
					next_state = WRITEBACK;
				end
				6'b10111x: begin
					/* OUT */
					io_we = 1'b1;
					pc_sel = PC_SEL_INC;
					pmem_ce = 1'b1;
				end
				6'b100100: begin
					if(pmem_d[9]) begin
						/* PUSH */
						push = 1'b1;
						dmem_sel = DMEM_SEL_SP_R;
						dmem_we = 1'b1;
						pc_sel = PC_SEL_INC;
						pmem_ce = 1'b1;
					end else begin
						/* POP */
						pop = 1'b1;
						dmem_sel = DMEM_SEL_SP_R;
						next_state = WRITEBACK;
					end
				end
				/* TODO: ADIW, SBIW, IJMP, ICALL, LDS, STS and fancy addressing modes (STD/LDD) */
				default: begin
					if((pmem_d[15:5] == 11'b1001_0101_000) & (pmem_d[3:0] == 4'b1000)) begin
						/* RET - RETI (treated as RET) */
						/* TODO: in which order should we pop the bytes? */
						dmem_sel = DMEM_SEL_SP_PCH;
						pop = 1'b1;
						next_state = RET1;
					end else if(pmem_d == 16'b1001_0101_1100_1000) begin
						/* LPM */
						pmem_selz = 1'b1;
						pmem_ce = 1'b1;
						next_state = LPM;
					end else begin
						pc_sel = PC_SEL_INC;
						normal_en = 1'b1;
						pmem_ce = 1'b1;
					end
				end
			endcase
		end
		RCALL: begin
			dmem_sel = DMEM_SEL_SP_PCH;
			dmem_we = 1'b1;
			push = 1'b1;
			pc_sel = PC_SEL_KL;
			next_state = STALL;
		end
		RET1: begin
			pc_sel = PC_SEL_DMEMH;
			dmem_sel = DMEM_SEL_SP_PCL;
			pop = 1'b1;
			next_state = RET2;
		end
		RET2: begin
			pc_sel = PC_SEL_DMEML;
			next_state = RET3;
		end
		RET3: begin
			pc_sel = PC_SEL_DEC;
			next_state = STALL;
		end
		LPM: begin
			lpm_en = 1'b1;
			pc_sel = PC_SEL_INC;
			pmem_ce = 1'b1;
			next_state = NORMAL;
		end
		STALL: begin
			pc_sel = PC_SEL_INC;
			pmem_ce = 1'b1;
			next_state = NORMAL;
		end
		WRITEBACK: begin
			pmem_ce = 1'b1;
			pc_sel = PC_SEL_INC;
			normal_en = 1'b1;
			next_state = NORMAL;
		end
	endcase
end

endmodule
