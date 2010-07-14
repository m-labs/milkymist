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
	
	output reg usb_discon,
	output txdp,
	output txdn,
	output txoe_n,
	input rxd,
	input rxdp,
	input rxdn,

	input [7:0] DataOut_i,
	input TxValid_i,
	output TxReady_o,
	output [7:0] DataIn_o,
	output RxValid_o,
	output RxActive_o,
	output RxError_o,
	output [1:0] LineState_o
);

wire fs_ce;

softusb_tx_phy tx_phy(
	.usb_clk(usb_clk),
	.usb_rst(usb_rst),

	.fs_ce(fs_ce),

	.txdp(txdp),
	.txdn(txdn),
	.txoe_n(txoe_n),

	.DataOut_i(DataOut_i),
	.TxValid_i(TxValid_i),
	.TxReady_o(TxReady_o)
);

softusb_rx_phy rx_phy(
	.usb_clk(usb_clk),
	.usb_rst(usb_rst),
	.fs_ce(fs_ce),

	.rxd(rxd),
	.rxdp(rxdp),
	.rxdn(rxdn),

	.DataIn_o(DataIn_o),
	.RxValid_o(RxValid_o),
	.RxActive_o(RxActive_o),
	.RxError_o(RxError_o),
	.RxEn_i(txoe_n),
	.LineState(LineState_o)
);

/* Generate an USB Disconnect if we see SE0 for at least 2.5uS */

reg [4:0] usb_discon_cnt;
always @(posedge usb_clk) begin
	if(usb_rst) begin
		usb_discon_cnt <= 5'h0;
		usb_discon <= 1'b0;
	end else begin
		if(LineState_o != 2'h0)
			usb_discon_cnt <= 5'h0;
		else if(!usb_discon && fs_ce)
			usb_discon_cnt <= usb_discon_cnt + 5'h1;
		usb_discon <= (usb_discon_cnt == 5'h1f);
	end
end

endmodule
