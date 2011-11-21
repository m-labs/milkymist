
`timescale 1 ns / 1 ns

module tb_monitor;

parameter tck = 10;

reg sys_clk, sys_rst;
reg wb_we_i, wb_stb_i, wb_cyc_i;
reg [31:0] wb_adr_i;
reg [3:0] wb_sel_i;
reg [31:0] wb_dat_i;
wire wb_ack_o;
wire [31:0] wb_dat_o;
reg dat;

monitor dut(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.write_lock(1'b1),
	.wb_stb_i(wb_stb_i),
	.wb_cyc_i(wb_cyc_i),
	.wb_ack_o(wb_ack_o),
	.wb_we_i(wb_we_i),
	.wb_adr_i(wb_adr_i),
	.wb_sel_i(wb_sel_i),
	.wb_dat_i(wb_dat_i),
	.wb_dat_o(wb_dat_o)
);

task waitclock;
begin
	@(posedge sys_clk);
	#1;
end
endtask

task wbwrite;
input [31:0] address;
input [31:0] data;
integer i;
begin
	wb_adr_i = address;
	wb_dat_i = data;
	wb_cyc_i = 1'b1;
	wb_stb_i = 1'b1;
	wb_we_i = 1'b1;
	i = 0;
	while(~wb_ack_o) begin
		i = i+1;
		waitclock;
	end
	waitclock;
	$display("WB Write: %x=%x acked in %d clocks", address, data, i);
	wb_cyc_i = 1'b0;
	wb_stb_i = 1'b0;
	wb_we_i = 1'b0;
end
endtask

task wbread;
input [31:0] address;
integer i;
begin
	wb_adr_i = address;
	wb_cyc_i = 1'b1;
	wb_stb_i = 1'b1;
	wb_we_i = 1'b0;
	i = 0;
	while(~wb_ack_o) begin
		i = i+1;
		waitclock;
	end
	$display("WB Read : %x=%x acked in %d clocks", address, wb_dat_o, i);
	waitclock;
	wb_cyc_i = 1'b0;
	wb_stb_i = 1'b0;
	wb_we_i = 1'b0;
end
endtask

/* clock */
initial sys_clk <= 0;
always #(tck/2) sys_clk <= ~sys_clk;

initial begin
	$dumpfile("monitor.vcd");
	$dumpvars(-1, dut);

	/* Reset / Initialize our logic */
	sys_rst = 1'b1;

	wb_adr_i = 32'd0;
	wb_dat_i = 32'd0;
	wb_cyc_i = 1'b0;
	wb_stb_i = 1'b0;
	wb_we_i = 1'b0;
	wb_sel_i = 4'b1111;

	waitclock;

	sys_rst = 1'b0;

	waitclock;

	$display("Reading ROM");
	wbread(32'h00000000);
	wbread(32'h00000004);
	wbread(32'h00000008);
	wbread(32'h00000010);

	$display("Reading and writing ROM/RAM");
	wbread(32'h00000600);
	wbwrite(32'h00000000, 32'h12345678);
	wbwrite(32'h00000600, 32'h12345678);
	wbread(32'h00000000);
	wbread(32'h00000600);
	
	$display("Test byte enables");
	wbwrite(32'h00000600, 32'h00000000);
	wbread(32'h00000600);
	wb_sel_i = 4'b0001;
	wbwrite(32'h00000600, 32'haa55aa55);
	wbread(32'h00000600);
	wb_sel_i = 4'b0100;
	wbwrite(32'h00000600, 32'haa55aa55);
	wbread(32'h00000600);
	wb_sel_i = 4'b0010;
	wbwrite(32'h00000600, 32'haa55aa55);
	wbread(32'h00000600);
	wb_sel_i = 4'b1000;
	wbwrite(32'h00000600, 32'haa55aa55);
	wbread(32'h00000600);

	$finish;
end

endmodule

