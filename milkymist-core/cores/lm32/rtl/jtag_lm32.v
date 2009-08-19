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
// File             : jtag_lm32.v
// Title            : JTAG data register for LM32 CPU debug interface
// Version          : 6.0.13
//                  : Initial Release
// Version          : 7.0SP2, 3.0
//                  : No Change
// Version          : 3.1
//                  : No Change
// =============================================================================

/////////////////////////////////////////////////////
// Module interface
/////////////////////////////////////////////////////

module jtag_lm32 (
	input JTCK,
	input JTDI,
	output JTDO2,
	input JSHIFT,
	input JUPDATE,
	input JRSTN,
	input JCE2,
	input JTAGREG_ENABLE,
	input CONTROL_DATAN,
	output REG_UPDATE,
	input [7:0] REG_D,
	input [2:0] REG_ADDR_D,
	output [7:0] REG_Q,
	output [2:0] REG_ADDR_Q
	);

/////////////////////////////////////////////////////
// Internal nets and registers 
/////////////////////////////////////////////////////

wire [9:0] tdibus;

/////////////////////////////////////////////////////
// Instantiations
/////////////////////////////////////////////////////
   
TYPEA DATA_BIT0 (
    .CLK(JTCK),
    .RESET_N(JRSTN),
    .CLKEN(clk_enable),
    .TDI(JTDI),
    .TDO(tdibus[0]),
    .DATA_OUT(REG_Q[0]),
    .DATA_IN(REG_D[0]),
    .CAPTURE_DR(captureDr),
    .UPDATE_DR(JUPDATE)
    );

TYPEA DATA_BIT1 (
    .CLK(JTCK),
    .RESET_N(JRSTN),
    .CLKEN(clk_enable),
    .TDI(tdibus[0]),
    .TDO(tdibus[1]),
    .DATA_OUT(REG_Q[1]),
    .DATA_IN(REG_D[1]),
    .CAPTURE_DR(captureDr),
    .UPDATE_DR(JUPDATE)
    );

TYPEA DATA_BIT2 (
    .CLK(JTCK),
    .RESET_N(JRSTN),
    .CLKEN(clk_enable),
    .TDI(tdibus[1]),
    .TDO(tdibus[2]),
    .DATA_OUT(REG_Q[2]),
    .DATA_IN(REG_D[2]),
    .CAPTURE_DR(captureDr),
    .UPDATE_DR(JUPDATE)
    );

TYPEA DATA_BIT3 (
    .CLK(JTCK),
    .RESET_N(JRSTN),
    .CLKEN(clk_enable),
    .TDI(tdibus[2]),
    .TDO(tdibus[3]),
    .DATA_OUT(REG_Q[3]),
    .DATA_IN(REG_D[3]),
    .CAPTURE_DR(captureDr),
    .UPDATE_DR(JUPDATE)
    );

TYPEA DATA_BIT4 (
    .CLK(JTCK),
    .RESET_N(JRSTN),
    .CLKEN(clk_enable),
    .TDI(tdibus[3]),
    .TDO(tdibus[4]),
    .DATA_OUT(REG_Q[4]),
    .DATA_IN(REG_D[4]),
    .CAPTURE_DR(captureDr),
    .UPDATE_DR(JUPDATE)
    );

TYPEA DATA_BIT5 (
    .CLK(JTCK),
    .RESET_N(JRSTN),
    .CLKEN(clk_enable),
    .TDI(tdibus[4]),
    .TDO(tdibus[5]),
    .DATA_OUT(REG_Q[5]),
    .DATA_IN(REG_D[5]),
    .CAPTURE_DR(captureDr),
    .UPDATE_DR(JUPDATE)
    );

TYPEA DATA_BIT6 (
    .CLK(JTCK),
    .RESET_N(JRSTN),
    .CLKEN(clk_enable),
    .TDI(tdibus[5]),
    .TDO(tdibus[6]),
    .DATA_OUT(REG_Q[6]),
    .DATA_IN(REG_D[6]),
    .CAPTURE_DR(captureDr),
    .UPDATE_DR(JUPDATE)
    );

TYPEA DATA_BIT7 (
    .CLK(JTCK),
    .RESET_N(JRSTN),
    .CLKEN(clk_enable),
    .TDI(tdibus[6]),
    .TDO(tdibus[7]),
    .DATA_OUT(REG_Q[7]),
    .DATA_IN(REG_D[7]),
    .CAPTURE_DR(captureDr),
    .UPDATE_DR(JUPDATE)
    );

TYPEA ADDR_BIT0 (
    .CLK(JTCK),
    .RESET_N(JRSTN),
    .CLKEN(clk_enable),
    .TDI(tdibus[7]),
    .TDO(tdibus[8]),
    .DATA_OUT(REG_ADDR_Q[0]),
    .DATA_IN(REG_ADDR_D[0]),
    .CAPTURE_DR(captureDr),
    .UPDATE_DR(JUPDATE)
    );

TYPEA ADDR_BIT1 (
    .CLK(JTCK),
    .RESET_N(JRSTN),
    .CLKEN(clk_enable),
    .TDI(tdibus[8]),
    .TDO(tdibus[9]),
    .DATA_OUT(REG_ADDR_Q[1]),
    .DATA_IN(REG_ADDR_D[1]),
    .CAPTURE_DR(captureDr),
    .UPDATE_DR(JUPDATE)
    );

TYPEA ADDR_BIT2 (
    .CLK(JTCK),
    .RESET_N(JRSTN),
    .CLKEN(clk_enable),
    .TDI(tdibus[9]),
    .TDO(JTDO2),
    .DATA_OUT(REG_ADDR_Q[2]),
    .DATA_IN(REG_ADDR_D[2]),
    .CAPTURE_DR(captureDr),
    .UPDATE_DR(JUPDATE)
    );

/////////////////////////////////////////////////////
// Combinational logic
/////////////////////////////////////////////////////

assign clk_enable = JTAGREG_ENABLE & JCE2;
assign captureDr = !JSHIFT & JCE2;
// JCE2 is only active during shift
assign REG_UPDATE = JTAGREG_ENABLE & JUPDATE;
 
endmodule
