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

`define AUTO_ON
 
module standby(
	input clk50,

	input btn1,
	input btn2,
	input btn3,
	output led1,
	output led2,

	output flash_ce_n,
	output flash_oe_n,
	output flash_we_n,
	output flash_rst_n,
	output sdram_clk_p,
	output sdram_clk_n,
	output vga_psave_n,
	output vga_clk,
	output mc_clk,
	output ac97_rst_n,
	output usba_oe_n,
	output usbb_oe_n,
	output phy_rst_n,
	output videoin_rst_n,
	output midi_tx,
	output dmxa_de,
	output dmxb_de
);

wire clk;
wire clk_dcm;
wire locked;

DCM_SP #(
	.CLKDV_DIVIDE(2.0),		// 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5

	.CLKFX_DIVIDE(8),		// 1 to 32
	.CLKFX_MULTIPLY(2),		// 2 to 32

	.CLKIN_DIVIDE_BY_2("FALSE"),
	.CLKIN_PERIOD(20.0),
	.CLKOUT_PHASE_SHIFT("NONE"),
	.CLK_FEEDBACK("NONE"),
	.DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"),
	.DUTY_CYCLE_CORRECTION("TRUE"),
	.PHASE_SHIFT(0),
	.STARTUP_WAIT("FALSE")
) clkgen (
	.CLK0(),
	.CLK90(),
	.CLK180(),
	.CLK270(),

	.CLK2X(),
	.CLK2X180(),

	.CLKDV(),
	.CLKFX(clk_dcm),
	.CLKFX180(),
	.LOCKED(locked),
	.CLKFB(),
	.CLKIN(clk50),
	.RST(1'b0),
	.PSEN(1'b0)
);
BUFG b1(
	.I(clk_dcm),
	.O(clk)
);

`ifndef AUTO_ON
reg btn1_r0;
reg btn1_r;
reg btn2_r0;
reg btn2_r;
reg btn2_r2;

wire debounce;

always @(posedge clk) begin
	if(debounce) begin
		btn1_r0 <= btn1;
		btn1_r <= btn1_r0;
		btn2_r0 <= btn2;
		btn2_r <= btn2_r0;
		btn2_r2 <= btn2_r;
	end
end

initial begin
	btn2_r0 <= 1'b1;
	btn2_r <= 1'b1;
	btn2_r2 <= 1'b1;
end

reg [19:0] debounce_r;
always @(posedge clk) debounce_r <= debounce_r + 20'd1;
assign debounce = &debounce_r;
`endif

reg ce_r;
reg [15:0] d_r;
reg write_r;
ICAP_SPARTAN6 icap(
	.BUSY(),
	.O(),
	.CE(ce_r),
	.CLK(clk),
	.I(d_r),
	.WRITE(write_r)
);

reg [15:0] d;
reg icap_en_n;

always @(posedge clk, negedge locked) begin
	if(~locked) begin
		d_r <= 16'hffff;
		ce_r <= 1'b1;
		write_r <= 1'b1;
	end else begin
		d_r[0] <= d[7];
		d_r[1] <= d[6];
		d_r[2] <= d[5];
		d_r[3] <= d[4];
		d_r[4] <= d[3];
		d_r[5] <= d[2];
		d_r[6] <= d[1];
		d_r[7] <= d[0];
		d_r[8] <= d[15];
		d_r[9] <= d[14];
		d_r[10] <= d[13];
		d_r[11] <= d[12];
		d_r[12] <= d[11];
		d_r[13] <= d[10];
		d_r[14] <= d[9];
		d_r[15] <= d[8];
		ce_r <= icap_en_n;
		write_r <= icap_en_n;
	end
end

parameter IDLE =		4'd0;
parameter DUMMY =		4'd1;
parameter SYNC1 =		4'd2;
parameter SYNC2 =		4'd3;
parameter GENERAL1_C =		4'd4;
parameter GENERAL1_D =		4'd5;
parameter GENERAL2_C =		4'd6;
parameter GENERAL2_D_RESCUE =	4'd7;
parameter GENERAL2_D_REGULAR =	4'd8;
parameter CMD =			4'd9;
parameter IPROG =		4'd10;
parameter NOP =			4'd11;
parameter LOOP =		4'd12;

reg [3:0] state;
reg [3:0] next_state;

initial state <= IDLE;

always @(posedge clk, negedge locked)
	if(~locked)
		state <= IDLE;
	else
		state <= next_state;

`ifndef AUTO_ON
reg rescue;
reg next_rescue;
always @(posedge clk, negedge locked)
	if(~locked)
		rescue <= 1'b0;
	else
		rescue <= next_rescue;
