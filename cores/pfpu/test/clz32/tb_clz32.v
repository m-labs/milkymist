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

module tb_clz32();

reg [31:0] d;
wire [4:0] clz;

pfpu_clz32 dut(
	.d(d),
	.clz(clz)
);

reg [5:0] i;
reg [7:0] j;

initial begin
	$display("Testing clz32 module");
	
	for (j=0;j<100;j=j+1) begin
		for (i=0;i<32;i=i+1) begin
			d = (32'h80000000 >> i);
			if(i < 31) d = d + ($random % (32'h40000000 >> i));
			#1 $display("%b -> %d", d, clz);
			if(i[4:0] != clz) begin
				$display("***** TEST FAILED *****");
				$display("Expected %d, got %d", i, clz);
				$finish;
			end
		end
	end
	
	d = 32'h00000000;
	#1 $display("%b -> %d", d, clz);
	if(5'd31 != clz) begin
		$display("***** TEST FAILED *****");
		$display("Expected 31, got %d", i, clz);
		$finish;
	end
	
	$display("***** TEST PASSED *****");
	$finish;
end

endmodule
