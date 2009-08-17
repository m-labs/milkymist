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

#ifndef __HW_PFPU_H
#define __HW_PFPU_H

#include <hw/common.h>

#define CSR_PFPU_CTL		MMPTR(0x80005000)
#define PFPU_CTL_START		0x01
#define PFPU_CTL_BUSY		0x01
#define PFPU_CTL_IRQ		0x02

#define CSR_PFPU_MESHBASE	MMPTR(0x80005004)
#define CSR_PFPU_HMESHLAST	MMPTR(0x80005008)
#define CSR_PFPU_VMESHLAST	MMPTR(0x8000500C)

#define CSR_PFPU_CODEPAGE	MMPTR(0x80005010)

#define CSR_PFPU_VERTICES	MMPTR(0x80005014)
#define CSR_PFPU_COLLISIONS	MMPTR(0x80005018)
#define CSR_PFPU_STRAYWRITES	MMPTR(0x8000501C)
#define CSR_PFPU_DMAPENDING	MMPTR(0x80005020)
#define CSR_PFPU_PC		MMPTR(0x80005024)

#define CSR_PFPU_DREGBASE	(0x80005400)
#define CSR_PFPU_CODEBASE	(0x80005800)

#define PFPU_OPCODE_NOP		(0x0)
#define PFPU_OPCODE_FADD	(0x1)
#define PFPU_OPCODE_FSUB	(0x2)
#define PFPU_OPCODE_FMUL	(0x3)
#define PFPU_OPCODE_FDIV	(0x4)
#define PFPU_OPCODE_F2I		(0x5)
#define PFPU_OPCODE_I2F		(0x6)
#define PFPU_OPCODE_VECT	(0x7)
#define PFPU_OPCODE_SIN		(0x8)
#define PFPU_OPCODE_COS		(0x9)
#define PFPU_OPCODE_ABOVE	(0xa)
#define PFPU_OPCODE_EQUAL	(0xb)
#define PFPU_OPCODE_COPY	(0xc)

#define PFPU_LATENCY_FADD	(4)
#define PFPU_LATENCY_FSUB	(4)
#define PFPU_LATENCY_FMUL	(5)
#define PFPU_LATENCY_FDIV	(0) /* TODO */
#define PFPU_LATENCY_F2I	(2)
#define PFPU_LATENCY_I2F	(3)
#define PFPU_LATENCY_VECT	(2)
#define PFPU_LATENCY_SIN	(4)
#define PFPU_LATENCY_COS	(4)
#define PFPU_LATENCY_ABOVE	(2)
#define PFPU_LATENCY_EQUAL	(2)
#define PFPU_LATENCY_COPY	(2)

#define PFPU_PROGSIZE		(2048)
#define PFPU_PAGESIZE		(512)

#define PFPU_REG_COUNT		(128)
#define PFPU_REG_X		(0)
#define PFPU_REG_Y		(1)
#define PFPU_REG_FLAGS		(2)
#define PFPU_REG_OUT		(127)

#define PFPU_TRIG_CONV		(8192.0/(2.0*3.14159265358))

static inline int pfpu_is_reserved(int reg)
{
	return (reg == PFPU_REG_X)||(reg == PFPU_REG_Y)||(reg == PFPU_REG_FLAGS)||(reg == PFPU_REG_OUT);
}

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
