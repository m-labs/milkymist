/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 *
 * This program is free and excepted software; you can use it, redistribute it
 * and/or modify it under the terms of the Exception General Public License as
 * published by the Exception License Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the Exception General Public License for more
 * details.
 *
 * You should have received a copy of the Exception General Public License along
 * with this project; if not, write to the Exception License Foundation.
 */

module sysctl #(
	parameter csr_addr = 4'h0,
	parameter ninputs = 16,
	parameter noutputs = 16,
	parameter systemid = 32'habadface
) (
	input sys_clk,
	input sys_rst,
	
	/* Interrupts */
	output gpio_irq,
	output timer0_irq,
	output timer1_irq,
   
	/* CSR bus interface */
	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output reg [31:0] csr_do,
	
	/* GPIO */
	input [ninputs-1:0] gpio_inputs,
	output reg [noutputs-1:0] gpio_outputs
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

reg [ninputs-1:0] gpio_irqact;
reg [ninputs-1:0] gpio_irqen;

wire [ninputs-1:0] gpio_diff = gpio_inbefore ^ gpio_in;

assign gpio_irq = |(gpio_irqact & gpio_irqen);

/*
 * Dual timer
 */

reg trig0, trig1;
reg en0, en1;
reg ar0, ar1;
reg [31:0] counter0, counter1;
reg [31:0] compare0, compare1;

wire match0 = (counter0 == compare0);
wire match1 = (counter1 == compare1);

assign timer0_irq = trig0;
assign timer1_irq = trig1;

/*
 * Logic and CSR interface
 */

wire csr_selected = csr_a[13:10] == csr_addr;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		csr_do <= 32'd0;
	
		gpio_outputs <= {noutputs{1'b0}};
		gpio_irqact <= {ninputs{1'b0}};
		gpio_irqen <= {ninputs{1'b0}};
		
		en0 <= 1'b0;
		en1 <= 1'b0;
		ar0 <= 1'b0;
		ar1 <= 1'b0;
		trig0 <= 1'b0;
		trig1 <= 1'b0;
		counter0 <= 32'd0;
		counter1 <= 32'd0;
		compare0 <= 32'hFFFFFFFF;
		compare1 <= 32'hFFFFFFFF;
	end else begin
		/* Handle GPIO */
		gpio_irqact <= gpio_irqact|gpio_diff;
	
		/* Handle timer 0 */
		if( en0 & ~match0) counter0 <= counter0 + 32'd1;
		if( en0 &  match0) trig0 <= 1'b1;
		if( ar0 &  match0) counter0 <= 32'd1;
		if(~ar0 &  match0) en0 <= 1'b0;

		/* Handle timer 1 */
		if( en1 & ~match1) counter1 <= counter1 + 32'd1;
		if( en1 &  match1) trig1 <= 1'b1;
		if( ar1 &  match1) counter1 <= 32'd1;
		if(~ar1 &  match1) en1 <= 1'b0;
	
		csr_do <= 32'd0;
		if(csr_selected) begin
			/* CSR Writes */
			if(csr_we) begin
				case(csr_a[3:0])
					/* GPIO registers */
					// 0000 is GPIO IN and is read-only
					4'b0001: gpio_outputs <= csr_di[noutputs-1:0];
					4'b0010: gpio_irqact <= (gpio_irqact|gpio_diff) & ~csr_di[ninputs-1:0];
					4'b0011: gpio_irqen <= csr_di[ninputs-1:0];
					
					/* Timer 0 registers */
					4'b0100: begin
						trig0 <= 1'b0;
						ar0 <= csr_di[1];
						en0 <= csr_di[2];
					end
					4'b0101: compare0 <= csr_di;
					4'b0110: counter0 <= csr_di;
					
					/* Timer 1 registers */
					4'b1000: begin
						trig1 <= 1'b0;
						ar1 <= csr_di[1];
						en1 <= csr_di[2];
					end
					4'b1001: compare1 <= csr_di;
					4'b1010: counter1 <= csr_di;
				endcase
			end
		
			/* CSR Reads */
			case(csr_a[3:0])
				/* GPIO registers */
				4'b0000: csr_do <= gpio_in;
				4'b0001: csr_do <= gpio_outputs;
				4'b0010: csr_do <= gpio_irqact;
				4'b0011: csr_do <= gpio_irqen;
				
				/* Timer 0 registers */
				4'b0100: csr_do <= {en0, ar0, trig0};
				4'b0101: csr_do <= compare0;
				4'b0110: csr_do <= counter0;
				
				/* Timer 1 registers */
				4'b1000: csr_do <= {en1, ar1, trig1};
				4'b1001: csr_do <= compare1;
				4'b1010: csr_do <= counter1;
				
				4'b1111: csr_do <= systemid;
			endcase
		end
	end
end

endmodule
