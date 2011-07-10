/*
 * Milkymist SoC (USB firmware
 * Copyright (C 2007, 2008, 2009, 2010 Sebastien Bourdeauducq
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

#define SIE_LINE_STATUS_A	0x00
#define SIE_LINE_STATUS_B	0x01

#define SIE_SEL_RX		0x02
#define SIE_SEL_TX		0x03

#define SIE_TX_DATA		0x04
#define SIE_TX_PENDING		0x05
#define SIE_TX_VALID		0x06
#define SIE_TX_BUSY		0x07
#define SIE_TX_BUSRESET		0x08

#define SIE_RX_DATA		0x09
#define SIE_RX_PENDING		0x0a
#define SIE_RX_ACTIVE		0x0b
#define SIE_RX_ERROR		0x0c

#define SIE_TX_LOW_SPEED	0x0d
#define SIE_LOW_SPEED		0x0e
#define SIE_GENERATE_EOP	0x0f

#endif /* __SIE_H */
