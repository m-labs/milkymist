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

#ifndef __HW_MEMTEST_H
#define __HW_MEMTEST_H

#include <hw/common.h>

#define CSR_MEMTEST_BCOUNT 	MMPTR(0xe0007000)
#define CSR_MEMTEST_ERRORS 	MMPTR(0xe0007004)
#define CSR_MEMTEST_ADDRESS 	MMPTR(0xe0007008)
#define CSR_MEMTEST_WRITE 	MMPTR(0xe000700C)

#endif /* __HW_MEMTEST_H */
