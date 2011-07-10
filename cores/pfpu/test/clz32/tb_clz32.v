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
