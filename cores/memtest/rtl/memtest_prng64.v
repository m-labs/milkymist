module memtest_prng64(
	input clk,
	input rst,
	input ce,
	output reg [63:0] rand
);

reg [30:0] state;

reg o;
integer i;
always @(posedge clk) begin
	if(rst) begin
		state = 31'd0;
		rand = 64'd0;
	end else if(ce) begin
		for(i=0;i<64;i=i+1) begin
			o = ~(state[30] ^ state[27]);
			rand[i] = o;
			state = {state[29:0], o};
		end
	end
end

endmodule
