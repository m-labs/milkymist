// ============================================================================
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
// ============================================================================/
//                         FILE DETAILS
// Project          : LatticeMico32
// File             : jtag_cores.v
// Title            : Instantiates all IP cores on JTAG chain.
// Dependencies     : system_conf.v
// Version          : 6.0.14
//                  : modified to use jtagconn for LM32,
//                  : all technologies 7/10/07
// Version          : 7.0SP2, 3.0
//                  : No Change
// Version          : 3.1
//                  : No Change
// ============================================================================

`include "system_conf.v"

/////////////////////////////////////////////////////
// jtagconn16 Module Definition
/////////////////////////////////////////////////////

module jtagconn16 (er2_tdo, jtck, jtdi, jshift, jupdate, jrstn, jce2, ip_enable) ;
    input  er2_tdo ; 
    output jtck ; 
    output jtdi ; 
    output jshift ; 
    output jupdate ; 
    output jrstn ; 
    output jce2 ; 
    output ip_enable ; 
endmodule

/////////////////////////////////////////////////////
// Module interface
/////////////////////////////////////////////////////

(* syn_hier="hard" *) module jtag_cores (
    // ----- Inputs -------
    reg_d,
    reg_addr_d,
    // ----- Outputs -------    
    reg_update,
    reg_q,
    reg_addr_q,
    jtck,
    jrstn
    );
    
/////////////////////////////////////////////////////
// Inputs
/////////////////////////////////////////////////////

input [7:0] reg_d;
input [2:0] reg_addr_d;

/////////////////////////////////////////////////////
// Outputs
/////////////////////////////////////////////////////
   
output reg_update;
wire   reg_update;
output [7:0] reg_q;
wire   [7:0] reg_q;
output [2:0] reg_addr_q;
wire   [2:0] reg_addr_q;

output jtck;
wire   jtck; 	/* synthesis syn_keep=1 */
output jrstn;
wire   jrstn;  /* synthesis syn_keep=1 */	

/////////////////////////////////////////////////////
// Instantiations
/////////////////////////////////////////////////////

wire jtdi;          /* synthesis syn_keep=1 */
wire er2_tdo2;      /* synthesis syn_keep=1 */
wire jshift;        /* synthesis syn_keep=1 */
wire jupdate;       /* synthesis syn_keep=1 */
wire jce2;          /* synthesis syn_keep=1 */
wire ip_enable;     /* synthesis syn_keep=1 */
    
(* JTAG_IP="LM32", IP_ID="0", HUB_ID="0", syn_noprune=1 *) jtagconn16 jtagconn16_lm32_inst (
    .er2_tdo        (er2_tdo2),
    .jtck           (jtck),
    .jtdi           (jtdi),
    .jshift         (jshift),
    .jupdate        (jupdate),
    .jrstn          (jrstn),
    .jce2           (jce2),
    .ip_enable      (ip_enable)
);
    
(* syn_noprune=1 *) jtag_lm32 jtag_lm32_inst (
    .JTCK           (jtck),
    .JTDI           (jtdi),
    .JTDO2          (er2_tdo2),
    .JSHIFT         (jshift),
    .JUPDATE        (jupdate),
    .JRSTN          (jrstn),
    .JCE2           (jce2),
    .JTAGREG_ENABLE (ip_enable),
    .CONTROL_DATAN  (),
    .REG_UPDATE     (reg_update),
    .REG_D          (reg_d),
    .REG_ADDR_D     (reg_addr_d),
    .REG_Q          (reg_q),
    .REG_ADDR_Q     (reg_addr_q)
    );
    
endmodule
