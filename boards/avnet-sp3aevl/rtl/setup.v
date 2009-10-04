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
 * System clock frequency in Hz.
 */
`define CLOCK_FREQUENCY 64000000

/*
 * System clock period in ns (must be in sync with CLOCK_FREQUENCY).
 */
`define CLOCK_PERIOD 15.625

/*
 * Default baudrate for the debug UART.
 */
`define BAUD_RATE 115200
