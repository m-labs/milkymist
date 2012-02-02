/*
 * ledm.v - LED matrix controller
 *
 * Copyright 2012 by Werner Almesberger
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 */

/*
 * LEDs are organized as antiparallel pairs in a matrix of R rows and C
 * columns. The controller cycles through the rows and lights first the
 * LEDs in one half of the pairs and then the ones in the other half.
 *
 * Inactive rows and columns are driven to Z.
 *
 * LED brightness is controlled by an R*C*2-channel PWM controller with
 * common period and per-channel duty cycle. A value of 0 disables the
 * LED.
 */

module ledm #(
        parameter csr_addr = 4'h9,
	parameter clk_freq = 100000000,	/* 100 MHz */
	parameter refresh = 1000,	/*   1 kHz */
        parameter rows = 3,
        parameter cols = 4,
        parameter row_bits = 2,
        parameter col_bits = 2,
	parameter pwm_bits = 8,
	parameter prescaler_bits = 8
) (
        input sys_clk,
        input sys_rst,

        input [13:0] csr_a,
        input csr_we,
        input [31:0] csr_di,
        output reg [31:0] csr_do,

        inout [rows-1:0] ledr,
        inout [cols-1:0] ledc
);

wire csr_selected = csr_a[13:10] == csr_addr;

/*
 * LED register array (with default parameters):
 * row (3) * column (4) * direction (2)
 *
 * Register address:
 * 9 8 7 6 5 4 3 2 1 0
 * x 0 x x x R R C C D  LED at row R, column C, direction D
 * x 1 x x x x x 0 0 0  prescaler (0: stop scanning;, N: divide clock by N+1)
 * x 1 x x x x x 0 0 1  force row tristate (0: no change; 1: Z)
 * x 1 x x x x x 0 1 0  force row zero (0: no change; 1: 0)
 * x 1 x x x x x 0 1 1  force row set (0: no change; 1: 1)
 * x 1 x x x x x 1 0 0  reserved
 * x 1 x x x x x 1 0 1  force column tristate (0: no change; 1: Z)
 * x 1 x x x x x 1 1 0  force column zero (0: no change; 1: 0)
 * x 1 x x x x x 1 1 1  force column  set (0: no change; 1: 1)
 *
 * Notes about the row/coumn overrides:
 *
 * - they are meant for testing and debugging and thus don't have overly
 *   "nice" properties
 * - they only have a lasting effect if prescaler = 0
 * - the overrides cannot be read back. A read should not be attempted.
 *   The current implementation returns the prescaler setting.
 */

reg [pwm_bits-1:0] led[0:rows-1][0:1][0:cols-1];
				/* PWM end; [row] [direction] [column] */
reg [prescaler_bits-1:0] prescaler; /* prescaler cycle */

reg [rows-1:0] ledr_reg;	/* row output buffer */
reg [cols-1:0] ledc_reg;	/* column output buffer */
assign ledr = ledr_reg;
assign ledc = ledc_reg;

reg [prescaler_bits-1:0] pre_count; /* prescaler, 0 ... prescaler-1 */
reg [pwm_bits-1:0] pwm_count;	/* PWM, 0 ... (1 << pwm_bits)-1 */
reg [row_bits-1:0] row, curr_row; /* row counter and cached current row */
reg dir;			/* direction toggle */

`define REG_ACCESS				\
    led[csr_a[col_bits+row_bits:col_bits+1]]	\
      [csr_a[0]]				\
      [csr_a[col_bits:1]]

assign ps_sel = csr_a[8];


always @(posedge sys_clk) begin: _
	if (sys_rst) begin
		initialize();
		disable _;
	end

	csr_do <= 0;
	if (csr_selected) begin
		if (!ps_sel &&
		    csr_a[col_bits+row_bits:col_bits+1] <= rows &&
		    csr_a[col_bits:1] <= cols) begin
			csr_do <= `REG_ACCESS;
			if (csr_we)
				`REG_ACCESS <= csr_di[pwm_bits-1:0];
		end
		if (ps_sel) begin
			csr_do <= prescaler;
			if (csr_we)
				configure();
		end
	end

	if(!prescaler)
		disable _;

	if (pre_count) begin
		pre_count <= pre_count-1'd1;
	end else begin
		pre_count <= prescaler;
		if (pwm_count)
			tick();
		else
			setup_row();
		pwm_count <= pwm_count+1'd1;
	end
end


task initialize;
begin: _
	integer r, d, c;

	/*
	 * System clock / PWM steps / directions / rows / refresh - 1
	 * 80 MHz / 256 / 2 / 3 / 1 kHz - 1 = 51
	 */
	prescaler <= (clk_freq >> pwm_bits)/2/rows/refresh-1;
	pre_count <= 0;
	pwm_count <= 0;
	row <= 0;
	curr_row <= 0;
	dir <= 0;

	for (r = 0; r != rows; r = r+1)
		ledr_reg[r] <= 1'bz;
	for (c = 0; c != cols; c = c+1)
		ledc_reg[c] <= 1'bz;
	for (r = 0; r != rows; r = r+1)
		for (d = 0; d != 2; d = d+1)
			for (c = 0; c != cols; c = c+1)
				led[r][d][c] <= 0;
end
endtask


`define ITERATE(r, n, v)		\
	for (i = 0; i != n; i = i+1)	\
		if (csr_di[i])		\
			r[i] <= v

task configure;
begin: _
	integer i;

	case(csr_a[2:0])
		3'b000:	prescaler <= csr_di[prescaler_bits-1:0];
		3'b001:	`ITERATE(ledr_reg, rows, 1'bz);
		3'b010:	`ITERATE(ledr_reg, rows, 0);
		3'b011:	`ITERATE(ledr_reg, rows, 1);
		3'b101:	`ITERATE(ledc_reg, cols, 1'bz);
		3'b110:	`ITERATE(ledc_reg, cols, 0);
		3'b111:	`ITERATE(ledc_reg, cols, 1);
	endcase
end
endtask


task tick;
begin: _
	integer i;

	for (i = 0; i != cols; i = i+1)
		if (led[curr_row][dir][i] == pwm_count)
			ledc_reg[i] <= 1'bz;
end
endtask


task setup_row;
begin: _
	integer i;

	for (i = 0; i != rows; i = i+1)
		ledr_reg[i] <= row == i ? dir : 1'bz;
	for (i = 0; i != cols; i = i+1)
		ledc_reg[i] <= led[row][!dir][i] ? !dir : 1'bz;
	curr_row <= row;
	if (dir) begin
		if (row == rows-1)
			row <= 0;
		else
			row <= row+1'd1;
	end
	dir <= !dir;
end
endtask

endmodule
