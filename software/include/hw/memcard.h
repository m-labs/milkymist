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

#ifndef __HW_MEMCARD_H
#define __HW_MEMCARD_H

#include <hw/common.h>

#define CSR_MEMCARD_CLK2XDIV		MMPTR(0xe0004000)

#define CSR_MEMCARD_ENABLE		MMPTR(0xe0004004)

#define MEMCARD_ENABLE_CMD_TX		(0x1)
#define MEMCARD_ENABLE_CMD_RX		(0x2)
#define MEMCARD_ENABLE_DAT_TX		(0x4)
#define MEMCARD_ENABLE_DAT_RX		(0x8)

#define CSR_MEMCARD_PENDING		MMPTR(0xe0004008)

#define MEMCARD_PENDING_CMD_TX		(0x1)
#define MEMCARD_PENDING_CMD_RX		(0x2)
#define MEMCARD_PENDING_DAT_TX		(0x4)
#define MEMCARD_PENDING_DAT_RX		(0x8)

#define CSR_MEMCARD_START		MMPTR(0xe000400c)

#define MEMCARD_START_CMD_RX		(0x1)
#define MEMCARD_START_DAT_RX		(0x2)

#define CSR_MEMCARD_CMD			MMPTR(0xe0004010)
#define CSR_MEMCARD_DAT			MMPTR(0xe0004014)

#endif /* __HW_MEMCARD_H */
