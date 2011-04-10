/*
 * Milkymist SoC
 * Copyright (C) 2007, 2008, 2009, 2010, 2011 Sebastien Bourdeauducq
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

module tb_minimac();

/* 100MHz system clock */
reg sys_clk;
initial sys_clk = 1'b0;
always #5 sys_clk = ~sys_clk;

/* 25MHz RX clock */
reg phy_rx_clk;
initial phy_rx_clk = 1'b0;
always #20 phy_rx_clk = ~phy_rx_clk;

/* 25MHz TX clock */
reg phy_tx_clk;
initial phy_tx_clk = 1'b0;
always #20 phy_tx_clk = ~phy_tx_clk;

reg sys_rst;

reg [13:0] csr_a;
reg csr_we;
reg [31:0] csr_di;
wire [31:0] csr_do;

reg [31:0] wb_adr_i;
reg [31:0] wb_dat_i;
wire [31:0] wb_dat_o;
reg wb_cyc_i;
reg wb_stb_i;
reg wb_we_i;
wire wb_ack_o;

reg [3:0] phy_rx_data;
reg phy_dv;
reg phy_rx_er;

wire phy_tx_en;
wire [3:0] phy_tx_data;

wire irq_rx;
wire irq_tx;

minimac2 #(
	.csr_addr(4'h0)
) ethernet (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_di),
	.csr_do(csr_do),
	
	.wb_adr_i(wb_adr_i),
	.wb_dat_i(wb_dat_i),
	.wb_dat_o(wb_dat_o),
	.wb_cyc_i(wb_cyc_i),
	.wb_stb_i(wb_stb_i),
	.wb_we_i(wb_we_i),
	.wb_sel_i(4'hf),
	.wb_ack_o(wb_ack_o),

	.irq_rx(irq_rx),
	.irq_tx(irq_tx),

	.phy_tx_clk(phy_tx_clk),
	.phy_tx_data(phy_tx_data),
	.phy_tx_en(phy_tx_en),
	.phy_tx_er(),
	.phy_rx_clk(phy_rx_clk),
	.phy_rx_data(phy_rx_data),
	.phy_dv(phy_dv),
	.phy_rx_er(phy_rx_er),
	.phy_col(),
	.phy_crs(),
	.phy_mii_clk(),
	.phy_mii_data()
);

task waitclock;
begin
	@(posedge sys_clk);
	#1;
end
endtask

task csrwrite;
input [31:0] address;
input [31:0] data;
begin
	csr_a = address[16:2];
	csr_di = data;
	csr_we = 1'b1;
	waitclock;
	$display("Configuration Write: %x=%x", address, data);
	csr_we = 1'b0;
end
endtask

task csrread;
input [31:0] address;
begin
	csr_a = address[16:2];
	waitclock;
	$display("Configuration Read : %x=%x", address, csr_do);
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

integer cycle;
initial cycle = 0;
always @(posedge phy_rx_clk) begin
	cycle <= cycle + 1;
	phy_rx_er <= 1'b0;
	phy_rx_data <= cycle;
	if(phy_dv) begin
		//$display("rx: %x", phy_rx_data);
		if((cycle % 16) == 13) begin
			phy_dv <= 1'b0;
			//$display("** stopping transmission");
		end
	end else begin
		if((cycle % 16) == 15) begin
			phy_dv <= 1'b1;
			//$display("** starting transmission");
		end
	end
end

always @(posedge phy_tx_clk) begin
	if(phy_tx_en)
		$display("tx: %x", phy_tx_data);
end

initial begin
	/* Reset / Initialize our logic */
	sys_rst = 1'b1;

	csr_a = 14'd0;
	csr_di = 32'd0;
	csr_we = 1'b0;
	phy_dv = 1'b0;

	waitclock;

	sys_rst = 1'b0;

	waitclock;

	csrwrite(32'h00, 0);
	csrwrite(32'h08, 1);
	wbwrite(32'h1000, 32'h12345678);
	wbread(32'h1000);
	csrwrite(32'h18, 10);
	csrwrite(32'h10, 1);

	#5000;
	
	csrread(32'h08);
	csrread(32'h0C);
	csrread(32'h10);
	csrread(32'h14);
	wbread(32'h0000);
	wbread(32'h0004);
	wbread(32'h0008);
	wbread(32'h0800);
	wbread(32'h0804);
	wbread(32'h0808);
	
	$finish;
end

endmodule
