/*
 * PS2 Interface
 * Copyright (C) 2009 Takeshi Matsuya
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

module ps2 #(
	parameter csr_addr = 4'h0,
	parameter clk_freq = 100000000
) (
	input sys_rst,
	input sys_clk,

	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output reg [31:0] csr_do,

	inout ps2_clk,
	inout ps2_data,
	output reg irq
);

/* CSR interface */
wire csr_selected = csr_a[13:10] == csr_addr;
reg tx_busy;

//-----------------------------------------------------------------
// divisor
//-----------------------------------------------------------------
reg [9:0] enable_counter;
wire enable;
assign enable = (enable_counter == 10'd0);

parameter divisor = clk_freq/12800/16;

always @(posedge sys_clk) begin
	if(sys_rst)
		enable_counter <= divisor - 10'd1;
	else begin
		enable_counter <= enable_counter - 10'd1;
		if(enable)
			enable_counter <= divisor - 10'd1;
	end
end

//-----------------------------------------------------------------
// Synchronize ps2 clock and data
//-----------------------------------------------------------------
reg ps2_clk_1;
reg ps2_data_1;
reg ps2_clk_2;
reg ps2_data_2;
reg ps2_clk_out;
reg ps2_data_out1, ps2_data_out2;

always @(posedge sys_clk) begin
	ps2_clk_1 <= ps2_clk;
	ps2_data_1 <= ps2_data;
	ps2_clk_2 <= ps2_clk_1;
	ps2_data_2 <= ps2_data_1;
end

/* PS2 */
reg [7:0] kcode;
reg rx_clk_data;
reg [5:0] rx_clk_count;
reg [4:0] rx_bitcount;
reg [10:0] rx_data;
reg [10:0] tx_data;
reg we_reg;

/* FSM */
reg [2:0] state;
reg [2:0] next_state;

parameter RECEIVE		= 3'd0;
parameter WAIT_READY		= 3'd1;
parameter CLOCK_LOW		= 3'd2;
parameter CLOCK_HIGH		= 3'd3;
parameter CLOCK_HIGH1		= 3'd4;
parameter CLOCK_HIGH2		= 3'd5;
parameter WAIT_CLOCK_LOW	= 3'd6;
parameter TRANSMIT		= 3'd7;

assign state_receive = state == RECEIVE;
assign state_transmit = state == TRANSMIT;

always @(posedge sys_clk) begin
	if(sys_rst)
		state = RECEIVE;
	else begin
		state = next_state;
	end
end

/* ps2 clock falling edge 100us counter */
//parameter divisor_100us = clk_freq/10000;
parameter divisor_100us = 1;
reg [16:0] watchdog_timer;
wire watchdog_timer_done;
assign watchdog_timer_done = (watchdog_timer == 17'd0);
always @(sys_clk) begin
	if(sys_rst||ps2_clk_out)
		watchdog_timer <= divisor_100us - 1;
	else if(~watchdog_timer_done)
			watchdog_timer <= watchdog_timer - 1;
end

always @(*) begin
	ps2_clk_out = 1'b1;
	ps2_data_out1 = 1'b1;
	tx_busy = 1'b1;

	next_state = state;

	case(state)
		RECEIVE: begin
			tx_busy = 1'b0;
			if(we_reg) begin
				next_state = WAIT_READY;
			end
		end
		WAIT_READY: begin
			if(rx_bitcount == 5'd0) begin
				ps2_clk_out = 1'b0;
				next_state = CLOCK_LOW;
			end
		end
		CLOCK_LOW: begin
			ps2_clk_out = 1'b0;
			if(watchdog_timer_done) begin
				next_state = CLOCK_HIGH;
			end
		end
		CLOCK_HIGH: begin
			next_state = CLOCK_HIGH1;
		end
		CLOCK_HIGH1: begin
			next_state = CLOCK_HIGH2;
		end
		CLOCK_HIGH2: begin
			ps2_data_out1 = 1'b0;
			next_state = WAIT_CLOCK_LOW;
		end
		WAIT_CLOCK_LOW: begin
			ps2_data_out1 = 1'b0;
			if(ps2_clk_2 == 1'b0) begin
				next_state = TRANSMIT;
			end
		end
		TRANSMIT: begin
			if(rx_bitcount == 5'd10) begin
				next_state = RECEIVE;
			end
		end
	endcase
end

//-----------------------------------------------------------------
// PS2 RX/TX Logic
//-----------------------------------------------------------------
always @(posedge sys_clk) begin
	if(sys_rst) begin
		rx_clk_data <= 1'd1;
		rx_clk_count <= 5'd0;
		rx_bitcount <= 5'd0;
		rx_data <= 11'b11111111111;
		irq <= 1'd0;
		csr_do <= 32'd0;
		we_reg <= 1'b0;
		ps2_data_out2 <= 1'b1;
	end else begin
		irq <= 1'b0;
		we_reg <= 1'b0;
		csr_do <= 32'd0;
		if(csr_selected) begin
			case(csr_a[0])
				1'b0: csr_do <= kcode;
				1'b1: csr_do <= tx_busy;
			endcase
			if(csr_we && csr_a[0] == 1'b0) begin
				tx_data <= {2'b11, ~(^csr_di[7:0]), csr_di[7:0]}; // STOP+PARITY+DATA
				we_reg <= 1'b1;
			end
		end
		if(enable) begin
			if(rx_clk_data == ps2_clk_2) begin
				rx_clk_count <= rx_clk_count + 5'd1;
			end else begin
				rx_clk_count <= 5'd0;
				rx_clk_data <= ps2_clk_2;
			end
			if(state_receive && rx_clk_data == 1'b0 && rx_clk_count == 5'd4) begin
				rx_data <= {ps2_data_2, rx_data[10:1]};
				rx_bitcount <= rx_bitcount + 5'd1;
				if(rx_bitcount == 5'd10) begin
					irq <= 1'b1;
					kcode <= rx_data[9:2];
				end
			end
			if(state_transmit && rx_clk_data == 1'b0 && rx_clk_count == 5'd0) begin
				ps2_data_out2 <= tx_data[rx_bitcount];
				rx_bitcount <= rx_bitcount + 5'd1;
				if(rx_bitcount == 5'd10) begin
					ps2_data_out2 <= 1'b1;
				end
			end
			if(rx_clk_count == 5'd16) begin
				rx_bitcount <= 5'd0;
				rx_data <= 11'b11111111111;
			end
		end
	end
end

assign ps2_clk = ps2_clk_out ? 1'hz : 1'b0;
assign ps2_data = ps2_data_out1 & ps2_data_out2 ? 1'hz : 1'b0;

endmodule
