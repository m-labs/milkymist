/*
 * Milkymist SoC
 * Copyright (C) 2007, 2008, 2009, 2010 Sebastien Bourdeauducq
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/*
 * Enable or disable some cores.
 * A complete system would have them all except the debug cores
 * but when working on a specific part, it's very useful to be
 * able to cut down synthesis times.
 */
`define ENABLE_MEMORYCARD
`define ENABLE_ETHERNET
`define ENABLE_USB

`define ENABLE_AC97
`define ENABLE_PFPU
`define ENABLE_TMU
`define ENABLE_FMLMETER
`define ENABLE_VIDEOIN
`define ENABLE_MIDI
`define ENABLE_DMX
`define ENABLE_IR

`ifndef ENABLE_TMU
`define ENABLE_MEMTEST
`endif


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
`define SDRAM_DEPTH 27

/*
 * SDRAM column depth (the number of column address bits)
 */
`define SDRAM_COLUMNDEPTH 10
