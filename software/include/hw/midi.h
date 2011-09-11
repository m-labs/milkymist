/*
 * Milkymist SoC (Software)
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

#ifndef __HW_MIDI_H
#define __HW_MIDI_H

#include <hw/common.h>

#define CSR_MIDI_RXTX 		MMPTR(0xe000b000)
#define CSR_MIDI_DIVISOR	MMPTR(0xe000b004)
#define CSR_MIDI_STAT		MMPTR(0xe000b008)
#define CSR_MIDI_CTRL		MMPTR(0xe000b00c)

#define MIDI_STAT_THRE		(0x1)
#define MIDI_STAT_RX_EVT	(0x2)
#define MIDI_STAT_TX_EVT	(0x4)

#define MIDI_CTRL_RX_INT	(0x1)
#define MIDI_CTRL_TX_INT	(0x2)
#define MIDI_CTRL_THRU		(0x4)

#endif /* __HW_MIDI_H */
