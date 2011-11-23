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

module sysctl #(
	parameter csr_addr = 4'h0,
	parameter ninputs = 16,
	parameter noutputs = 16,
	parameter clk_freq = 32'h00000000,
	parameter systemid = 32'habadface
) (
	input sys_clk,
	input sys_rst,
	
	/* Interrupts */
	output reg gpio_irq,
	output reg timer0_irq,
	output reg timer1_irq,

	/* CSR bus interface */
	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output reg [31:0] csr_do,
	
	/* GPIO */
	input [ninputs-1:0] gpio_inputs,
	output reg [noutputs-1:0] gpio_outputs,

	input [31:0] capabilities,

	output reg debug_write_lock,
	output reg bus_errors_en,
	output reg hard_reset
);

/*
 * GPIO
 */

/* Synchronize the input */
reg [ninputs-1:0] gpio_in0;
reg [ninputs-1:0] gpio_in;
always @(posedge sys_clk) begin
	gpio_in0 <= gpio_inputs;
	gpio_in <= gpio_in0;
end

/* Detect level changes and generate IRQs */
reg [ninputs-1:0] gpio_inbefore;
always @(posedge sys_clk) gpio_inbefore <= gpio_in;
wire [ninputs-1:0] gpio_diff = gpio_inbefore ^ gpio_in;
reg [ninputs-1:0] gpio_irqen;
always @(posedge sys_clk) begin
	if(sys_rst)
		gpio_irq <= 1'b0;
	else
		gpio_irq <= |(gpio_diff & gpio_irqen);
end

/*
 * Dual timer
 */

reg en0, en1;
reg ar0, ar1;
reg [31:0] counter0, counter1;
reg [31:0] compare0, compare1;

wire match0 = (counter0 == compare0);
wire match1 = (counter1 == compare1);

/*
 * ICAP
 */

wire icap_ready;
wire icap_we;

sysctl_icap icap(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.ready(icap_ready),
	.we(icap_we),
	.d(csr_di[15:0]),
	.ce(csr_di[16]),
	.write(csr_di[17])
);

/*
 * Debug scrachpad register
 */
reg [7:0] debug_scratchpad;

/*
 * Logic and CSR interface
 */

wire csr_selected = csr_a[13:10] == csr_addr;

assign icap_we = csr_selected & csr_we & (csr_a[4:0] == 5'b10000);

always @(posedge sys_clk) begin
	if(sys_rst) begin
		csr_do <= 32'd0;

		timer0_irq <= 1'b0;
		timer1_irq <= 1'b0;
	
		gpio_outputs <= {noutputs{1'b0}};
		gpio_irqen <= {ninputs{1'b0}};
		
		en0 <= 1'b0;
		en1 <= 1'b0;
		ar0 <= 1'b0;
		ar1 <= 1'b0;
		counter0 <= 32'd0;
		counter1 <= 32'd0;
		compare0 <= 32'hFFFFFFFF;
		compare1 <= 32'hFFFFFFFF;

		hard_reset <= 1'b0;

		debug_scratchpad <= 8'd0;
		debug_write_lock <= 1'b0;
		bus_errors_en <= 1'b0;
	end else begin
		timer0_irq <= 1'b0;
		timer1_irq <= 1'b0;

		/* Handle timer 0 */
		if( en0 & ~match0) counter0 <= counter0 + 32'd1;
		if( en0 &  match0) timer0_irq <= 1'b1;
		if( ar0 &  match0) counter0 <= 32'd1;
		if(~ar0 &  match0) en0 <= 1'b0;

		/* Handle timer 1 */
		if( en1 & ~match1) counter1 <= counter1 + 32'd1;
		if( en1 &  match1) timer1_irq <= 1'b1;
		if( ar1 &  match1) counter1 <= 32'd1;
		if(~ar1 &  match1) en1 <= 1'b0;
	
		csr_do <= 32'd0;
		if(csr_selected) begin
			/* CSR Writes */
			if(csr_we) begin
				case(csr_a[4:0])
					/* GPIO registers */
					// 00000 is GPIO IN and is read-only
					5'b00001: gpio_outputs <= csr_di[noutputs-1:0];
					5'b00010: gpio_irqen <= csr_di[ninputs-1:0];
					
					/* Timer 0 registers */
					5'b00100: begin
						en0 <= csr_di[0];
						ar0 <= csr_di[1];
					end
					5'b00101: compare0 <= csr_di;
					5'b00110: counter0 <= csr_di;
					
					/* Timer 1 registers */
					5'b01000: begin
						en1 <= csr_di[0];
						ar1 <= csr_di[1];
					end
					5'b01001: compare1 <= csr_di;
					5'b01010: counter1 <= csr_di;

					/* ICAP */
					// 10000 is ICAP and is handled separately

					/* Debug monitor (gdbstub) */
					5'b10100: debug_scratchpad <= csr_di[7:0];
					5'b10101: begin
						if(csr_di[0])
							debug_write_lock <= 1'b1;
						bus_errors_en <= csr_di[1];
					end

					// 11101 is clk_freq and is read-only
					// 11110 is capabilities and is read-only
					5'b11111: hard_reset <= 1'b1;
				endcase
			end
		
			/* CSR Reads */
			case(csr_a[4:0])
				/* GPIO registers */
				5'b00000: csr_do <= gpio_in;
				5'b00001: csr_do <= gpio_outputs;
				5'b00010: csr_do <= gpio_irqen;
				
				/* Timer 0 registers */
				5'b00100: csr_do <= {ar0, en0};
				5'b00101: csr_do <= compare0;
				5'b00110: csr_do <= counter0;
				
				/* Timer 1 registers */
				5'b01000: csr_do <= {ar1, en1};
				5'b01001: csr_do <= compare1;
				5'b01010: csr_do <= counter1;

				/* ICAP */
				5'b10000: csr_do <= icap_ready;

				/* Debug monitor (gdbstub) */
				5'b10100: csr_do <= debug_scratchpad;
				5'b10101: csr_do <= {bus_errors_en, debug_write_lock};

				/* Read only SoC properties */
				5'b11101: csr_do <= clk_freq;
				5'b11110: csr_do <= capabilities;
				5'b11111: csr_do <= systemid;
			endcase
		end
	end
end

endmodule
