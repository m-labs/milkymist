/*
 * Milkymist SoC (USB firmware)
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

#ifndef __INPUT_COMLOC_H
#define __INPUT_COMLOC_H

#include <hw/softusb.h>

#define COMLOC(x)	(*(unsigned char *)(x))
#define COMLOCV(x)	(*(volatile unsigned char *)(x))

#define COMLOC_DEBUG_PRODUCE	COMLOCV(SOFTUSB_DMEM_BASE+0x1000)
#define COMLOC_DEBUG(offset)	COMLOCV(SOFTUSB_DMEM_BASE+0x1001+offset)
#define COMLOC_MEVT_PRODUCE	COMLOCV(SOFTUSB_DMEM_BASE+0x1101)
#define COMLOC_MEVT(offset)	COMLOCV(SOFTUSB_DMEM_BASE+0x1102+offset)
#define COMLOC_KEVT_PRODUCE	COMLOCV(SOFTUSB_DMEM_BASE+0x1142)
#define COMLOC_KEVT(offset)	COMLOCV(SOFTUSB_DMEM_BASE+0x1143+offset)

#endif /* __INPUT_COMLOC_H */
