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

#ifndef __SCHEDULER_H
#define __SCHEDULER_H

#include <hw/pfpu.h>
#include "compiler.h"

struct scheduler_state {
	int dont_touch[PFPU_REG_COUNT];
	int register_allocation[PFPU_REG_COUNT];
	int exits[PFPU_PROGSIZE];
	int last_exit;
	pfpu_instruction prog[PFPU_PROGSIZE];
};

void scheduler_init(struct scheduler_state *sc);
void scheduler_dont_touch(struct scheduler_state *sc, struct compiler_terminal *terminals);
int scheduler_schedule(struct scheduler_state *sc, vpfpu_instruction *visn, int vlength);

void print_program(struct scheduler_state *sc);

#endif /* __SCHEDULER_H */
