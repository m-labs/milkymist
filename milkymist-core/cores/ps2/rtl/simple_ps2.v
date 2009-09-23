//
// Simple PS/2 Interface
//
module simple_ps2 #(
	parameter csr_addr = 4'h0,
	parameter clk_range = 8 	/* 4:4-7MHz 5:8-16MHz 6:17-33MHz 7:34-133MHz 8:67-134Mhz 9:135-268MHz */
) (
	input sys_clk,
	input sys_rst,
	input [13:0] csr_a,
	output irq,
	output [31:0] csr_do,
	input ps2_clk,
	input ps2_data
);

reg valid;
reg [10:0] rx_data;
reg [3:0] clk_data;
reg [7:0] kcode;
reg [clk_range:0] counter;

/* CSR interface */
wire csr_selected = csr_a[13:10] == csr_addr;

always @(posedge sys_clk or posedge sys_rst)
	if ( sys_rst )
		counter <= 0;
	else
		counter <= counter + 1;

always @(posedge counter[clk_range] or posedge sys_rst) begin
	if( sys_rst ) begin
		rx_data <= 11'b11111111111;
		clk_data <= 4'b0000;
		valid <= 1'b0;
		kcode <= 8'd0;
	end else begin
		clk_data <= {clk_data[2:0], ps2_clk};
		if ( clk_data == 4'b1000 )
			rx_data <= {ps2_data, rx_data[10:1]};
		if ( !rx_data[0] & rx_data[10] ) begin
			valid <= 1'b1;
			kcode <= rx_data[8:1];
			rx_data <= 11'b11111111111;
		end else
			valid <= 1'b0;
	end
end

assign irq = valid;
assign csr_do = csr_selected ? {24'd0, kcode} : 32'd0;

endmodule
