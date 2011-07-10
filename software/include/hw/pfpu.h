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

#ifndef __HW_PFPU_H
#define __HW_PFPU_H

#include <hw/common.h>

#define CSR_PFPU_CTL		MMPTR(0xe0006000)
#define PFPU_CTL_START		0x01
#define PFPU_CTL_BUSY		0x01

#define CSR_PFPU_MESHBASE	MMPTR(0xe0006004)
#define CSR_PFPU_HMESHLAST	MMPTR(0xe0006008)
#define CSR_PFPU_VMESHLAST	MMPTR(0xe000600C)

#define CSR_PFPU_CODEPAGE	MMPTR(0xe0006010)

#define CSR_PFPU_VERTICES	MMPTR(0xe0006014)
#define CSR_PFPU_COLLISIONS	MMPTR(0xe0006018)
#define CSR_PFPU_STRAYWRITES	MMPTR(0xe000601C)
#define CSR_PFPU_LASTDMA	MMPTR(0xe0006020)
#define CSR_PFPU_PC		MMPTR(0xe0006024)

#define CSR_PFPU_DREGBASE	(0xe0006400)
#define CSR_PFPU_CODEBASE	(0xe0006800)

#define PFPU_OPCODE_NOP		(0x0)
#define PFPU_OPCODE_FADD	(0x1)
#define PFPU_OPCODE_FSUB	(0x2)
#define PFPU_OPCODE_FMUL	(0x3)
#define PFPU_OPCODE_FABS	(0x4)
#define PFPU_OPCODE_F2I		(0x5)
#define PFPU_OPCODE_I2F		(0x6)
#define PFPU_OPCODE_VECTOUT	(0x7)
#define PFPU_OPCODE_SIN		(0x8)
#define PFPU_OPCODE_COS		(0x9)
#define PFPU_OPCODE_ABOVE	(0xa)
#define PFPU_OPCODE_EQUAL	(0xb)
#define PFPU_OPCODE_COPY	(0xc)
#define PFPU_OPCODE_IF		(0xd)
#define PFPU_OPCODE_TSIGN	(0xe)
#define PFPU_OPCODE_QUAKE	(0xf)

#define PFPU_LATENCY_FADD	(5)
#define PFPU_LATENCY_FSUB	(5)
#define PFPU_LATENCY_FMUL	(7)
#define PFPU_LATENCY_FABS	(2)
#define PFPU_LATENCY_F2I	(2)
#define PFPU_LATENCY_I2F	(3)
#define PFPU_LATENCY_VECTOUT	(0)
#define PFPU_LATENCY_SIN	(4)
#define PFPU_LATENCY_COS	(4)
#define PFPU_LATENCY_ABOVE	(2)
#define PFPU_LATENCY_EQUAL	(2)
#define PFPU_LATENCY_COPY	(2)
#define PFPU_LATENCY_IF		(2)
#define PFPU_LATENCY_TSIGN	(2)
#define PFPU_LATENCY_QUAKE	(2)

#define PFPU_PROGSIZE		(2048)
#define PFPU_PAGESIZE		(512)

#define PFPU_REG_COUNT		(128)
#define PFPU_SPREG_COUNT	(2)
#define PFPU_REG_X		(0)
#define PFPU_REG_Y		(1)

#define PFPU_REG_IFB		(2)

#define PFPU_TRIG_CONV		(8192.0/(2.0*3.14159265358))

typedef union {
	struct {
		unsigned pad:7;
		unsigned opa:7;
		unsigned opb:7;
		unsigned opcode:4;
		unsigned dest:7;
	} i __attribute__((packed));
	unsigned int w;
} pfpu_instruction;

#endif /* __HW_PFPU_H */
