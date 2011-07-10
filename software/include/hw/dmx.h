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

#ifndef __HW_DMX_H
#define __HW_DMX_H

#include <hw/common.h>

#define CSR_DMX_TX(x)		MMPTR(0xe000c000+4*(x))
#define CSR_DMX_THRU		MMPTR(0xe000c800)

#define CSR_DMX_RX(x)		MMPTR(0xe000d000+4*(x))

#endif /* __HW_DMX_H */
