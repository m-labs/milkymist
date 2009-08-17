/*
 * Milkymist VJ SoC (Software support library)
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation;
 * version 3 of the License.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 */

#ifndef __HW_SYSTEMACE_H
#define __HW_SYSTEMACE_H

#include <hw/common.h>

#define CSR_ACE_BUSMODE		MMPTR(0xa0000000)
#define CSR_ACE_STATUSL		MMPTR(0xa0000008)
#define CSR_ACE_STATUSH		MMPTR(0xa000000C)
#define CSR_ACE_ERRORL		MMPTR(0xa0000010)
#define CSR_ACE_ERRORH		MMPTR(0xa0000014)
#define CSR_ACE_CLBAL		MMPTR(0xa0000018)
#define CSR_ACE_CLBAH		MMPTR(0xa000001C)
#define CSR_ACE_MLBAL		MMPTR(0xa0000020)
#define CSR_ACE_MLBAH		MMPTR(0xa0000024)
#define CSR_ACE_SECCMD		MMPTR(0xa0000028)
#define CSR_ACE_VERSION		MMPTR(0xa000002C)
#define CSR_ACE_CTLL		MMPTR(0xa0000030)
#define CSR_ACE_CTLH		MMPTR(0xa0000034)
#define CSR_ACE_FAT		MMPTR(0xa0000038)
#define CSR_ACE_DATA		MMPTR(0xa0000080)

#define ACE_BUSMODE_16BIT	0x0001

#define ACE_STATUSL_CFGLOCK	0x0001
#define ACE_STATUSL_MPULOCK	0x0002
#define ACE_STATUSL_CFDETECT	0x0010
#define ACE_STATUSL_DATARDY	0x0020
#define ACE_STATUSL_DATAWRONLY	0x0040
#define ACE_STATUSL_CFCMDRDY	0x0100

#define ACE_SECCMD_RESET	0x0100
#define ACE_SECCMD_IDENTIFY	0x0200
#define ACE_SECCMD_READ		0x0300
#define ACE_SECCMD_WRITE	0x0400
#define ACE_SECCMD_ABORT	0x0600

#define ACE_CTLL_LOCKREQ	0x0002
#define ACE_CTLL_CFGRESET	0x0080

#endif /* __HW_SYSTEMACE_H */
