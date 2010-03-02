/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009, 2010 Sebastien Bourdeauducq
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

reg sys_rst;

reg [13:0] csr_a;
reg csr_we;
reg [31:0] csr_di;
wire [31:0] csr_do;

wire [31:0] wbm_adr_o;
wire [2:0] wbm_cti_o;
wire wbm_cyc_o;
wire wbm_stb_o;
reg wbm_ack_i;
wire [31:0] wbm_dat_o;
wire wbm_we_o;

reg [3:0] phy_rx_data;
reg phy_dv;
reg phy_rx_er;

minimac #(
	.csr_addr(4'h0)
) ethernet (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_di(csr_di),
	.csr_do(csr_do),

	.wbm_adr_o(wbm_adr_o),
	.wbm_cti_o(wbm_cti_o),
	.wbm_we_o(wbm_we_o),
	.wbm_cyc_o(wbm_cyc_o),
	.wbm_stb_o(wbm_stb_o),
	.wbm_ack_i(wbm_ack_i),
	.wbm_sel_o(),
	.wbm_dat_o(wbm_dat_o),
	.wbm_dat_i(),

	.irq_rx(),
	.irq_tx(),

	.phy_tx_clk(),
	.phy_tx_data(),
	.phy_tx_en(),
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

always @(posedge sys_clk) begin
	if(wbm_cyc_o & wbm_stb_o & ~wbm_ack_i & (($random % 5) == 0)) begin
		$display("Write(%b): %x <- %x", wbm_we_o, wbm_adr_o, wbm_dat_o);
		wbm_ack_i = 1'b1;
	end else
		wbm_ack_i = 1'b0;
end


always @(posedge phy_rx_clk) begin
	phy_rx_er <= 1'b0;
	phy_rx_data <= $random;
	if(phy_dv) begin
		//$display("rx: %x", phy_rx_data);
		if(($random % 125) == 0) begin
			phy_dv <= 1'b0;
			$display("** stopping transmission");
		end
	end else begin
		if(($random % 12) == 0) begin
			phy_dv <= 1'b1;
			$display("** starting transmission");
		end
	end
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
	csrwrite(32'h14, 32'h10000000);
	csrwrite(32'h10, 1);
	csrwrite(32'h20, 32'h20000000);
	csrwrite(32'h1C, 1);
	csrwrite(32'h2C, 32'h30000000);
	csrwrite(32'h28, 1);
	csrwrite(32'h38, 32'h40000000);
	csrwrite(32'h34, 1);

	#3000;
	csrread(32'h00);

	csrread(32'h14);
	csrread(32'h20);
	csrread(32'h2C);
	csrread(32'h38);
	
	$finish;
end

endmodule
