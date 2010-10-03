module jtag_cores (
    input [7:0] reg_d,
    input [2:0] reg_addr_d,
    output reg_update,
    output [7:0] reg_q,
    output [2:0] reg_addr_q,
    output jtck,
    output jrstn
);

wire tck;
wire tdi;
wire tdo;
wire shift;
wire update;
wire reset;

jtag_tap jtag_tap (
	.tck(tck),
	.tdi(tdi),
	.tdo(tdo),
	.shift(shift),
	.update(update),
	.reset(reset)
);

reg [10:0] jtag_shift;
reg [10:0] jtag_latched;

always @(posedge tck or posedge reset)
begin
	if(reset)
		jtag_shift <= 11'b0;
	else begin
		if(shift)
			jtag_shift <= {tdi, jtag_shift[10:1]};
		else
			jtag_shift <= {reg_d, reg_addr_d};
	end
end

assign tdo = jtag_shift[0];

always @(posedge reg_update or posedge reset)
begin
	if(reset)
		jtag_latched <= 11'b0;
	else
		jtag_latched <= jtag_shift;
end

assign reg_update = update;
assign reg_q = jtag_latched[10:3];
assign reg_addr_q = jtag_latched[2:0];
assign jtck = tck;
assign jrstn = ~reset;

endmodule
