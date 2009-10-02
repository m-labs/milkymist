/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 *
 * This program is free and excepted software; you can use it, redistribute it
 * and/or modify it under the terms of the Exception General Public License as
 * published by the Exception License Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the Exception General Public License for more
 * details.
 *
 * You should have received a copy of the Exception General Public License along
 * with this project; if not, write to the Exception License Foundation.
 */

/*
 * Enable or disable some cores.
 * A complete system would have them all except the debug cores
 * but when working on a specific part, it's very useful to be
 * able to cut down synthesis times.
 */

//`define ENABLE_ISP1362
//`define ENABLE_CFCARD
/*
 * FIXME: clocks in AC97 and VGA are not handled correctly
 * and cause failure of ISE 11.2.
 */
//`define ENABLE_AC97
//`define ENABLE_VGA
//`define ENABLE_PFPU
/*
 * FIXME: enabling the TMU causes Xst 11.2 with SP6 to fail with
 * "ERROR:Xst:1706 - Unit <system>:
 * port <m1_di<10>> of logic node <fmlarb/Mmux_s_do2> has no source"
 * repeated for other signals in m1_di and fmlarb/Mmux_s_do.
 */
//`define ENABLE_TMU

/*
 * System clock frequency in Hz.
 */
`define CLOCK_FREQUENCY 80000000

/*
 * System clock period in ns (must be in sync with CLOCK_FREQUENCY).
 */
`define CLOCK_PERIOD 12.5

/*
 * Default baudrate for the debug UART.
 */
`define BAUD_RATE 115200

/*
 * SDRAM depth, in bytes (the number of bits you need to address the whole
 * array with byte granularity)
 */
`define SDRAM_DEPTH 26

/*
 * SDRAM column depth (the number of column address bits)
 */
`define SDRAM_COLUMNDEPTH 9
