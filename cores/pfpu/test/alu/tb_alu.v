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

module tb_alu();

reg sys_clk;
reg alu_rst;

initial sys_clk = 1'b0;
always #5 sys_clk = ~sys_clk;

task waitclock;
begin
	@(posedge sys_clk);
	#1;
end
endtask

task waitnclock;
input [15:0] n;
integer i;
begin
	for(i=0;i<n;i=i+1)
		waitclock;
end
endtask

reg [31:0] a;
reg [31:0] b;
reg [1:0] flags;
reg [3:0] opcode;
wire [31:0] r;

pfpu_alu dut(
	.sys_clk(sys_clk),
	.alu_rst(alu_rst),

	.a(a),
	.b(b),
	.flags(flags),
	.opcode(opcode),
	.r(r),
	.r_valid(),
	.err_collision()
);

real x;
always begin
	alu_rst = 1'b1;
	waitclock;
	alu_rst = 1'b0;
	
	/* Test addition */
	opcode = 4'h1;
	waitclock;
	opcode = 4'h0;
	$tofloat(3.0, a);
	$tofloat(9.0, b);
	waitnclock(3);
	$fromfloat(r, x);
	$display("Addition result:\t%f", x);
	
	/* Test subtraction */
	opcode = 4'h2;
	waitclock;
	opcode = 4'h0;
	$tofloat(1.0, a);
	$tofloat(12.34, b);
	waitnclock(3);
	$fromfloat(r, x);
	$display("Subtraction result:\t%f", x);
	
	/* Test multiplication */
	opcode = 4'h3;
	waitclock;
	opcode = 4'h0;
	$tofloat(0.1, a);
	$tofloat(45.0, b);
	waitnclock(4);
	$fromfloat(r, x);
	$display("Multiplication result:\t%f", x);
	
	/* Test division */
	opcode = 4'h4;
	waitclock;
	opcode = 4'h0;
	$tofloat(1.0, a);
	$tofloat(12.34, b);
	waitnclock(3);
	$fromfloat(r, x);
	$display("Division result:\t%f", x);
	
	/* Test float to integer */
	opcode = 4'h5;
	waitclock;
	opcode = 4'h0;
	$tofloat(2848.1374, a);
	waitclock;
	$display("F2I result:\t\t%d", r);
	
	/* Test integer to float */
	opcode = 4'h6;
	waitclock;
	opcode = 4'h0;
	a = 32'd398487;
	waitnclock(2);
	$fromfloat(r, x);
	$display("I2F result:\t\t%f", x);
	
	/* Test vector maker */
	opcode = 4'h7;
	waitclock;
	opcode = 4'h0;
	a = 32'h0000cafe;
	b = 32'h0000babe;
	waitnclock(1);
	$display("Vect result:\t\t%x", r);

	/* Test sine */
	opcode = 4'h8;
	waitclock;
	opcode = 4'h0;
	a = -32'd133988374;
	waitnclock(3);
	$fromfloat(r, x);
	$display("Sine result:\t\t%f", x);
	
	/* Test cosine */
	opcode = 4'h9;
	waitclock;
	opcode = 4'h0;
	a = -32'd133988374;
	waitnclock(3);
	$fromfloat(r, x);
	$display("Cosine result:\t\t%f", x);

	/* Test above */
	opcode = 4'ha;
	waitclock;
	opcode = 4'h0;
	$tofloat(21.2984, a);
	$tofloat(17.8148, b);
	waitnclock(1);
	$fromfloat(r, x);
	$display("Above result:\t\t%f", x);
	
	$finish;
end

endmodule
