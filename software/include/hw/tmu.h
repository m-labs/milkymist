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

#ifndef __HW_TMU_H
#define __HW_TMU_H

#include <hw/common.h>

#define CSR_TMU_CTL		MMPTR(0x80006000)
#define TMU_CTL_START		0x01
#define TMU_CTL_BUSY		0x01
#define TMU_CTL_IRQ		0x02
#define TMU_CTL_CHROMAKEY	0x04
#define TMU_CTL_WRAP		0x08

#define CSR_TMU_HMESHLAST	MMPTR(0x80006004)
#define CSR_TMU_VMESHLAST	MMPTR(0x80006008)
#define CSR_TMU_BRIGHTNESS	MMPTR(0x8000600C)
#define CSR_TMU_CHROMAKEY	MMPTR(0x80006010)

#define TMU_BRIGHTNESS_MAX	(63)

#define CSR_TMU_SRCMESH		MMPTR(0x80006014)
#define CSR_TMU_SRCFBUF		MMPTR(0x80006018)
#define CSR_TMU_SRCHRES		MMPTR(0x8000601C)
#define CSR_TMU_SRCVRES		MMPTR(0x80006020)

#define CSR_TMU_DSTMESH		MMPTR(0x80006024)
#define CSR_TMU_DSTFBUF		MMPTR(0x80006028)
#define CSR_TMU_DSTHRES		MMPTR(0x8000602C)
#define CSR_TMU_DSTVRES		MMPTR(0x80006030)

/* Performance counters */

#define CSR_TMUP_PIXELS		MMPTR(0x80006034)
#define CSR_TMUP_CLOCKS		MMPTR(0x80006038)

#define CSR_TMUP_STALL1		MMPTR(0x8000603C)
#define CSR_TMUP_COMPLETE1	MMPTR(0x80006040)
#define CSR_TMUP_STALL2		MMPTR(0x80006044)
#define CSR_TMUP_COMPLETE2	MMPTR(0x80006048)

#define CSR_TMUP_MISSES		MMPTR(0x8000604C)

struct tmu_vertex {
	short int y;
	short int x;
} __attribute__((packed));

#define TMU_MESH_MAXSIZE	128

#endif /* __HW_TMU_H */

