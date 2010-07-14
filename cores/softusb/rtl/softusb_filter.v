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

module softusb_filter(
	input usb_clk,

	input rxd,
	input rxdp,
	input rxdn,

	output reg rxd_s,
	output reg rxdp_s,
	output reg rxdn_s
);

/*
 * First synchronize to the local system clock to
 * avoid metastability outside the sync block (*_s0).
 * Then make sure we see the signal for at least two
 * clock cycles stable to avoid glitches and noise
 */

reg rxd_s0, rxd_s1;
reg rxdp_s0, rxdp_s1, rxdp_s_r;
reg rxdn_s0, rxdn_s1, rxdn_s_r;

always @(posedge usb_clk) rxd_s0  <= rxd;
always @(posedge usb_clk) rxd_s1  <= rxd_s0;
always @(posedge usb_clk) // Avoid detecting Line Glitches and noise
	if(rxd_s0 && rxd_s1)
		rxd_s <= 1'b1;
	else if(!rxd_s0 && !rxd_s1)
		rxd_s <= 1'b0;

always @(posedge usb_clk) rxdp_s0  <= rxdp;
always @(posedge usb_clk) rxdp_s1  <= rxdp_s0;
always @(posedge usb_clk) rxdp_s_r <= rxdp_s0 & rxdp_s1;
always @(posedge usb_clk) rxdp_s   <= (rxdp_s0 & rxdp_s1) | rxdp_s_r; // Avoid detecting Line Glitches and noise

always @(posedge usb_clk) rxdn_s0  <= rxdn;
always @(posedge usb_clk) rxdn_s1  <= rxdn_s0;
always @(posedge usb_clk) rxdn_s_r <= rxdn_s0 & rxdn_s1;
always @(posedge usb_clk) rxdn_s   <= (rxdn_s0 & rxdn_s1) | rxdn_s_r; // Avoid detecting Line Glitches and noise

endmodule
