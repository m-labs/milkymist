module ICAP_SPARTAN6(
	output BUSY,
	output [15:0] O,
	input CE,
	input CLK,
	input [15:0] I,
	input WRITE
);

always @(posedge CLK)
	if(~CE & ~WRITE)
		$display("ICAP receiving: %x", I);

endmodule
