/*
 * Milkymist SoC
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

module pfpu_ctlif #(
	parameter csr_addr = 4'h0
) (
	input sys_clk,
	input sys_rst,
	
	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output [31:0] csr_do,
	
	output reg irq,
	
	output reg start,
	input busy,
	
	/* Address generator interface */
	output reg [28:0] dma_base,
	output reg [6:0] hmesh_last,
	output reg [6:0] vmesh_last,
	
	/* Register file interface */
	output [6:0] cr_addr,
	input [31:0] cr_di,
	output [31:0] cr_do,
	output cr_w_en,
	
	/* Program memory interface */
	output reg [1:0] cp_page,
	output [8:0] cp_offset,
	input [31:0] cp_di,
	output [31:0] cp_do,
	output cp_w_en,

	/* Diagnostic registers */
	input vnext,
	input err_collision,
	input err_stray,
	input [10:0] pc,

	input [31:0] wbm_adr_o,
	input wbm_ack_i
);

reg [31:0] last_dma;
always @(posedge sys_clk)
	if(wbm_ack_i)
		last_dma <= wbm_adr_o;

reg old_busy;
always @(posedge sys_clk) begin
	if(sys_rst)
		old_busy <= 1'b0;
	else
		old_busy <= busy;
end

reg [13:0] vertex_counter;
reg [10:0] collision_counter;
reg [10:0] stray_counter;

wire csr_selected = csr_a[13:10] == csr_addr;

reg [31:0] csr_do_r;
reg csr_do_cont;
reg csr_do_regf;
reg csr_do_prog;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		csr_do_r <= 32'd0;
		csr_do_cont <= 1'b0;
		csr_do_regf <= 1'b0;
		csr_do_prog <= 1'b0;
		irq <= 1'b0;
		start <= 1'b0;
		
		dma_base <= 29'd0;
		hmesh_last <= 7'd0;
		vmesh_last <= 7'd0;
		cp_page <= 2'd0;

		vertex_counter <= 14'd0;
		collision_counter <= 11'd0;
		stray_counter <= 11'd0;
	end else begin
		irq <= old_busy & ~busy;

		if(vnext) vertex_counter <= vertex_counter + 14'd1;
		if(err_collision) collision_counter <= collision_counter + 11'd1;
		if(err_stray) stray_counter <= stray_counter + 11'd1;

		csr_do_cont <= 1'b0;
		csr_do_prog <= 1'b0;
		csr_do_regf <= 1'b0;
		
		start <= 1'b0;

		/* Read control registers */
		case(csr_a[3:0])
			4'b0000: csr_do_r <= busy;

			4'b0001: csr_do_r <= {dma_base, 3'b000};
			4'b0010: csr_do_r <= hmesh_last;
			4'b0011: csr_do_r <= vmesh_last;

			4'b0100: csr_do_r <= cp_page;

			4'b0101: csr_do_r <= vertex_counter;
			4'b0110: csr_do_r <= collision_counter;
			4'b0111: csr_do_r <= stray_counter;
			4'b1000: csr_do_r <= last_dma;
			4'b1001: csr_do_r <= pc;

			default: csr_do_r <= 32'bx;
		endcase
		
		if(csr_selected) begin
			/* Generate enables for the one-hot mux on csr_do */
			csr_do_cont <= ~csr_a[8] & ~csr_a[9];
			csr_do_regf <= csr_a[8];
			csr_do_prog <= csr_a[9];
			
			/* Write control registers */
			if(
				csr_we		/* if this is a write cycle */
				& ~csr_a[8]	/* which is not for register file */
				& ~csr_a[9]	/* nor for program memory */
				)
			begin
				/* then it is for control registers */
				case(csr_a[2:0])
					3'b000: begin
						start <= csr_di[0];

						vertex_counter <= 14'd0;
						collision_counter <= 11'd0;
						stray_counter <= 11'd0;
					end
					3'b001: dma_base <= csr_di[31:3];
					3'b010: hmesh_last <= csr_di[6:0];
					3'b011: vmesh_last <= csr_di[6:0];
					3'b100: cp_page <= csr_di[1:0];
					default:;
				endcase
			end
		end
	end
end

/*
 * Program memory and register file have synchronous read,
 * so we must use some tricks to move the registers into them.
 */

assign csr_do =
	 ({32{csr_do_cont}} & csr_do_r)
	|({32{csr_do_prog}} & cp_di)
	|({32{csr_do_regf}} & cr_di);

assign cp_offset = csr_a[8:0];
assign cp_w_en = csr_selected & csr_a[9] & csr_we;
assign cp_do = csr_di;

assign cr_addr = csr_a[6:0];
assign cr_w_en = csr_selected & ~csr_a[9] & csr_a[8] & csr_we;
assign cr_do = csr_di;

endmodule
