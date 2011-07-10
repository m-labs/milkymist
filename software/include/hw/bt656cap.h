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

#ifndef __HW_BT656CAP_H
#define __HW_BT656CAP_H

#include <hw/common.h>

#define CSR_BT656CAP_I2C		MMPTR(0xe000a000)
#define CSR_BT656CAP_FILTERSTATUS	MMPTR(0xe000a004)
#define CSR_BT656CAP_BASE		MMPTR(0xe000a008)
#define CSR_BT656CAP_MAXBURSTS		MMPTR(0xe000a00C)
#define CSR_BT656CAP_DONEBURSTS		MMPTR(0xe000a010)

#define BT656CAP_I2C_SDAIN		(0x1)
#define BT656CAP_I2C_SDAOUT		(0x2)
#define BT656CAP_I2C_SDAOE		(0x4)
#define BT656CAP_I2C_SDC		(0x8)

#define BT656CAP_FILTERSTATUS_FIELD1	(0x1)
#define BT656CAP_FILTERSTATUS_FIELD2	(0x2)
#define BT656CAP_FILTERSTATUS_INFRAME	(0x4)

#endif /* __HW_BT656CAP_H */
