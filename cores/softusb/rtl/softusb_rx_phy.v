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

module softusb_rx_phy(
	input usb_clk,
	input usb_rst,
	
	output reg fs_ce,
	
	input rxd_s,
	input rxdp_s,
	input rxdn_s,
	
	output [7:0] utmi_data_in,
	output utmi_rx_valid,
	output utmi_rx_active,
	output utmi_rx_error,
	input utmi_rx_en
);

reg synced_d;
wire k, j, se0;
reg rxd_r;
reg rx_en;
reg rx_active;
reg [2:0] bit_cnt;
reg rx_valid1, rx_valid;
reg shift_en;
reg sd_r;
reg sd_nrzi;
reg [7:0] hold_reg;
wire drop_bit; // Indicates a stuffed bit
reg [2:0] one_cnt;

reg [1:0] dpll_state, dpll_next_state;
reg fs_ce_d;
wire change;
wire lock_en;
reg [2:0] fs_state, fs_next_state;
reg rx_valid_r;
reg sync_err_d, sync_err;
reg bit_stuff_err;
reg se0_r, byte_err;
reg se0_s;

assign utmi_rx_active = rx_active;
assign utmi_rx_valid = rx_valid;
assign utmi_rx_error = sync_err | bit_stuff_err | byte_err;
assign utmi_data_in = hold_reg;

always @(posedge usb_clk) rx_en <= utmi_rx_en;
always @(posedge usb_clk) sync_err <= !rx_active & sync_err_d;

assign k = !rxdp_s &  rxdn_s;
assign j =  rxdp_s & !rxdn_s;
assign se0 = !rxdp_s & !rxdn_s;

always @(posedge usb_clk)
	if(fs_ce)
		se0_s <= se0;

/* DPLL */

/*
 * This design uses a clock enable to do 12Mhz timing and not a
 * real 12Mhz clock. Everything always runs at 48Mhz. We want to
 * make sure however, that the clock enable is always exactly in
 * the middle between two virtual 12Mhz rising edges.
 * We monitor rxdp and rxdn for any changes and do the appropiate
 * adjustments.
 * In addition to the locking done in the dpll FSM, we adjust the
 * final latch enable to compensate for various sync registers ...
 */

/* Allow lockinf only when we are receiving */
assign lock_en = rx_en;

always @(posedge usb_clk) rxd_r <= rxd_s;

/* Edge detector */
assign change = rxd_r != rxd_s;

/* DPLL FSM */
always @(posedge usb_clk)
	if(usb_rst)
		dpll_state <= 2'h1;
	else
		dpll_state <= dpll_next_state;

always @(*) begin
	fs_ce_d = 1'b0;
	case(dpll_state)
		2'h0:
			if(lock_en && change)
				dpll_next_state = 2'h0;
			else
				dpll_next_state = 2'h1;
		2'h1: begin
			fs_ce_d = 1'b1;
			if(lock_en && change)
				dpll_next_state = 2'h3;
			else
				dpll_next_state = 2'h2;
		end
		2'h2:
			if(lock_en && change)
				dpll_next_state = 2'h0;
			else
				dpll_next_state = 2'h3;
		2'h3:
			if(lock_en && change)
				dpll_next_state = 2'h0;
			else
				dpll_next_state = 2'h0;
	endcase
end

/*
 * Compensate for sync registers at the input - allign full speed
 * clock enable to be in the middle between two bit changes ...
 */
reg fs_ce_r1, fs_ce_r2;

always @(posedge usb_clk) fs_ce_r1 <= fs_ce_d;
always @(posedge usb_clk) fs_ce_r2 <= fs_ce_r1;
always @(posedge usb_clk) fs_ce <= fs_ce_r2;


/* Find Sync Pattern FSM */

parameter	FS_IDLE	= 3'h0,
		K1	= 3'h1,
		J1	= 3'h2,
		K2	= 3'h3,
		J2	= 3'h4,
		K3	= 3'h5,
		J3	= 3'h6,
		K4	= 3'h7;

always @(posedge usb_clk)
	if(usb_rst)
		fs_state <= FS_IDLE;
	else
		fs_state <= fs_next_state;

