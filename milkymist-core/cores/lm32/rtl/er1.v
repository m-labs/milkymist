// =============================================================================
//                           COPYRIGHT NOTICE
// Copyright 2006 (c) Lattice Semiconductor Corporation
// ALL RIGHTS RESERVED
// This confidential and proprietary software may be used only as authorised by
// a licensing agreement from Lattice Semiconductor Corporation.
// The entire notice above must be reproduced on all authorized copies and
// copies may only be made to the extent permitted by a licensing agreement from
// Lattice Semiconductor Corporation.
//
// Lattice Semiconductor Corporation        TEL : 1-800-Lattice (USA and Canada)
// 5555 NE Moore Court                            408-826-6000 (other locations)
// Hillsboro, OR 97124                     web  : http://www.latticesemi.com/
// U.S.A                                   email: techsupport@latticesemi.com
// =============================================================================/
//                         FILE DETAILS
// Project          : LatticeMico32
// File             : er1.v
// Description:
//    This module is where the ER1 register implemented. ER1 and ER2 registers
//    can be registers implemented in Lattice FPGAs using normal FPGA's
//    programmable logic resources.  Once they are implemented, they can be
//    accessed as if they are JTAG data registers through the FPGA JTAG port.
//    In order to accessing these registers, JTAG instructions ER1(0x32) or
//    ER2(0x38) needs to be written to the JTAG IR register for enabling the
//    ER1/ER2 accessing logic.  The ER1 or ER2 accessing logic can only be
//    enabled one at a time.  Once they are enabled, they will be disabled if
//    another JTAG instruction is written into the JTAG instruction register.
//    The registers allow dynamically accessing the FPGA internal information
//    even when the device is running.  Therefore, they are very useful for some
//    of the IP cores.  In order to let ER1/ER2 registers shared by multiple IP
//    cores or other designs, there is a ER1/ER2 structure patterned by Lattice.
//    The ER1/ER2 structure allows only one ER1 register but more than one ER2
//    registers in an FPGA device.  Please refer to the related document for
//    this patterned ER1/ER2 structure.
// Dependencies     : None
// Version          : 6.0.14
//                  : Initial Version
// Version          : 7.0SP2, 3.0
//                  : No Change
// Version          : 3.1
//                  : No Change
// =============================================================================
module ER1 (input  JTCK,
	    input  JTDI,
	    output JTDO1,
	    output reg JTDO2,
	    input  JSHIFT,
	    input  JUPDATE,
	    input  JRSTN,
	    input  JCE1,
	    input [14:0] ER2_TDO,
	    output reg [14:0] IP_ENABLE,
	    input  ISPTRACY_ER2_TDO,
	    output ISPTRACY_ENABLE,
	    output CONTROL_DATAN)/* synthesis syn_hier = hard */;


   wire 	   controlDataNBit;
   wire 	   ispTracyEnableBit;
   wire [3:0] 	   encodedIpEnableBits;
   wire [9:0] 	   er1TdiBit;
   wire 	   captureDrER1;
   

   assign 	   JTDO1 = er1TdiBit[0];
   
   TYPEB BIT0 (.CLK(JTCK),
	       .RESET_N(JRSTN),
	       .CLKEN(JCE1),
	       .TDI(er1TdiBit[1]),
	       .TDO(er1TdiBit[0]),
	       .DATA_IN(1'b0),
	       .CAPTURE_DR(captureDrER1));

   TYPEB BIT1 (.CLK(JTCK),
	       .RESET_N(JRSTN),
	       .CLKEN(JCE1),
	       .TDI(er1TdiBit[2]),
	       .TDO(er1TdiBit[1]),
	       .DATA_IN(1'b0),
	       .CAPTURE_DR(captureDrER1));

   TYPEB BIT2 (.CLK(JTCK),
	       .RESET_N(JRSTN),
	       .CLKEN(JCE1),
	       .TDI(er1TdiBit[3]),
	       .TDO(er1TdiBit[2]),
	       .DATA_IN(1'b1),
	       .CAPTURE_DR(captureDrER1));
   
   TYPEA BIT3 (.CLK(JTCK),
	       .RESET_N(JRSTN),
	       .CLKEN(JCE1),
	       .TDI(er1TdiBit[4]),
	       .TDO(er1TdiBit[3]),
	       .DATA_OUT(controlDataNBit),
	       .DATA_IN(controlDataNBit),
	       .CAPTURE_DR(captureDrER1),
	       .UPDATE_DR(JUPDATE));

   assign CONTROL_DATAN = controlDataNBit;

   TYPEA BIT4 (.CLK(JTCK),
	       .RESET_N(JRSTN),
	       .CLKEN(JCE1),
	       .TDI(er1TdiBit[5]),
	       .TDO(er1TdiBit[4]),
	       .DATA_OUT(ispTracyEnableBit),
	       .DATA_IN(ispTracyEnableBit),
	       .CAPTURE_DR(captureDrER1),
	       .UPDATE_DR(JUPDATE)
	       );

   assign ISPTRACY_ENABLE = ispTracyEnableBit;

   TYPEA BIT5 (.CLK(JTCK),
	       .RESET_N(JRSTN),
	       .CLKEN(JCE1),
	       .TDI(er1TdiBit[6]),
	       .TDO(er1TdiBit[5]),
	       .DATA_OUT(encodedIpEnableBits[0]),
	       .DATA_IN(encodedIpEnableBits[0]),
	       .CAPTURE_DR(captureDrER1),
	       .UPDATE_DR(JUPDATE));
   
   TYPEA BIT6 (.CLK(JTCK),
	       .RESET_N(JRSTN),
	       .CLKEN(JCE1),
	       .TDI(er1TdiBit[7]),
	       .TDO(er1TdiBit[6]),
	       .DATA_OUT(encodedIpEnableBits[1]),
	       .DATA_IN(encodedIpEnableBits[1]),
	       .CAPTURE_DR(captureDrER1),
	       .UPDATE_DR(JUPDATE));
   
   TYPEA BIT7 (.CLK(JTCK),
	       .RESET_N(JRSTN),
	       .CLKEN(JCE1),
	       .TDI(er1TdiBit[8]),
	       .TDO(er1TdiBit[7]),
	       .DATA_OUT(encodedIpEnableBits[2]),
	       .DATA_IN(encodedIpEnableBits[2]),
	       .CAPTURE_DR(captureDrER1),
	       .UPDATE_DR(JUPDATE));
   
   TYPEA BIT8 (.CLK(JTCK),
	       .RESET_N(JRSTN),
	       .CLKEN(JCE1),
	       .TDI(er1TdiBit[9]),
	       .TDO(er1TdiBit[8]),
	       .DATA_OUT(encodedIpEnableBits[3]),
	       .DATA_IN(encodedIpEnableBits[3]),
	       .CAPTURE_DR(captureDrER1),
	       .UPDATE_DR(JUPDATE)
	       );
   
   assign er1TdiBit[9] = JTDI;
   assign captureDrER1  = !JSHIFT & JCE1;
   
   always @ (encodedIpEnableBits,ISPTRACY_ER2_TDO, ER2_TDO)
   begin
    case (encodedIpEnableBits)
      4'h0: begin 
      		IP_ENABLE <= 15'b000000000000000;
      		JTDO2 <= ISPTRACY_ER2_TDO;
      	    end
      4'h1: begin
      		IP_ENABLE <= 15'b000000000000001;
      		JTDO2 <= ER2_TDO[0];
      	    end	
      4'h2: begin
      		IP_ENABLE <= 15'b000000000000010;
      		JTDO2 <= ER2_TDO[1];
      	    end
      4'h3: begin
      		IP_ENABLE <= 15'b000000000000100;
      		JTDO2 <= ER2_TDO[2];
      	    end
      4'h4: begin
      		IP_ENABLE <= 15'b000000000001000;
      		JTDO2 <= ER2_TDO[3];
      	    end
      4'h5: begin
      		IP_ENABLE <= 15'b000000000010000;
      		JTDO2 <= ER2_TDO[4];
      	    end
      4'h6: begin
      		IP_ENABLE <= 15'b000000000100000;
      		JTDO2 <= ER2_TDO[5];
      	    end
      4'h7: begin
      		IP_ENABLE <= 15'b000000001000000;
      		JTDO2 <= ER2_TDO[6];
      	    end
      4'h8: begin
      		IP_ENABLE <= 15'b000000010000000;
      		JTDO2 <= ER2_TDO[7];
      	    end
      4'h9: begin
      		IP_ENABLE <= 15'b000000100000000;
      		JTDO2 <= ER2_TDO[8];
      	    end
      4'hA: begin
      		IP_ENABLE <= 15'b000001000000000;
      		JTDO2 <= ER2_TDO[9];
      	    end
      4'hB: begin
      		IP_ENABLE <= 15'b000010000000000;
      		JTDO2 <= ER2_TDO[10];
      	    end
      4'hC: begin
      		IP_ENABLE <= 15'b000100000000000;
      		JTDO2 <= ER2_TDO[11];
      	    end
      4'hD: begin
      		IP_ENABLE <= 15'b001000000000000;
      		JTDO2 <= ER2_TDO[12];
      	    end
      4'hE: begin
      		IP_ENABLE <= 15'b010000000000000;
      		JTDO2 <= ER2_TDO[13];
      	    end
      4'hF: begin
      		IP_ENABLE <= 15'b100000000000000;
      		JTDO2 <= ER2_TDO[14];
      	    end
    endcase
  end
endmodule
