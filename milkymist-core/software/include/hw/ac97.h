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

#ifndef __HW_AC97_H
#define __HW_AC97_H

#include <hw/common.h>

#define CSR_AC97_CRCTL		MMPTR(0x80004000)

#define AC97_CRCTL_RQEN		(0x01)
#define AC97_CRCTL_WRITE	(0x02)
#define AC97_CRCTL_REQUEST	(0x04)
#define AC97_CRCTL_REPLY	(0x08)

#define CSR_AC97_CRADDR		MMPTR(0x80004004)
#define CSR_AC97_CRDATAOUT	MMPTR(0x80004008)
#define CSR_AC97_CRDATAIN	MMPTR(0x8000400C)

#define CSR_AC97_DCTL		MMPTR(0x80004010)
#define CSR_AC97_DADDRESS	MMPTR(0x80004014)
#define CSR_AC97_DREMAINING	MMPTR(0x80004018)

#define CSR_AC97_UCTL		MMPTR(0x80004020)
#define CSR_AC97_UADDRESS	MMPTR(0x80004024)
#define CSR_AC97_UREMAINING	MMPTR(0x80004028)

#define AC97_SCTL_EN		(0x01)
#define AC97_SCTL_IRQ		(0x02)

#define AC97_MAX_DMASIZE	(0x3fffc)

#endif /* __HW_AC97_H */
