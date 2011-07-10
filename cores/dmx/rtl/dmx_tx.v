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

module dmx_tx #(
	parameter csr_addr = 4'h0,
	parameter clk_freq = 100000000
) (
	input sys_clk,
	input sys_rst,

	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output [31:0] csr_do,

	input thru,
	output tx
);

/* RAM and CSR interface */

wire csr_selected = csr_a[13:10] == csr_addr;

wire csr_channels_we;
wire [31:0] csr_do_channels;
wire [8:0] channel_a;
wire [7:0] channel_d;
dmx_dpram channels(
	.clk(sys_clk),

	.a(csr_a[8:0]),
	.we(csr_channels_we),
	.di(csr_di[7:0]),
	.do(csr_do_channels[7:0]),

	.a2(channel_a),
	.we2(1'b0),
	.di2(8'hxx),
	.do2(channel_d)
);
assign csr_channels_we = csr_selected & ~csr_a[9] & csr_we;
assign csr_do_channels[31:8] = 24'h000000;

reg thru_en;

reg [31:0] csr_do_reg;
reg csr_do_sel;
always @(posedge sys_clk) begin
	if(sys_rst) begin
		csr_do_reg <= 32'd0;
		csr_do_sel <= 1'b0;
		thru_en <= 1'b0;
	end else begin
		csr_do_reg <= 32'd0;
		csr_do_sel <= 1'b0;
		if(csr_selected) begin
			csr_do_sel <= ~csr_a[9];
			csr_do_reg <= thru_en;
			if(csr_we) begin
				if(csr_a[9])
					thru_en <= csr_di[0];
			end
		end
	end
end

assign csr_do = csr_do_sel ? csr_do_channels : csr_do_reg;

reg tx_gen;
assign tx = thru_en ? thru : tx_gen;

/* Signal generator */

parameter divisor = clk_freq/250000;

reg ce;
reg [8:0] ce_counter;
always @(posedge sys_clk) begin
	if(sys_rst) begin
		ce <= 1'b0;
		ce_counter <= divisor-1;
	end else begin
		if(ce_counter == 9'd0) begin
			ce <= 1'b1;
			ce_counter <= divisor-1;
		end else begin
			ce <= 1'b0;
			ce_counter <= ce_counter - 9'd1;
		end
	end
end

reg [7:0] channel_d_r;
reg channel_d_ce;
always @(posedge sys_clk) begin
	if(channel_d_ce)
		channel_d_r <= channel_d;
end

reg [3:0] tx_sel;
parameter TX_SEL_B0 =		4'd0;
parameter TX_SEL_B1 =		4'd1;
parameter TX_SEL_B2 =		4'd2;
parameter TX_SEL_B3 =		4'd3;
parameter TX_SEL_B4 =		4'd4;
parameter TX_SEL_B5 =		4'd5;
parameter TX_SEL_B6 =		4'd6;
parameter TX_SEL_B7 =		4'd7;
parameter TX_SEL_HI =		4'd8;
parameter TX_SEL_LO =		4'd9;

always @(posedge sys_clk) begin
	case(tx_sel)
		TX_SEL_B0: tx_gen <= channel_d_r[0];
		TX_SEL_B1: tx_gen <= channel_d_r[1];
		TX_SEL_B2: tx_gen <= channel_d_r[2];
		TX_SEL_B3: tx_gen <= channel_d_r[3];
		TX_SEL_B4: tx_gen <= channel_d_r[4];
		TX_SEL_B5: tx_gen <= channel_d_r[5];
		TX_SEL_B6: tx_gen <= channel_d_r[6];
		TX_SEL_B7: tx_gen <= channel_d_r[7];
		TX_SEL_HI: tx_gen <= 1'b1;
		TX_SEL_LO: tx_gen <= 1'b0;
		default: tx_gen <= 1'bx;
	endcase
end

reg acounter_reset;
reg acounter_ce;
reg frame_done;
reg [8:0] acounter;
always @(posedge sys_clk) begin
	if(ce) begin
		if(acounter_reset) begin
			acounter <= 9'd0;
			frame_done <= 1'b0;
		end else if(acounter_ce) begin
			acounter <= acounter + 9'd1;
			frame_done <= acounter == 9'd511;
		end
	end
end
assign channel_a = acounter;

reg break_counter_reset;
reg [4:0] break_counter;
reg break_done;
always @(posedge sys_clk) begin
	if(ce) begin
		if(break_counter_reset) begin
			break_counter <= 5'd0;
			break_done <= 1'b0;
		end else begin
			if(break_counter == 5'd25)
				break_done <= 1'b1;
			else
				break_counter <= break_counter + 5'd1;
		end
	end
end

reg [4:0] state;
reg [4:0] next_state;

parameter MTBP =	5'd0;
parameter BREAK =	5'd1;
parameter MAB1 =	5'd2;
parameter MAB2 =	5'd3;
parameter SC_START =	5'd4;
parameter SC_D0 =	5'd5;
parameter SC_D1 =	5'd6;
parameter SC_D2 =	5'd7;
parameter SC_D3 =	5'd8;
parameter SC_D4 =	5'd9;
parameter SC_D5 =	5'd10;
parameter SC_D6 =	5'd11;
parameter SC_D7 =	5'd12;
parameter SC_STOP1 =	5'd13;
parameter SC_STOP2 =	5'd14;
parameter START =	5'd15;
parameter D0 =		5'd16;
parameter D1 =		5'd17;
parameter D2 =		5'd18;
parameter D3 =		5'd19;
parameter D4 =		5'd20;
parameter D5 =		5'd21;
parameter D6 =		5'd22;
parameter D7 =		5'd23;
parameter STOP1 =	5'd24;
parameter STOP2 =	5'd25;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= MTBP;
	else if(ce)
		state <= next_state;
end

always @(*) begin
	tx_sel = TX_SEL_HI;
	acounter_reset = 1'b1;
	acounter_ce = 1'b0;
	break_counter_reset = 1'b1;

	channel_d_ce = 1'b0;

	next_state = state;

	case(state)
		MTBP: next_state = BREAK;

		BREAK: begin
			tx_sel = TX_SEL_LO;
			break_counter_reset = 1'b0;
			if(break_done)
				next_state = MAB1;
		end

		MAB1: next_state = MAB2;
		MAB2: next_state = SC_START;

		SC_START: begin
			tx_sel = TX_SEL_LO;
			next_state = SC_D0;
		end
		SC_D0: begin
			tx_sel = TX_SEL_LO;
			next_state = SC_D1;
		end
		SC_D1: begin
			tx_sel = TX_SEL_LO;
			next_state = SC_D2;
		end
		SC_D2: begin
			tx_sel = TX_SEL_LO;
			next_state = SC_D3;
		end
		SC_D3: begin
			tx_sel = TX_SEL_LO;
			next_state = SC_D4;
		end
		SC_D4: begin
			tx_sel = TX_SEL_LO;
			next_state = SC_D5;
		end
		SC_D5: begin
			tx_sel = TX_SEL_LO;
			next_state = SC_D6;
		end
		SC_D6: begin
			tx_sel = TX_SEL_LO;
			next_state = SC_D7;
		end
		SC_D7: begin
			tx_sel = TX_SEL_LO;
			next_state = SC_STOP1;
		end
		SC_STOP1: next_state = SC_STOP2;
		SC_STOP2: next_state = START;

		START: begin
			tx_sel = TX_SEL_LO;
			acounter_reset = 1'b0;
			channel_d_ce = 1'b1;
			next_state = D0;
		end
		D0: begin
			tx_sel = TX_SEL_B0;
			acounter_reset = 1'b0;
			next_state = D1;
		end
		D1: begin
			tx_sel = TX_SEL_B1;
			acounter_reset = 1'b0;
			next_state = D2;
		end
		D2: begin
			tx_sel = TX_SEL_B2;
			acounter_reset = 1'b0;
			next_state = D3;
		end
		D3: begin
			tx_sel = TX_SEL_B3;
			acounter_reset = 1'b0;
			next_state = D4;
		end
		D4: begin
			tx_sel = TX_SEL_B4;
			acounter_reset = 1'b0;
			next_state = D5;
		end
		D5: begin
			tx_sel = TX_SEL_B5;
			acounter_reset = 1'b0;
			next_state = D6;
		end
		D6: begin
			tx_sel = TX_SEL_B6;
			acounter_reset = 1'b0;
			next_state = D7;
		end
		D7: begin
			tx_sel = TX_SEL_B7;
			acounter_reset = 1'b0;
			next_state = STOP1;
		end
		STOP1: begin
			acounter_reset = 1'b0;
			acounter_ce = 1'b1;
			next_state = STOP2;
		end
		STOP2: begin
			acounter_reset = 1'b0;
			if(frame_done)
				next_state = MTBP;
			else
				next_state = START;
		end
	endcase
end

endmodule
