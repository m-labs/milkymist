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
// File             : lm32_ram.v
// Title            : Pseudo dual-port RAM.
// Version          : 6.1.17
//                  : Initial Release
// Version          : 7.0SP2, 3.0
//                  : No Change
// Version          : 3.1
//                  : Options added to select EBRs (True-DP, Psuedo-DP, DQ, or
//                  : Distributed RAM).
// Version          : 3.2
//                  : EBRs use SYNC resets instead of ASYNC resets.
// Version          : 3.5
//                  : Added read-after-write hazard resolution when using true
//                  : dual-port EBRs
// =============================================================================

`include "lm32_include.v"

/////////////////////////////////////////////////////
// Module interface
/////////////////////////////////////////////////////

module lm32_ram 
  (
   // ----- Inputs -------
   read_clk,
   write_clk,
   reset,
   enable_read,
   read_address,
   enable_write,
   write_address,
   write_data,
   write_enable,
   // ----- Outputs -------
   read_data
   );

/*----------------------------------------------------------------------
 Parameters
 ----------------------------------------------------------------------*/
parameter data_width = 1;               // Width of the data ports
parameter address_width = 1;            // Width of the address ports

/*----------------------------------------------------------------------
 Inputs
 ----------------------------------------------------------------------*/
input read_clk;                         // Read clock
input write_clk;                        // Write clock
input reset;                            // Reset

input enable_read;                      // Access enable
input [address_width-1:0] read_address; // Read/write address
input enable_write;                     // Access enable
input [address_width-1:0] write_address;// Read/write address
input [data_width-1:0] write_data;      // Data to write to specified address
input write_enable;                     // Write enable

/*----------------------------------------------------------------------
 Outputs
 ----------------------------------------------------------------------*/
output [data_width-1:0] read_data;      // Data read from specified addess
wire   [data_width-1:0] read_data;

/*----------------------------------------------------------------------
 Internal nets and registers
 ----------------------------------------------------------------------*/
reg [data_width-1:0]    mem[0:(1<<address_width)-1]; // The RAM
reg [address_width-1:0] ra; // Registered read address

/*----------------------------------------------------------------------
 Combinational Logic
 ----------------------------------------------------------------------*/
// Read port
assign read_data = mem[ra];

/*----------------------------------------------------------------------
 Sequential Logic
 ----------------------------------------------------------------------*/
// Write port
always @(posedge write_clk)
  if ((write_enable == `TRUE) && (enable_write == `TRUE))
    mem[write_address] <= write_data;

// Register read address for use on next cycle
always @(posedge read_clk)
  if (enable_read)
    ra <= read_address;

endmodule
