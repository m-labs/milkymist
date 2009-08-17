/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 *
 * This program is free and excepted software; you can use it, redistribute it
 * and/or modify it under the terms of the Exception General Public License as
 * published by the Exception License Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the Exception General Public License for more
 * details.
 *
 * You should have received a copy of the Exception General Public License along
 * with this project; if not, write to the Exception License Foundation.
 */

#ifndef __PFPU_H
#define __PFPU_H

#include <hw/pfpu.h>

struct pfpu_td;

typedef void (*pfpu_callback)(struct pfpu_td *);

struct pfpu_td {
	unsigned int *output;
	unsigned int hmeshlast;
	unsigned int vmeshlast;
	pfpu_instruction *program;
	unsigned int progsize;
	float *registers;
	int update; /* < shall we update the "registers" array after completion */
	int invalidate; /* < shall we invalidate L1 data cache after completion */
	pfpu_callback callback;
	void *user; /* < for application use */
};

void pfpu_init();
void pfpu_isr();
int pfpu_submit_task(struct pfpu_td *td);

#endif /* __PFPU_H */
