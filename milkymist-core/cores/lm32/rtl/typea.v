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
// File             : TYPEA.v
// Description:
//    This is one of the two types of cells that are used to create ER1/ER2
//    register bits.
// Dependencies     : None
// Version          : 6.1.17
//   The SHIFT_DR_CAPTURE_DR and ENABLE_ER1/2 signals of the
//   dedicate logic JTAG_PORT didn't act as what their names implied.
//   The SHIFT_DR_CAPTURE_DR actually acts as SHIFT_DR.
//   The ENABLE_ER1/2 actually acts as SHIFT_DR_CAPTURE_DR.
//   These had caused a lot of headaches for a long time and now they are
//   fixed by:
//   (1) Use SHIFT_DR_CAPTURE_DR and ENABLE_ER1/2 to create
//       CAPTURE_DR for all typeA, typeB bits in the ER1, ER2 registers.
//   (2) Use ENABLE_ER1 or the enESR, enCSR, enBAR (these 3 signals
//       have the same waveform of ENABLE_ER2) directly to be the CLKEN
//       of all typeA, typeB bits in the ER1, ER2 registers.
//   (3) Modify typea.vhd to use only UPDATE_DR signal for the clock enable
//       of the holding flip-flop.
//   These changes caused ispTracy.vhd and cge.dat changes and the new
//   CGE.exe version will be 1.3.5.
// Version          : 7.0SP2, 3.0
//                  : No Change
// Version          : 3.1
//                  : No Change
// =============================================================================
module TYPEA(
      input CLK,
      input RESET_N,
      input CLKEN,
      input TDI,
      output TDO,
      output reg DATA_OUT,
      input DATA_IN,
      input CAPTURE_DR,
      input UPDATE_DR
   );
  
  reg tdoInt;


  always @ (negedge CLK or negedge RESET_N)
  begin
      if (RESET_N == 1'b0)
         tdoInt <= 1'b0;
      else if (CLK == 1'b0)
         if (CLKEN == 1'b1)
            if (CAPTURE_DR == 1'b0)
               tdoInt <= TDI;
            else
               tdoInt <= DATA_IN;
  end

   assign TDO = tdoInt;

  always @ (negedge CLK or negedge RESET_N)
   begin
      if (RESET_N == 1'b0)
         DATA_OUT <= 1'b0;
      else if (CLK == 1'b0)
         if (UPDATE_DR == 1'b1)
            DATA_OUT <= tdoInt;
   end
endmodule
