/*
 * Milkymist VJ SoC (Software)
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

#ifndef __HW_MINIMAC_H
#define __HW_MINIMAC_H

#include <hw/common.h>

#define CSR_MINIMAC_SETUP		MMPTR(0xe0008000)

#define MINIMAC_SETUP_RXRST		(0x1)
#define MINIMAC_SETUP_TXRST		(0x2)

#define CSR_MINIMAC_MDIO		MMPTR(0xe0008004)

#define MINIMAC_MDIO_DO			(0x1)
#define MINIMAC_MDIO_DI			(0x2)
#define MINIMAC_MDIO_OE			(0x4)
#define MINIMAC_MDIO_CLK		(0x8)

#define CSR_MINIMAC_STATE0		MMPTR(0xe0008008)
#define CSR_MINIMAC_ADDR0		MMPTR(0xe000800C)
#define CSR_MINIMAC_COUNT0		MMPTR(0xe0008010)

#define CSR_MINIMAC_STATE1		MMPTR(0xe0008014)
#define CSR_MINIMAC_ADDR1		MMPTR(0xe0008018)
#define CSR_MINIMAC_COUNT1		MMPTR(0xe000801C)

#define CSR_MINIMAC_STATE2		MMPTR(0xe0008020)
#define CSR_MINIMAC_ADDR2		MMPTR(0xe0008024)
#define CSR_MINIMAC_COUNT2		MMPTR(0xe0008028)

#define CSR_MINIMAC_STATE3		MMPTR(0xe000802C)
#define CSR_MINIMAC_ADDR3		MMPTR(0xe0008030)
#define CSR_MINIMAC_COUNT3		MMPTR(0xe0008034)

#define MINIMAC_STATE_EMPTY		(0x0)
#define MINIMAC_STATE_LOADED		(0x1)
#define MINIMAC_STATE_PENDING		(0x2)

#define CSR_MINIMAC_TXADR		MMPTR(0xe0008038)
#define CSR_MINIMAC_TXREMAINING		MMPTR(0xe000803C)

#endif /* __HW_MINIMAC_H */