always @(*) begin
	synced_d = 1'b0;
	sync_err_d = 1'b0;
	fs_next_state = fs_state;
	if(fs_ce && !rx_active && !se0 && !se0_s) begin
		case(fs_state)
			FS_IDLE: begin
				if(k && rx_en)	fs_next_state = K1;
			end
			K1: begin
				if(j && rx_en)
					fs_next_state = J1;
				else begin
					sync_err_d = 1'b1;
					fs_next_state = FS_IDLE;
				end
			end
			J1: begin
				if(k && rx_en)
					fs_next_state = K2;
				else begin
					sync_err_d = 1'b1;
					fs_next_state = FS_IDLE;
				end
			end
			K2: begin
				if(j && rx_en)
					fs_next_state = J2;
				else begin
					sync_err_d = 1'b1;
					fs_next_state = FS_IDLE;
				end
			end
			J2: begin
				if(k && rx_en)
					fs_next_state = K3;
				else begin
					sync_err_d = 1'b1;
					fs_next_state = FS_IDLE;
				end
			end
			K3: begin
				if(j && rx_en)
					fs_next_state = J3;
				else if(k && rx_en) begin
					fs_next_state = FS_IDLE;	// Allow missing fiusb_rst K-J
					synced_d = 1'b1;
				end else begin
					sync_err_d = 1'b1;
					fs_next_state = FS_IDLE;
				end
			end
			J3: begin
				if(k && rx_en)
					fs_next_state = K4;
				else begin
					sync_err_d = 1'b1;
					fs_next_state = FS_IDLE;
				end
			end
			K4: begin
				if(k)
					synced_d = 1'b1;
				fs_next_state = FS_IDLE;
			end
		endcase
	end
end

/* Generate RxActive */

always @(posedge usb_clk)
	if(usb_rst)
		rx_active <= 1'b0;
	else if(synced_d && rx_en)
		rx_active <= 1'b1;
	else if(se0 && rx_valid_r)
		rx_active <= 1'b0;

always @(posedge usb_clk)
	if(rx_valid)
		rx_valid_r <= 1'b1;
	else if(fs_ce)
		rx_valid_r <= 1'b0;

/* NRZI Decoder */

always @(posedge usb_clk)
	if(fs_ce)
		sd_r <= rxd_s;

always @(posedge usb_clk)
	if(usb_rst)
		sd_nrzi <= 1'b0;
	else if(!rx_active)
		sd_nrzi <= 1'b1;
	else if(rx_active && fs_ce)
		sd_nrzi <= !(rxd_s ^ sd_r);

/* Bit Stuff Detect */

always @(posedge usb_clk)
	if(usb_rst)
		one_cnt <= 3'h0;
	else if(!shift_en)
		one_cnt <= 3'h0;
	else if(fs_ce) begin
		if(!sd_nrzi || drop_bit)
			one_cnt <= 3'h0;
		else
			one_cnt <= one_cnt + 3'h1;
	end

assign drop_bit = (one_cnt == 3'h6);

always @(posedge usb_clk)
	bit_stuff_err <= drop_bit & sd_nrzi & fs_ce & !se0 & rx_active; // Bit Stuff Error

/* Serial => Parallel converter */

always @(posedge usb_clk)
	if(fs_ce)
		shift_en <= synced_d | rx_active;

always @(posedge usb_clk)
	if(fs_ce && shift_en && !drop_bit)
		hold_reg <= {sd_nrzi, hold_reg[7:1]};

/* Generate RxValid */

always @(posedge usb_clk)
	if(usb_rst)
		bit_cnt <= 3'b0;
	else if(!shift_en)
		bit_cnt <= 3'h0;
	else if(fs_ce && !drop_bit)
		bit_cnt <= bit_cnt + 3'h1;

always @(posedge usb_clk)
	if(usb_rst)
		rx_valid1 <= 1'b0;
	else if(fs_ce && !drop_bit && (bit_cnt == 3'h7))
		rx_valid1 <= 1'b1;
	else if(rx_valid1 && fs_ce && !drop_bit)
		rx_valid1 <= 1'b0;

always @(posedge usb_clk)
	rx_valid <= !drop_bit & rx_valid1 & fs_ce;

always @(posedge usb_clk)
	se0_r <= se0;

always @(posedge usb_clk)
	byte_err <= se0 & !se0_r & (|bit_cnt[2:1]) & rx_active;

endmodule
