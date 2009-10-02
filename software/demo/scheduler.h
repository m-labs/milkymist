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
