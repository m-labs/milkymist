// TODO

module jtag_cores (
    // ----- Inputs -------
    reg_d,
    reg_addr_d,
    // ----- Outputs -------    
    reg_update,
    reg_q,
    reg_addr_q,
    jtck,
    jrstn
);

input [7:0] reg_d;
input [2:0] reg_addr_d;

output reg_update;
wire   reg_update;
output [7:0] reg_q;
wire   [7:0] reg_q;
output [2:0] reg_addr_q;
wire   [2:0] reg_addr_q;

output jtck;
wire   jtck;
output jrstn;
wire   jrstn;

assign reg_update = 1'b0;
assign reg_q = 8'hxx;
assign reg_addr_q = 3'bxxx;
assign jtck = 1'b0;
assign jrstn = 1'b1;
    
endmodule
