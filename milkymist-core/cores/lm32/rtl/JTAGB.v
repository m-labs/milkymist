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
// File             : JTAGB.v
// Title            : JTAGB Black Box
// Dependencies     : None
// Version          : 6.0.14
//                  : Initial Release
// Version          : 7.0SP2, 3.0
//                  : No Change
// Version          : 3.1
//                  : No Change
// =============================================================================
module JTAGB (
         output JTCK,
         output JRTI1,
         output JRTI2,
         output JTDI,
         output JSHIFT,
         output JUPDATE,
         output JRSTN,
         output JCE1,
         output JCE2,
         input JTDO1,
         input JTDO2
      ) /*synthesis syn_black_box */; 
      
endmodule
