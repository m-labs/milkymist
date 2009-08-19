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
// File             : lm32_monitor.v
// Title            : Debug monitor memory Wishbone interface
// Version          : 6.1.17
//                  : Initial Release
// Version          : 7.0SP2, 3.0
//                  : No Change
// Version          : 3.1
//                  : No Change
// =============================================================================

`include "system_conf.v"
`include "lm32_include.v"

/////////////////////////////////////////////////////
// Module interface
/////////////////////////////////////////////////////

module lm32_monitor (
    // ----- Inputs -------
    clk_i, 
    rst_i,
    MON_ADR_I,
    MON_CYC_I,
    MON_DAT_I,
    MON_SEL_I,
    MON_STB_I,
    MON_WE_I,
    MON_LOCK_I,
    MON_CTI_I,
    MON_BTE_I,
    // ----- Outputs -------
    MON_ACK_O,
    MON_RTY_O,
    MON_DAT_O,
    MON_ERR_O
    );

/////////////////////////////////////////////////////
// Inputs
/////////////////////////////////////////////////////

input clk_i;                                        // Wishbone clock
input rst_i;                                        // Wishbone reset
input [`LM32_WORD_RNG] MON_ADR_I;                   // Wishbone address
input MON_STB_I;                                    // Wishbone strobe
input MON_CYC_I;                                    // Wishbone cycle
input [`LM32_WORD_RNG] MON_DAT_I;                   // Wishbone write data
input [`LM32_BYTE_SELECT_RNG] MON_SEL_I;            // Wishbone byte select
input MON_WE_I;                                     // Wishbone write enable
input MON_LOCK_I;                                   // Wishbone locked transfer
input [`LM32_CTYPE_RNG] MON_CTI_I;                  // Wishbone cycle type
input [`LM32_BTYPE_RNG] MON_BTE_I;                  // Wishbone burst type
   
/////////////////////////////////////////////////////
// Outputs
/////////////////////////////////////////////////////

output MON_ACK_O;                                   // Wishbone acknowlege
reg    MON_ACK_O;
output [`LM32_WORD_RNG] MON_DAT_O;                  // Wishbone data output
reg    [`LM32_WORD_RNG] MON_DAT_O;
output MON_RTY_O;                                   // Wishbone retry
wire   MON_RTY_O;       
output MON_ERR_O;                                   // Wishbone error
wire   MON_ERR_O;
   
/////////////////////////////////////////////////////
// Internal nets and registers 
/////////////////////////////////////////////////////

reg [1:0] state;                                    // Current state of FSM
wire [`LM32_WORD_RNG] data;                         // Data read from RAM
reg write_enable;                                   // RAM write enable
reg [`LM32_WORD_RNG] write_data;                    // RAM write data
 
/////////////////////////////////////////////////////
// Instantiations
/////////////////////////////////////////////////////

lm32_monitor_ram ram (
    // ----- Inputs -------
    .ClockA             (clk_i),
    .ClockB             (clk_i),
    .ResetA             (rst_i),
    .ResetB             (rst_i),
    .ClockEnA           (`TRUE),
    .ClockEnB           (`FALSE),
    .AddressA           (MON_ADR_I[10:2]),
    .DataInA            (write_data),
    .WrA                (write_enable),
    .WrB                (`FALSE),
    // ----- Outputs -------
    .QA                 (data)
    );

/////////////////////////////////////////////////////
// Combinational Logic
/////////////////////////////////////////////////////

assign MON_RTY_O = `FALSE;
assign MON_ERR_O = `FALSE;

/////////////////////////////////////////////////////
// Sequential Logic
/////////////////////////////////////////////////////

always @(posedge clk_i `CFG_RESET_SENSITIVITY)
begin
    if (rst_i == `TRUE)
    begin
        write_enable <= `FALSE;
        MON_ACK_O <= `FALSE;
        MON_DAT_O <= {`LM32_WORD_WIDTH{1'bx}};
        state <= 2'b00;
    end
    else
    begin
        case (state)
        2'b00:
        begin
            // Wait for a Wishbone access
            if ((MON_STB_I == `TRUE) && (MON_CYC_I == `TRUE))
                state <= 2'b01;
        end
        2'b01:
        begin
            // Output read data to Wishbone
            MON_ACK_O <= `TRUE;
            MON_DAT_O <= data;
            // Sub-word writes are performed using read-modify-write  
            // as the Lattice EBRs don't support byte enables
            if (MON_WE_I == `TRUE)
                write_enable <= `TRUE;
            write_data[7:0] <= MON_SEL_I[0] ? MON_DAT_I[7:0] : data[7:0];
            write_data[15:8] <= MON_SEL_I[1] ? MON_DAT_I[15:8] : data[15:8];
            write_data[23:16] <= MON_SEL_I[2] ? MON_DAT_I[23:16] : data[23:16];
            write_data[31:24] <= MON_SEL_I[3] ? MON_DAT_I[31:24] : data[31:24];
            state <= 2'b10;
        end
        2'b10:
        begin
            // Wishbone access occurs in this cycle
            write_enable <= `FALSE;
            MON_ACK_O <= `FALSE;
            MON_DAT_O <= {`LM32_WORD_WIDTH{1'bx}};
            state <= 2'b00;
        end
        endcase        
    end
end

endmodule
