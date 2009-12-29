/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
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

`define ENABLE_ACEUSB
`define ENABLE_AC97
`define ENABLE_PFPU
`define ENABLE_TMU
`define ENABLE_PS2_KEYBOARD
`define ENABLE_PS2_MOUSE

/*
 * System clock frequency in Hz.
 */
`define CLOCK_FREQUENCY 100000000

/*
 * System clock period in ns (must be in sync with CLOCK_FREQUENCY).
 */
`define CLOCK_PERIOD 10

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