`endif

`ifdef AUTO_ON
/* HACK: for some reason, reconfiguring right away fails intermittently.
 * Work around this with a timer.
 */
reg [19:0] timer;
always @(posedge clk, negedge locked)
	if(~locked)
		timer <= 20'd0;
	else
		timer <= timer + 20'd1;
`endif

always @(*) begin
	d = 16'hxxxx;
	icap_en_n = 1'b1;

`ifndef AUTO_ON
	next_rescue = rescue;
`endif

	next_state = state;

	case(state)
		IDLE: begin
`ifdef AUTO_ON
			if(timer[19])
				next_state = DUMMY;
`else
			next_rescue = btn1_r;
			if(btn2_r & ~btn2_r2)
				next_state = DUMMY;
`endif
		end
		DUMMY: begin
			d = 16'hffff;
			icap_en_n = 1'b0;
			next_state = SYNC1;
		end
		SYNC1: begin
			d = 16'haa99;
			icap_en_n = 1'b0;
			next_state = SYNC2;
		end
		SYNC2: begin
			d = 16'h5566;
			icap_en_n = 1'b0;
			next_state = GENERAL1_C;
		end
		GENERAL1_C: begin
			d = 16'h3261;
			icap_en_n = 1'b0;
			next_state = GENERAL1_D;
		end
		GENERAL1_D: begin
			d = 16'h0000;
			icap_en_n = 1'b0;
			next_state = GENERAL2_C;
		end
		GENERAL2_C: begin
			d = 16'h3281;
			icap_en_n = 1'b0;
`ifdef AUTO_ON
			if(btn1)
`else
			if(rescue)
`endif
				next_state = GENERAL2_D_RESCUE;
			else
				next_state = GENERAL2_D_REGULAR;
		end
		GENERAL2_D_RESCUE: begin
			d = 16'h0005;
			icap_en_n = 1'b0;
			next_state = CMD;
		end
		GENERAL2_D_REGULAR: begin
			d = 16'h0037;
			icap_en_n = 1'b0;
			next_state = CMD;
		end
		CMD: begin
			d = 16'h30A1;
			icap_en_n = 1'b0;
			next_state = IPROG;
		end
		IPROG: begin
			d = 16'h000E;
			icap_en_n = 1'b0;
			next_state = NOP;
		end
		NOP: begin
			d = 16'h2000;
			icap_en_n = 1'b0;
			next_state = LOOP;
		end
		LOOP: next_state = LOOP;
	endcase
end


assign led1 = 1'b0;
assign led2 = 1'b0;

assign flash_ce_n = 1'b1;
assign flash_oe_n = 1'b1;
assign flash_we_n = 1'b1;
assign flash_rst_n = 1'b1;
assign sdram_clk_p = 1'b0;
assign sdram_clk_n = 1'b1;
assign vga_psave_n = 1'b0;
assign vga_clk = 1'b0;
assign mc_clk = 1'b0;
assign ac97_rst_n = 1'b0;
assign usba_oe_n = 1'b1;
assign usbb_oe_n = 1'b1;
assign phy_rst_n = 1'b0;
assign videoin_rst_n = 1'b0;
assign midi_tx = 1'b1;
assign dmxa_de = 1'b0;
assign dmxb_de = 1'b0;

endmodule
