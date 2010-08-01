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

#include "io.h"

#define SIE_LINE_STATUS_A	IO8(0x00)
#define SIE_LINE_STATUS_B	IO8(0x01)
#define SIE_DISCON_A		IO8(0x02)
#define SIE_DISCON_B		IO8(0x03)

#define SIE_SEL_RX		IO8(0x04)
#define SIE_SEL_TX		IO8(0x05)

#define SIE_TX_DATA		IO8(0x06)
#define SIE_TX_PENDING		IO8(0x07)
#define SIE_TX_VALID		IO8(0x08)
#define SIE_TX_BUSRESET		IO8(0x09)

#define SIE_RX_DATA		IO8(0x0a)
#define SIE_RX_PENDING		IO8(0x0b)
#define SIE_RX_ACTIVE		IO8(0x0c)

#define SIE_TX_LOW_SPEED	IO8(0x0d)
#define SIE_LOW_SPEED		IO8(0x0e)
#define SIE_GENERATE_EOP	IO8(0x0f)

#endif /* __SIE_H */
