/*
 * Milkymist VJ SoC (OHCI firmware)
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

#ifndef __SIE_H
#define __SIE_H

#define SIE_LINE_STATUS_A	*((volatile unsigned int *)0xc0000000)
#define SIE_LINE_STATUS_B	*((volatile unsigned int *)0xc0000004)
#define SIE_DISCON_A		*((volatile unsigned int *)0xc0000008)
#define SIE_DISCON_B		*((volatile unsigned int *)0xc000000c)

#define SIE_SEL_RX		*((volatile unsigned int *)0xc0000010)
#define SIE_SEL_TX		*((volatile unsigned int *)0xc0000014)

#define SIE_TX_DATA		*((volatile unsigned int *)0xc0000018)
#define SIE_TX_PENDING		*((volatile unsigned int *)0xc000001C)
#define SIE_TX_VALID		*((volatile unsigned int *)0xc0000020)

#define SIE_RX_DATA		*((volatile unsigned int *)0xc0000024)
#define SIE_RX_PENDING		*((volatile unsigned int *)0xc0000028)
#define SIE_RX_ACTIVE		*((volatile unsigned int *)0xc000002C)
#define SIE_RX_ERROR		*((volatile unsigned int *)0xc0000030)

#endif /* __SIE_H */
