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

module softusb_tx_phy(
	input usb_clk,
	input usb_rst,

	input fs_ce,

	output reg txdp,
	output reg txdn,
	output reg txoe,
	
	input [7:0] utmi_data_out,
	input utmi_tx_valid,
	output reg utmi_tx_ready,

	input generate_reset
);

parameter	IDLE	= 3'd0,
		SOP	= 3'h1,
		DATA	= 3'h2,
		EOP1	= 3'h3,
		EOP2	= 3'h4,
		WAIT	= 3'h5;

reg [2:0] state, next_state;
reg ld_sop_d;
reg ld_data_d;
reg ld_eop_d;
reg tx_ip;
reg tx_ip_sync;
reg [2:0] bit_cnt;
reg [7:0] hold_reg;
reg [7:0] hold_reg_d;

reg sd_raw_o;
wire hold;
reg data_done;
reg sft_done;
reg sft_done_r;
wire sft_done_e;
reg ld_data;
wire eop_done;
reg [2:0] one_cnt;
wire stuff;
reg sd_bs_o;
reg sd_nrzi_o;
reg append_eop;
reg append_eop_sync1;
reg append_eop_sync2;
reg append_eop_sync3;
reg append_eop_sync4;
reg txoe_r1, txoe_r2;

always @(posedge usb_clk) ld_data <= ld_data_d;

/* Transmit in progress indicator */

always @(posedge usb_clk)
	if(usb_rst)
		tx_ip <= 1'b0;
	else if(ld_sop_d)
		tx_ip <= 1'b1;
	else if(eop_done)
		tx_ip <= 1'b0;

always @(posedge usb_clk)
	if(usb_rst)
		tx_ip_sync <= 1'b0;
	else if(fs_ce)
		tx_ip_sync <= tx_ip;

/*
 * data_done helps us to catch cases where TxValid drops due to
 * packet end and then gets re-asserted as a new packet starts.
 * We might not see this because we are still transmitting.
 * data_done should solve those cases ...
 */
always @(posedge usb_clk)
	if(usb_rst)
		data_done <= 1'b0;
	else if(utmi_tx_valid && ! tx_ip)
		data_done <= 1'b1;
	else if(!utmi_tx_valid)
		data_done <= 1'b0;

/* Shift Register */

always @(posedge usb_clk)
	if(usb_rst)
		bit_cnt <= 3'h0;
	else if(!tx_ip_sync)
		bit_cnt <= 3'h0;
	else if(fs_ce && !hold)
		bit_cnt <= bit_cnt + 3'h1;

assign hold = stuff;

always @(posedge usb_clk) begin
	if(!tx_ip_sync)
		sd_raw_o <= 1'b0;
	else begin
		case(bit_cnt)
			3'h0: sd_raw_o <= hold_reg_d[0];
			3'h1: sd_raw_o <= hold_reg_d[1];
			3'h2: sd_raw_o <= hold_reg_d[2];
			3'h3: sd_raw_o <= hold_reg_d[3];
			3'h4: sd_raw_o <= hold_reg_d[4];
			3'h5: sd_raw_o <= hold_reg_d[5];
			3'h6: sd_raw_o <= hold_reg_d[6];
			3'h7: sd_raw_o <= hold_reg_d[7];
		endcase
	end
end

