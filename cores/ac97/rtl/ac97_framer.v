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

module ac97_framer(
	input sys_clk,
	input sys_rst,
	
	/* to transceiver */
	input down_ready,
	output down_stb,
	output reg down_sync,
	output reg down_data,
	
	/* frame data */
	input en,
	output reg next_frame,
	input addr_valid,
	input [19:0] addr,
	input data_valid,
	input [19:0] data,
	input pcmleft_valid,
	input [19:0] pcmleft,
	input pcmright_valid,
	input [19:0] pcmright
);

reg [7:0] bitcounter;

reg slot_bit;
always @(*) begin
	case(bitcounter)
		8'd16: slot_bit = addr[19];
		8'd17: slot_bit = addr[18];
		8'd18: slot_bit = addr[17];
		8'd19: slot_bit = addr[16];
		8'd20: slot_bit = addr[15];
		8'd21: slot_bit = addr[14];
		8'd22: slot_bit = addr[13];
		8'd23: slot_bit = addr[12];
		8'd24: slot_bit = addr[11];
		8'd25: slot_bit = addr[10];
		8'd26: slot_bit = addr[9];
		8'd27: slot_bit = addr[8];
		8'd28: slot_bit = addr[7];
		8'd29: slot_bit = addr[6];
		8'd30: slot_bit = addr[5];
		8'd31: slot_bit = addr[4];
		8'd32: slot_bit = addr[3];
		8'd33: slot_bit = addr[2];
		8'd34: slot_bit = addr[1];
		8'd35: slot_bit = addr[0];
		
		8'd36: slot_bit = data[19];
		8'd37: slot_bit = data[18];
		8'd38: slot_bit = data[17];
		8'd39: slot_bit = data[16];
		8'd40: slot_bit = data[15];
		8'd41: slot_bit = data[14];
		8'd42: slot_bit = data[13];
		8'd43: slot_bit = data[12];
		8'd44: slot_bit = data[11];
		8'd45: slot_bit = data[10];
		8'd46: slot_bit = data[9];
		8'd47: slot_bit = data[8];
		8'd48: slot_bit = data[7];
		8'd49: slot_bit = data[6];
		8'd50: slot_bit = data[5];
		8'd51: slot_bit = data[4];
		8'd52: slot_bit = data[3];
		8'd53: slot_bit = data[2];
		8'd54: slot_bit = data[1];
		8'd55: slot_bit = data[0];
		
		8'd56: slot_bit = pcmleft[19];
		8'd57: slot_bit = pcmleft[18];
		8'd58: slot_bit = pcmleft[17];
		8'd59: slot_bit = pcmleft[16];
		8'd60: slot_bit = pcmleft[15];
		8'd61: slot_bit = pcmleft[14];
		8'd62: slot_bit = pcmleft[13];
		8'd63: slot_bit = pcmleft[12];
		8'd64: slot_bit = pcmleft[11];
		8'd65: slot_bit = pcmleft[10];
		8'd66: slot_bit = pcmleft[9];
		8'd67: slot_bit = pcmleft[8];
		8'd68: slot_bit = pcmleft[7];
		8'd69: slot_bit = pcmleft[6];
		8'd70: slot_bit = pcmleft[5];
		8'd71: slot_bit = pcmleft[4];
		8'd72: slot_bit = pcmleft[3];
		8'd73: slot_bit = pcmleft[2];
		8'd74: slot_bit = pcmleft[1];
		8'd75: slot_bit = pcmleft[0];
		
		8'd76: slot_bit = pcmright[19];
		8'd77: slot_bit = pcmright[18];
		8'd78: slot_bit = pcmright[17];
		8'd79: slot_bit = pcmright[16];
		8'd80: slot_bit = pcmright[15];
		8'd81: slot_bit = pcmright[14];
		8'd82: slot_bit = pcmright[13];
		8'd83: slot_bit = pcmright[12];
		8'd84: slot_bit = pcmright[11];
		8'd85: slot_bit = pcmright[10];
		8'd86: slot_bit = pcmright[9];
		8'd87: slot_bit = pcmright[8];
		8'd88: slot_bit = pcmright[7];
		8'd89: slot_bit = pcmright[6];
		8'd90: slot_bit = pcmright[5];
		8'd91: slot_bit = pcmright[4];
		8'd92: slot_bit = pcmright[3];
		8'd93: slot_bit = pcmright[2];
		8'd94: slot_bit = pcmright[1];
		8'd95: slot_bit = pcmright[0];
		default: slot_bit = 1'bx;
	endcase
end

reg in_slot;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		bitcounter <= 8'd0;
		down_sync <= 1'b0;
		down_data <= 1'b0;
		in_slot <= 1'b0;
	end else begin
		if(en)
			next_frame <= 1'b0;
		if(down_ready & en) begin
			if(bitcounter == 8'd255)
				next_frame <= 1'b1;
			
			if(bitcounter == 8'd255)
				down_sync <= 1'b1;
			if(bitcounter == 8'd15)
				down_sync <= 1'b0;
			
			if(bitcounter == 8'd15)
				in_slot <= 1'b1;
			if(bitcounter == 8'd95)
				in_slot <= 1'b0;
			
			case({down_sync, in_slot})
				2'b10: begin
					/* Tag */
					case(bitcounter[3:0])
						4'h0: down_data <= 1'b1;		// Frame valid
						4'h1: down_data <= addr_valid;		// Slot 1 valid
						4'h2: down_data <= data_valid;		// Slot 2 valid
						4'h3: down_data <= pcmleft_valid;	// Slot 3 valid
						4'h4: down_data <= pcmright_valid;	// Slot 4 valid
						default: down_data <= 1'b0;
					endcase
					//$display("PCMRIGHT_V: %b", pcmright_valid);
				end
				2'b01:
					/* Active slot */
					down_data <= slot_bit;
				default: down_data <= 1'b0;
			endcase
			
			bitcounter <= bitcounter + 8'd1;
		end
	end
end

assign down_stb = en;

endmodule
