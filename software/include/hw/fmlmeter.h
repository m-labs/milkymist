/*
 * Milkymist SoC (Software)
 * Copyright (C) 2007, 2008, 2009, 2010, 2011 Sebastien Bourdeauducq
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

#ifndef __HW_FMLMETER_H
#define __HW_FMLMETER_H

#include <hw/common.h>

#define CSR_FMLMETER_COUNTERS_ENABLE	MMPTR(0xe0009000)

#define FMLMETER_COUNTERS_ENABLE	(0x01)

#define CSR_FMLMETER_STBCOUNT		MMPTR(0xe0009004)
#define CSR_FMLMETER_ACKCOUNT		MMPTR(0xe0009008)

#define CSR_FMLMETER_CAPTURE_WADR	MMPTR(0xe000900c)
#define CSR_FMLMETER_CAPTURE_RADR	MMPTR(0xe0009010)
#define CSR_FMLMETER_CAPTURE_DATA	MMPTR(0xe0009014)

#endif /* __HW_FMLMETER_H */
