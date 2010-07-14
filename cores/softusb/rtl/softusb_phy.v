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

/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2000-2002 Rudolf Usselmann                    ////
////                         www.asics.ws                        ////
////                         rudi@asics.ws                       ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

module softusb_phy(
	input usb_clk,
	input usb_rst,

	output usba_spd,
	output usba_oe_n,
	input usba_rcv,
	inout usba_vp,
	inout usba_vm,

	output usbb_spd,
	output usbb_oe_n,
	input usbb_rcv,
	inout usbb_vp,
	inout usbb_vm,

	output reg usba_discon,
	output reg usbb_discon,

	output [1:0] utmi_line_state_a,
	output [1:0] utmi_line_state_b,

	input port_sel_rx,
	input [1:0] port_sel_tx,

	input [7:0] utmi_data_out,
	input utmi_tx_valid,
	output utmi_tx_ready,
	output [7:0] utmi_data_in,
	output utmi_rx_valid,
	output utmi_rx_active,
	output utmi_rx_error
);

/* RX synchronizers and filters */

wire rxd_s_a;
wire rxdp_s_a;
wire rxdn_s_a;
softusb_filter filter_a(
	.usb_clk(usb_clk),

	.rxd(usba_rcv),
	.rxdp(usba_vp),
	.rxdn(usba_vm),

	.rxd_s(rxd_s_a),
	.rxdp_s(rxdp_s_a),
	.rxdn_s(rxdn_s_a)
);
assign utmi_line_state_a = {rxdn_s_a, rxdp_s_a};

wire rxd_s_b;
wire rxdp_s_b;
wire rxdn_s_b;
softusb_filter filter_b(
	.usb_clk(usb_clk),

	.rxd(usbb_rcv),
	.rxdp(usbb_vp),
	.rxdn(usbb_vm),

	.rxd_s(rxd_s_b),
	.rxdp_s(rxdp_s_b),
	.rxdn_s(rxdn_s_b)
);
assign utmi_line_state_b = {rxdn_s_b, rxdp_s_b};

/* TX section */

wire fs_ce;
wire txdp;
wire txdn;
wire txoe;

softusb_tx_phy tx_phy(
	.usb_clk(usb_clk),
	.usb_rst(usb_rst),

	.fs_ce(fs_ce),

	.txdp(txdp),
	.txdn(txdn),
	.txoe(txoe),

	.utmi_data_out(utmi_data_out),
	.utmi_tx_valid(utmi_tx_valid),
	.utmi_tx_ready(utmi_tx_ready)
);

/* RX section */

softusb_rx_phy rx_phy(
	.usb_clk(usb_clk),
	.usb_rst(usb_rst),
	.fs_ce(fs_ce),

	.rxd_s(port_sel_rx ? rxd_s_b : rxd_s_a),
	.rxdp_s(port_sel_rx ? rxdp_s_b : rxdp_s_a),
	.rxdn_s(port_sel_rx ? rxdn_s_b : rxdn_s_a),

	.utmi_data_in(utmi_data_in),
	.utmi_rx_valid(utmi_rx_valid),
	.utmi_rx_active(utmi_rx_active),
	.utmi_rx_error(utmi_rx_error),
	.utmi_rx_en(~txoe)
);

/* Tri-state enables and drivers */

wire txoe_a = txoe & port_sel_tx[0];
wire txoe_b = txoe & port_sel_tx[1];

assign usba_oe_n = ~txoe_a;
assign usba_vp = txoe_a ? txdp : 1'bz;
assign usba_vm = txoe_a ? txdn : 1'bz;
assign usbb_oe_n = ~txoe_b;
assign usbb_vp = txoe_b ? txdp : 1'bz;
assign usbb_vm = txoe_b ? txdn : 1'bz;

/* Generate an USB Disconnect if we see SE0 for at least 2.5uS */

reg [4:0] usba_discon_cnt;
always @(posedge usb_clk) begin
	if(usb_rst) begin
		usba_discon_cnt <= 5'h0;
		usba_discon <= 1'b0;
	end else begin
		if(utmi_line_state_a != 2'h0)
			usba_discon_cnt <= 5'h0;
		else if(!usba_discon && fs_ce)
			usba_discon_cnt <= usba_discon_cnt + 5'h1;
		usba_discon <= (usba_discon_cnt == 5'h1f);
	end
end

reg [4:0] usbb_discon_cnt;
always @(posedge usb_clk) begin
	if(usb_rst) begin
		usbb_discon_cnt <= 5'h0;
		usbb_discon <= 1'b0;
	end else begin
		if(utmi_line_state_b != 2'h0)
			usbb_discon_cnt <= 5'h0;
		else if(!usbb_discon && fs_ce)
			usbb_discon_cnt <= usbb_discon_cnt + 5'h1;
		usbb_discon <= (usbb_discon_cnt == 5'h1f);
	end
end

/* FIXME: full speed only for now */
assign usba_spd = 1'b1;
assign usbb_spd = 1'b1;

endmodule
