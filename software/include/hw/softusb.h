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

#ifndef __SOFTUSB_H
#define __SOFTUSB_H

#include <hw/common.h>

#define CSR_SOFTUSB_CONTROL	MMPTR(0xe000f000)

#define SOFTUSB_CONTROL_RESET	(0x1)

#define SOFTUSB_PMEM_BASE	(0xa0000000)
#define SOFTUSB_DMEM_BASE	(0xa0020000)

#define SOFTUSB_PMEM_SIZE	(1 << 12)
#define SOFTUSB_DMEM_SIZE	(1 << 13)

#endif /* __SOFTUSB_H */
