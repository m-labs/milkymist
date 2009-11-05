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

	output irq,

	input ps2_clk,
	input ps2_data
);

/* CSR interface */
wire csr_selected = csr_a[13:10] == csr_addr;

//-----------------------------------------------------------------
// divisor
//-----------------------------------------------------------------
reg [9:0] enable_counter;
wire	enable;
assign	enable = ( enable_counter == 10'd0);

parameter divisor = clk_freq/12800/16;

always @(posedge sys_clk) begin
	if ( sys_rst )
		enable_counter <= divisor - 10'd1;
	else begin
		enable_counter <= enable_counter - 10'd1;
		if (enable)
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

always @(posedge sys_clk) begin
	ps2_clk_1 <= ps2_clk;
	ps2_data_1 <= ps2_data;
	ps2_clk_2 <= ps2_clk_1;
	ps2_data_2 <= ps2_data_1;
end

//-----------------------------------------------------------------
// PS2 RX Logic
//-----------------------------------------------------------------
reg [7:0] kcode;
reg       rx_irq;
reg       rx_clk_data;
reg [5:0] rx_clk_count;
reg [4:0] rx_bitcount;
reg [10:0] rx_data;

always @(posedge sys_clk) begin
	if( sys_rst ) begin
		rx_clk_data <= 1'd1;
		rx_clk_count<= 5'd0;
		rx_bitcount <= 4'd0;
		rx_data     <= 11'b11111111111;
		rx_irq      <= 1'd0;
		csr_do      <= 32'd0;
	end else begin
rx_irq      <= 1'b0;	// IRQ ack
		csr_do      <= 32'd0;
		if (csr_selected) begin
//rx_irq      <= 1'b0;	// IRQ ack
//			if (csr_we) begin
//				case(csr_a[1:0])
//					2'b01:	rx_irq <= 1'b0;	// IRQ ack
//				endcase
//			end
			case(csr_a[1:0])
				2'b00: csr_do <= kcode;		// PS2 code
			endcase
		end
		if (enable) begin
			if ( rx_clk_data == ps2_clk_2 ) begin
				rx_clk_count <= rx_clk_count + 5'd1;
			end else begin
				rx_clk_count <= 5'd0;
				rx_clk_data  <= ps2_clk_2;
			end
			if ( rx_clk_data == 1'd0 && rx_clk_count == 5'd4 ) begin
				rx_data     <= {ps2_data_2, rx_data[10:1]};
				rx_bitcount <= rx_bitcount + 4'd1;
				if ( rx_bitcount == 4'd10 ) begin
					rx_irq <= 1'b1;
					kcode  <= rx_data[9:2];
				end
			end
			if ( rx_clk_count == 5'd16 ) begin
				rx_bitcount <= 4'd0;
				rx_data     <= 11'b11111111111;
			end
		end
	end
end

assign irq = rx_irq;

endmodule
