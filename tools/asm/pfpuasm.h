/*
 * pfpuasm.h - PFPU assembler
 *
 * Copyright 2012 by Werner Almesberger
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#ifndef PFPUASM_H
#define	PFPUASM_H

#include <stdint.h>

#include "hw/pfpu.h"


/*
 * We can't use a union for portability reasons. Safer to compose the
 * instruction "manually".
 *
 * Instruction format:
 *
 * 3 3 2 2 2 2 2|2 2 2 2 2 1 1|1 1 1 1 1 1 1|1      |
 * 1 0 9 8 7 6 5|4 3 2 1 0 9 8|7 6 5 4 3 2 1|0 9 8 7|6 5 4 3 2 1 0
 *      pad     |     opa     |     opb     |opcode |    dest
 */

#define	OPA_SHIFT	18
#define	OPA_MASK	0x7f
#define	OPB_SHIFT	11
#define	OPB_MASK	0x7f
#define	OPCODE_SHIFT	7
#define	OPCODE_MASK	0x0f
#define	DEST_SHIFT	0
#define	DEST_MASK	0x7f


extern uint32_t prog[PFPU_PROGSIZE];
extern uint32_t *pc;

extern uint32_t regs[PFPU_REG_COUNT];
extern int max_reg;

extern int auto_nop;


union u_f2i {
	float f;
	int i;
};


static inline uint32_t f2i(float f)
{
	union u_f2i u = { .f = f };

	return u.i;
}


static inline float i2f(uint32_t i)
{
	union u_f2i u = { .i = i };

	return u.f;
}


void yyerror(const char *s);

#endif /* !PFPUASM_H */
