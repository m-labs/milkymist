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

#ifndef __COMPILER_H
#define __COMPILER_H

#include <hw/pfpu.h>

#include "ast.h"

typedef struct {
	int opa;
	int opb;
	int opcode;
	int dest;
} vpfpu_instruction;

/*
 * Virtual registers 0-(PFPU_REG_COUNT-1) are directly mapped to physical registers.
 * The others are dynamically mapped to free physical registers by the scheduler.
 */

struct compiler_terminal {
	int valid;
	int isconst;
	union {
		char name[IDENTIFIER_SIZE];
		float x;
	} id;
};

struct compiler_initial {
	char name[IDENTIFIER_SIZE];
	float x;
};

struct compiler_state {
	int n_vregs;
	struct compiler_terminal terminals[PFPU_REG_COUNT];
	int prog_length;
	vpfpu_instruction prog[PFPU_PROGSIZE];
};

void compiler_init(struct compiler_state *sc);
int compiler_add_isn(struct compiler_state *sc, int opcode, int opa, int opb, int dest);
int compiler_add_vreg(struct compiler_state *sc);
int compiler_add_variable(struct compiler_state *sc, const char *name);
int compiler_add_constant(struct compiler_state *sc, float x);
int compiler_compile_equation(struct compiler_state *sc, const char *target, struct ast_node *node);
void compiler_get_initial_regs(struct compiler_state *sc, struct compiler_initial *initials, float *regs);

void print_opcode(int opcode);
int get_arity(int opcode);
void print_vprogram(struct compiler_state *sc);
void print_terminals(struct compiler_state *sc);

#endif /* __COMPILER_H */
