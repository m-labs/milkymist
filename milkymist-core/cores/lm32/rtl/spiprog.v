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
// File             : SPIPROG.v
//   This module contains the ER2 regsiters of SPI Serial FLASH programmer IP
//   core.  There are only three ER2 registers, one control register and two
//   data registers, in this IP core.  The control register is a 8-bit wide
//   register for selecting which data register will be accessed when the
//   Control/Data# bit in ER1 register is low.  Data register 0 is a readonly
//   ID register.  It is composed of three register fields -- an 8-bit
//   "implementer", a 16-bit "IP_functionality", and a 12-bit "revision".
//   Data register 1 is a variable length register for sending commands to or
//   receiving readback data from the SPI Serial FLASH device.
// Dependencies     : None
// Version          : 6.1.17
//        1. Reduced the the ID register (DR0) length from 36 bits to 8 bits.
//        2. Same as TYPEA and TYPEB modules, use falling edge clock
//           for all TCK Flip-Flops.
//        3. Added 7 delay Flip-Flops so that the DR1 readback data from 
//           SPI Serial FLASH is in the byte boundary.
// Version          : 7.0SP2, 3.0
//                  : No Change
// Version          : 3.1
//                  : No Change
// =============================================================================
//---------------------------------------------------------------------------
//
//Name : SPIPROG.v
//
//Description:
//
//   This module contains the ER2 regsiters of SPI Serial FLASH programmer IP
//   core.  There are only three ER2 registers, one control register and two
//   data registers, in this IP core.  The control register is a 8-bit wide
//   register for selecting which data register will be accessed when the
//   Control/Data# bit in ER1 register is low.  Data register 0 is a readonly
//   ID register.  It is composed of three register fields -- an 8-bit
//   "implementer", a 16-bit "IP_functionality", and a 12-bit "revision".
//   Data register 1 is a variable length register for sending commands to or
//   receiving readback data from the SPI Serial FLASH device.
//
//$Log: spiprog.vhd,v $
//Revision 1.2  2004-09-09 11:43:26-07  jhsin
//1. Reduced the the ID register (DR0) length from 36 bits to 8 bits.
//2. Same as TYPEA and TYPEB modules, use falling edge clock
//   for all TCK Flip-Flops.
//
//Revision 1.1  2004-08-12 13:22:05-07  jhsin
//Added 7 delay Flip-Flops so that the DR1 readback data from SPI Serial FLASH is in the byte boundary.
//
//Revision 1.0  2004-08-03 18:35:56-07  jhsin
//Initial revision
//
//

module SPIPROG (input 	JTCK           ,
		input 	JTDI           ,
		output 	JTDO2          ,
		input 	JSHIFT         ,
		input 	JUPDATE        ,
		input 	JRSTN          ,
		input 	JCE2           ,
		input 	SPIPROG_ENABLE ,
		input 	CONTROL_DATAN  ,
		output 	SPI_C          ,
		output 	SPI_D          ,
		output 	SPI_SN         ,
		input 	SPI_Q);

   wire 		er2Cr_enable ;
   wire 		er2Dr0_enable;
   wire 		er2Dr1_enable;
   
   wire 		tdo_er2Cr ;
   wire 		tdo_er2Dr0;
   wire 		tdo_er2Dr1;
   
   wire [7:0] 		encodedDrSelBits ;
   wire [8:0] 		er2CrTdiBit      ;
   wire [8:0] 		er2Dr0TdiBit     ;
   
   wire 		captureDrER2;
   reg 			spi_s       ;
   reg [6:0] 		spi_q_dly;
   
   wire [7:0] 		ip_functionality_id;
   
   genvar 		i;
   
   //   ------ Control Register 0 ------
   
   assign 		er2Cr_enable = JCE2 & SPIPROG_ENABLE & CONTROL_DATAN;
   
   assign 		tdo_er2Cr = er2CrTdiBit[0];
   
   //   CR_BIT0_BIT7 
   generate
      for(i=0; i<=7; i=i+1)
	begin:CR_BIT0_BIT7
	   TYPEA BIT_N (.CLK        (JTCK),
			.RESET_N    (JRSTN),
			.CLKEN      (er2Cr_enable),
			.TDI        (er2CrTdiBit[i + 1]),
			.TDO        (er2CrTdiBit[i]),
			.DATA_OUT   (encodedDrSelBits[i]),
			.DATA_IN    (encodedDrSelBits[i]),
			.CAPTURE_DR (captureDrER2),
			.UPDATE_DR  (JUPDATE));
	end
   endgenerate // CR_BIT0_BIT7

   assign er2CrTdiBit[8] = JTDI;

//   ------ Data Register 0 ------
   assign er2Dr0_enable = (JCE2 & SPIPROG_ENABLE & ~CONTROL_DATAN & (encodedDrSelBits == 8'b00000000)) ? 1'b1 : 1'b0;

   assign tdo_er2Dr0 = er2Dr0TdiBit[0];

   assign ip_functionality_id = 8'b00000001;  //-- SPI Serial FLASH Programmer (0x01)

//   DR0_BIT0_BIT7 
   generate
      for(i=0; i<=7; i=i+1)
	begin:DR0_BIT0_BIT7
	   TYPEB BIT_N (.CLK        (JTCK),
			.RESET_N    (JRSTN),
			.CLKEN      (er2Dr0_enable),
			.TDI        (er2Dr0TdiBit[i + 1]),
			.TDO        (er2Dr0TdiBit[i]),
			.DATA_IN    (ip_functionality_id[i]),
			.CAPTURE_DR (captureDrER2));
	end
   endgenerate // DR0_BIT0_BIT7

   assign er2Dr0TdiBit[8] = JTDI;

//   ------ Data Register 1 ------

   assign er2Dr1_enable = (JCE2 & JSHIFT & SPIPROG_ENABLE & ~CONTROL_DATAN & (encodedDrSelBits == 8'b00000001)) ?  1'b1 : 1'b0;
   
   assign SPI_C = ~ (JTCK & er2Dr1_enable & spi_s);

   assign SPI_D = JTDI & er2Dr1_enable;

   //   SPI_S_Proc
   always @(negedge JTCK or negedge JRSTN)
     begin
	if (~JRSTN)
          spi_s <= 1'b0;
	else
          if (JUPDATE)
            spi_s <= 1'b0;
          else
            spi_s <= er2Dr1_enable;
     end
   
   assign SPI_SN = ~spi_s;
   
   //   SPI_Q_Proc
   always @(negedge JTCK or negedge JRSTN)
     begin
	if (~JRSTN)
          spi_q_dly <= 'b0;
	else
          if (er2Dr1_enable)
            spi_q_dly  <= {spi_q_dly[5:0],SPI_Q};
     end
   
   assign tdo_er2Dr1 = spi_q_dly[6];
   
   //   ------ JTDO2 MUX ------
   
   assign JTDO2 = CONTROL_DATAN ? tdo_er2Cr :
	  (encodedDrSelBits == 8'b00000000) ? tdo_er2Dr0 :
	  (encodedDrSelBits == 8'b00000001) ? tdo_er2Dr1 : 1'b0;
   
   assign captureDrER2  = ~JSHIFT & JCE2;
   
endmodule
