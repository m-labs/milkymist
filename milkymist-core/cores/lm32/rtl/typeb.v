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
// File             : TYPEB.v
// Description:
//    This is one of the two types of cells that are used to create ER1/ER2
//    register bits.
// Dependencies     : None
// Version          : 6.1.17
//   Modified typeb module to remove redundant DATA_OUT port.
// Version          : 7.0SP2, 3.0
//                  : No Change
// Version          : 3.1
//                  : No Change
// =============================================================================
module TYPEB
   (
      input CLK,
      input RESET_N,
      input CLKEN,
      input TDI,
      output TDO,
      input DATA_IN,
      input CAPTURE_DR
   );

   reg tdoInt;

   always @ (negedge CLK or negedge RESET_N)
   begin
      if (RESET_N== 1'b0)
         tdoInt <= 1'b0;
      else if (CLK == 1'b0)
         if (CLKEN==1'b1)
            if (CAPTURE_DR==1'b0)
               tdoInt <= TDI;
            else
               tdoInt <= DATA_IN;
   end

   assign TDO = tdoInt;

endmodule

