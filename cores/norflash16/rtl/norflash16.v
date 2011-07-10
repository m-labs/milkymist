/*
 * Milkymist SoC
 * Copyright (C) 2007, 2008, 2009, 2010 Sebastien Bourdeauducq
 * Copyright (C) 2010 Michael Walle
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

module norflash16 #(
	parameter adr_width = 22,
	parameter rd_timing = 4'd12,
	parameter wr_timing = 4'd6
) (
	input sys_clk,
	input sys_rst,

	input [31:0] wb_adr_i,
	output reg [31:0] wb_dat_o,
	input [31:0] wb_dat_i,
	input [3:0] wb_sel_i,
	input wb_stb_i,
	input wb_cyc_i,
	output reg wb_ack_o,
	input wb_we_i,

	output [adr_width-1:0] flash_adr,
	inout [15:0] flash_d,
	output reg flash_oe_n,
	output reg flash_we_n
);

reg [adr_width-1:0] flash_adr_r;
reg [15:0] flash_do;
reg lsb;

assign two_cycle_transfer = (wb_sel_i == 4'b1111);
assign flash_adr = {flash_adr_r[adr_width-1:1], (two_cycle_transfer) ? lsb : flash_adr_r[0]};
assign flash_d = flash_oe_n ? flash_do : 16'bz;

reg load;
reg store;

always @(posedge sys_clk) begin
	flash_oe_n <= 1'b1;
	flash_we_n <= 1'b1;

	/* Use IOB registers to prevent glitches on address lines */
	/* register only when needed to reduce EMI */
	if(wb_cyc_i & wb_stb_i) begin
		flash_adr_r <= wb_adr_i[adr_width:1];
		if(wb_we_i)
			case(wb_sel_i)
				4'b0011: flash_do <= wb_dat_i[15:0];
				4'b1100: flash_do <= wb_dat_i[31:16];
				default: flash_do <= 16'hxxxx;
			endcase
		else
			flash_oe_n <= 1'b0;
	end

	if(load) begin
		casex({wb_sel_i, lsb})
			5'b0001x: wb_dat_o <= {4{flash_d[7:0]}};
			5'b0010x: wb_dat_o <= {4{flash_d[15:8]}};
			5'b0100x: wb_dat_o <= {4{flash_d[7:0]}};
			5'b1000x: wb_dat_o <= {4{flash_d[15:8]}};
			5'b0011x: wb_dat_o <= {2{flash_d}};
			5'b1100x: wb_dat_o <= {2{flash_d}};
			5'b11110: begin wb_dat_o[31:16] <= flash_d; lsb <= ~lsb; end
			5'b11111: begin wb_dat_o[15:0]  <= flash_d; lsb <= ~lsb; end
			default:  wb_dat_o <= 32'hxxxxxxxx;
		endcase
	end
	if(store)
		flash_we_n <= 1'b0;
	if(sys_rst)
		lsb <= 1'b0;
end

/*
 * Timing of the flash chips:
 *   - typically 110ns address to output
 *   - 50ns write pulse width
 */
reg [3:0] counter;
reg counter_en;
reg counter_wr_mode;
wire counter_done = counter_wr_mode
		? (counter == wr_timing)
		: (counter == rd_timing);
always @(posedge sys_clk) begin
	if(sys_rst)
		counter <= 4'd0;
	else begin
		if(counter_en & ~counter_done)
			counter <= counter + 4'd1;
		else
			counter <= 4'd0;
	end
end

parameter IDLE		= 2'd0;
parameter DELAYRD	= 2'd1;
parameter DELAYWR	= 2'd2;
parameter ACK		= 2'd3;

reg [1:0] state;
reg [1:0] next_state;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= IDLE;
	else
		state <= next_state;
end

always @(*) begin
	next_state = state;
	counter_en = 1'b0;
	counter_wr_mode = 1'b0;
	load = 1'b0;
	store = 1'b0;
	wb_ack_o = 1'b0;

	case(state)
		IDLE: begin
			if(wb_cyc_i & wb_stb_i) begin
				if(wb_we_i)
					next_state = DELAYWR;
				else
					next_state = DELAYRD;
			end
		end

		DELAYRD: begin
			counter_en = 1'b1;
			if(counter_done) begin
				load = 1'b1;
				if(~two_cycle_transfer | lsb)
					next_state = ACK;
			end
		end

		DELAYWR: begin
			counter_wr_mode = 1'b1;
			counter_en = 1'b1;
			store = 1'b1;
			if(counter_done)
				next_state = ACK;
		end

		ACK: begin
			wb_ack_o = 1'b1;
			next_state = IDLE;
		end
	endcase
end

endmodule
