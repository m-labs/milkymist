/*
 * Milkymist SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
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

module ac97_deframer(
	input sys_clk,
	input sys_rst,
	
	/* to transceiver */
	input up_stb,
	output up_ack,
	input up_sync,
	input up_data,
	
	/* frame data */
	input en,
	output reg next_frame,
	output reg frame_valid,
	output reg addr_valid,
	output reg [19:0] addr,
	output reg data_valid,
	output reg [19:0] data,
	output reg pcmleft_valid,
	output reg [19:0] pcmleft,
	output reg pcmright_valid,
	output reg [19:0] pcmright
);

reg [7:0] bitcounter;
reg sync_old;
always @(posedge sys_clk) begin
	if(sys_rst) begin
		bitcounter <= 8'd253;
		next_frame <= 1'b0;
		sync_old <= 1'b0;
	end else begin
		if(en)
			next_frame <= 1'b0;
		if(up_stb & en) begin
			case(bitcounter)
				8'd0: frame_valid <= up_data;		// Frame valid
				8'd1: addr_valid <= up_data;		// Slot 1 valid
				8'd2: data_valid <= up_data;		// Slot 2 valid
				8'd3: pcmleft_valid <= up_data;		// Slot 3 valid
				8'd4: pcmright_valid <= up_data;	// Slot 4 valid
	
				8'd16: addr[19] <= up_data;
				8'd17: addr[18] <= up_data;
				8'd18: addr[17] <= up_data;
				8'd19: addr[16] <= up_data;
				8'd20: addr[15] <= up_data;
				8'd21: addr[14] <= up_data;
				8'd22: addr[13] <= up_data;
				8'd23: addr[12] <= up_data;
				8'd24: addr[11] <= up_data;
				8'd25: addr[10] <= up_data;
				8'd26: addr[9] <= up_data;
				8'd27: addr[8] <= up_data;
				8'd28: addr[7] <= up_data;
				8'd29: addr[6] <= up_data;
				8'd30: addr[5] <= up_data;
				8'd31: addr[4] <= up_data;
				8'd32: addr[3] <= up_data;
				8'd33: addr[2] <= up_data;
				8'd34: addr[1] <= up_data;
				8'd35: addr[0] <= up_data;
				
				8'd36: data[19] <= up_data;
				8'd37: data[18] <= up_data;
				8'd38: data[17] <= up_data;
				8'd39: data[16] <= up_data;
				8'd40: data[15] <= up_data;
				8'd41: data[14] <= up_data;
				8'd42: data[13] <= up_data;
				8'd43: data[12] <= up_data;
				8'd44: data[11] <= up_data;
				8'd45: data[10] <= up_data;
				8'd46: data[9] <= up_data;
				8'd47: data[8] <= up_data;
				8'd48: data[7] <= up_data;
				8'd49: data[6] <= up_data;
				8'd50: data[5] <= up_data;
				8'd51: data[4] <= up_data;
				8'd52: data[3] <= up_data;
				8'd53: data[2] <= up_data;
				8'd54: data[1] <= up_data;
				8'd55: data[0] <= up_data;
				
				8'd56: pcmleft[19] <= up_data;
				8'd57: pcmleft[18] <= up_data;
				8'd58: pcmleft[17] <= up_data;
				8'd59: pcmleft[16] <= up_data;
				8'd60: pcmleft[15] <= up_data;
				8'd61: pcmleft[14] <= up_data;
				8'd62: pcmleft[13] <= up_data;
				8'd63: pcmleft[12] <= up_data;
				8'd64: pcmleft[11] <= up_data;
				8'd65: pcmleft[10] <= up_data;
				8'd66: pcmleft[9] <= up_data;
				8'd67: pcmleft[8] <= up_data;
				8'd68: pcmleft[7] <= up_data;
				8'd69: pcmleft[6] <= up_data;
				8'd70: pcmleft[5] <= up_data;
				8'd71: pcmleft[4] <= up_data;
				8'd72: pcmleft[3] <= up_data;
				8'd73: pcmleft[2] <= up_data;
				8'd74: pcmleft[1] <= up_data;
				8'd75: pcmleft[0] <= up_data;
				
				8'd76: pcmright[19] <= up_data;
				8'd77: pcmright[18] <= up_data;
				8'd78: pcmright[17] <= up_data;
				8'd79: pcmright[16] <= up_data;
				8'd80: pcmright[15] <= up_data;
				8'd81: pcmright[14] <= up_data;
				8'd82: pcmright[13] <= up_data;
				8'd83: pcmright[12] <= up_data;
				8'd84: pcmright[11] <= up_data;
				8'd85: pcmright[10] <= up_data;
				8'd86: pcmright[9] <= up_data;
				8'd87: pcmright[8] <= up_data;
				8'd88: pcmright[7] <= up_data;
				8'd89: pcmright[6] <= up_data;
				8'd90: pcmright[5] <= up_data;
				8'd91: pcmright[4] <= up_data;
				8'd92: pcmright[3] <= up_data;
				8'd93: pcmright[2] <= up_data;
				8'd94: pcmright[1] <= up_data;
				8'd95: pcmright[0] <= up_data;
			endcase
			
			if(bitcounter == 8'd95)
				next_frame <= 1'b1;
			
			sync_old <= up_sync;
			if(up_sync & ~sync_old)
				bitcounter <= 8'd0;
			else
				bitcounter <= bitcounter + 8'd1;
		end
	end
end

assign up_ack = en;

endmodule
