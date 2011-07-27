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

#ifndef __HW_TMU_H
#define __HW_TMU_H

#include <hw/common.h>

#define CSR_TMU_CTL		MMPTR(0xe0007000)
#define TMU_CTL_START		0x01
#define TMU_CTL_BUSY		0x01
#define TMU_CTL_CHROMAKEY	0x02
#define TMU_CTL_ADDITIVE	0x04

#define CSR_TMU_HMESHLAST	MMPTR(0xe0007004)
#define CSR_TMU_VMESHLAST	MMPTR(0xe0007008)
#define CSR_TMU_BRIGHTNESS	MMPTR(0xe000700C)
#define CSR_TMU_CHROMAKEY	MMPTR(0xe0007010)

#define TMU_BRIGHTNESS_MAX	(63)

#define CSR_TMU_VERTICESADR	MMPTR(0xe0007014)
#define CSR_TMU_TEXFBUF		MMPTR(0xe0007018)
#define CSR_TMU_TEXHRES		MMPTR(0xe000701C)
#define CSR_TMU_TEXVRES		MMPTR(0xe0007020)
#define CSR_TMU_TEXHMASK	MMPTR(0xe0007024)
#define CSR_TMU_TEXVMASK	MMPTR(0xe0007028)

#define TMU_MASK_NOFILTER	(0x3ffc0)
#define TMU_MASK_FULL		(0x3ffff)
#define TMU_FIXEDPOINT_SHIFT	(6)

#define CSR_TMU_DSTFBUF		MMPTR(0xe000702C)
#define CSR_TMU_DSTHRES		MMPTR(0xe0007030)
#define CSR_TMU_DSTVRES		MMPTR(0xe0007034)
#define CSR_TMU_DSTHOFFSET	MMPTR(0xe0007038)
#define CSR_TMU_DSTVOFFSET	MMPTR(0xe000703C)
#define CSR_TMU_DSTSQUAREW	MMPTR(0xe0007040)
#define CSR_TMU_DSTSQUAREH	MMPTR(0xe0007044)

#define CSR_TMU_ALPHA		MMPTR(0xe0007048)

#define TMU_ALPHA_MAX		(63)

struct tmu_vertex {
	int x;
	int y;
} __attribute__((packed));

#define TMU_MESH_MAXSIZE	128

#endif /* __HW_TMU_H */