always @(posedge usb_clk)
	sft_done <= !hold & (bit_cnt == 3'h7);

always @(posedge usb_clk)
	sft_done_r <= sft_done;

assign sft_done_e = sft_done & !sft_done_r;

/* Out Data Hold Register */
always @(posedge usb_clk)
	if(ld_sop_d)
		hold_reg <= 8'h80;
	else if(ld_data) begin
		hold_reg <= utmi_data_out;
		$display("%t USB TX: %x", $time, utmi_data_out);
	end

always @(posedge usb_clk) hold_reg_d <= hold_reg;

/* Bit Stuffer */

always @(posedge usb_clk)
	if(usb_rst)
		one_cnt <= 3'h0;
	else if(!tx_ip_sync)
		one_cnt <= 3'h0;
	else if(fs_ce) begin
		if(!sd_raw_o || stuff)
			one_cnt <= 3'h0;
		else
			one_cnt <= one_cnt + 3'h1;
	end

assign stuff = (one_cnt == 3'h6);

always @(posedge usb_clk)
	if(usb_rst)
		sd_bs_o <= 1'h0;
	else if(fs_ce)
		sd_bs_o <= !tx_ip_sync ? 1'b0 : (stuff ? 1'b0 : sd_raw_o);

/* NRZI Encoder */

always @(posedge usb_clk)
	if(usb_rst)
		sd_nrzi_o <= 1'b1;
	else if(!tx_ip_sync || !txoe_r1)
		sd_nrzi_o <= 1'b1;
	else if(fs_ce)
		sd_nrzi_o <= sd_bs_o ? sd_nrzi_o : ~sd_nrzi_o;

/* EOP append logic */

always @(posedge usb_clk)
	if(usb_rst)
		append_eop <= 1'b0;
	else if(ld_eop_d)
		append_eop <= 1'b1;
	else if(append_eop_sync2)
		append_eop <= 1'b0;

always @(posedge usb_clk)
	if(usb_rst)
		append_eop_sync1 <= 1'b0;
	else if(fs_ce)
		append_eop_sync1 <= append_eop;

always @(posedge usb_clk)
	if(usb_rst)
		append_eop_sync2 <= 1'b0;
	else if(fs_ce)
		append_eop_sync2 <= append_eop_sync1;

always @(posedge usb_clk)
	if(usb_rst)
		append_eop_sync3 <= 1'b0;
	else if(fs_ce)
		append_eop_sync3 <= append_eop_sync2 |
			(append_eop_sync3 & !append_eop_sync4); // Make sure always 2 bit wide

always @(posedge usb_clk)
	if(usb_rst)
		append_eop_sync4 <= 1'b0;
	else if(fs_ce)
		append_eop_sync4 <= append_eop_sync3;

assign eop_done = append_eop_sync3;

/* Output Enable Logic */

always @(posedge usb_clk)
	if(usb_rst)
		txoe_r1 <= 1'b0;
	else if(fs_ce)
		txoe_r1 <= tx_ip_sync;

always @(posedge usb_clk)
	if(usb_rst)
		txoe_r2 <= 1'b0;
	else if(fs_ce)
		txoe_r2 <= txoe_r1;

always @(posedge usb_clk)
	if(usb_rst)
		txoe <= 1'b0;
	else if(fs_ce)
		txoe <= txoe_r1 | txoe_r2 | generate_reset;

/* Output Registers */

always @(posedge usb_clk)
	if(usb_rst)
		txdp <= 1'b1;
	else if(generate_reset)
		txdp <= 1'b0;
	else if(fs_ce)
		txdp <= !append_eop_sync3 &  sd_nrzi_o;

always @(posedge usb_clk)
	if(usb_rst)
		txdn <= 1'b0;
	else if(generate_reset)
		txdn <= 1'b0;
	else if(fs_ce)
		txdn <= !append_eop_sync3 & ~sd_nrzi_o;

/* Tx State machine */

always @(posedge usb_clk)
	if(usb_rst)
		state <= IDLE;
	else
		state <= next_state;

always @(*) begin
	next_state = state;
	utmi_tx_ready = 1'b0;

	ld_sop_d = 1'b0;
	ld_data_d = 1'b0;
	ld_eop_d = 1'b0;

	case(state)
		IDLE: if(utmi_tx_valid) begin
				ld_sop_d = 1'b1;
				next_state = SOP;
			end
		SOP: if(sft_done_e) begin
				utmi_tx_ready = 1'b1;
				ld_data_d = 1'b1;
				next_state = DATA;
			end
		DATA: begin
			if(!data_done && sft_done_e) begin
				ld_eop_d = 1'b1;
				next_state = EOP1;
			end
			if(data_done && sft_done_e) begin
				utmi_tx_ready = 1'b1;
				ld_data_d = 1'b1;
			end
		end
		EOP1: if(eop_done)
			next_state = EOP2;
		EOP2: if(!eop_done && fs_ce)
			next_state = WAIT;
		WAIT: if(fs_ce)
			next_state = IDLE;
	endcase
end

endmodule

