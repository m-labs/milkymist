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

#define CSR_MINIMAC_SETUP		MMPTR(0x80009000)

#define MINIMAC_SETUP_SPEED10		(0x1)
#define MINIMAC_SETUP_PROMISC		(0x2)

#define CSR_MINIMAC_ADDRHI		MMPTR(0x80009004)
#define CSR_MINIMAC_ADDRLO		MMPTR(0x80009008)

#define CSR_MINIMAC_MDIO		MMPTR(0x8000900C)

#define MINIMAC_MDIO_DO			(0x1)
#define MINIMAC_MDIO_DI			(0x2)
#define MINIMAC_MDIO_OE			(0x4)
#define MINIMAC_MDIO_CLK		(0x8)

#define CSR_MINIMAC_STATE0		MMPTR(0x80009010)
#define CSR_MINIMAC_ADDR0		MMPTR(0x80009014)
#define CSR_MINIMAC_COUNT0		MMPTR(0x80009018)
#define CSR_MINIMAC_STATE1		MMPTR(0x8000901C)
#define CSR_MINIMAC_ADDR1		MMPTR(0x80009020)
#define CSR_MINIMAC_COUNT1		MMPTR(0x80009024)
#define CSR_MINIMAC_STATE2		MMPTR(0x80009028)
#define CSR_MINIMAC_ADDR2		MMPTR(0x8000902C)
#define CSR_MINIMAC_COUNT2		MMPTR(0x80009030)
#define CSR_MINIMAC_STATE3		MMPTR(0x80009034)
#define CSR_MINIMAC_ADDR3		MMPTR(0x80009038)
#define CSR_MINIMAC_COUNT3		MMPTR(0x8000903C)

#define MINIMAC_STATE_EMPTY		(0x0)
#define MINIMAC_STATE_LOADED		(0x1)
#define MINIMAC_STATE_PENDING		(0x2)

#define CSR_MINIMAC_TXADR		MMPTR(0x80009040)
#define CSR_MINIMAC_TXREMAINING		MMPTR(0x80009044)

#endif /* __HW_MINIMAC_H */
