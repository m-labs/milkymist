/*
 * Milkymist VJ SoC (Software)
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

#ifndef __HW_PS2_H
#define __HW_PS2_H

#include <hw/common.h>

#define CSR_PS2_KEYBOARD_DATA	MMPTR(0x80007000)
#define CSR_PS2_KEYBOARD_STATUS	MMPTR(0x80007004)
#define CSR_PS2_MOUSE_DATA	MMPTR(0x80008000)
#define CSR_PS2_MOUSE_STATUS	MMPTR(0x80008004)

#define PS2_BUSY		(0x1)

#endif /* __HW_PS2_H */
