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

#include <stdio.h>
#include <string.h>
#include <hw/pfpu.h>

#include "compiler.h"

void compiler_init(struct compiler_state *sc)
{
	int i;
	
	sc->n_vregs = PFPU_REG_COUNT;
	for(i=0;i<PFPU_REG_COUNT;i++)
		sc->terminals[i].valid = 0;
	sc->prog_length = 0;
}

static int find_free_terminal(struct compiler_state *sc)
{
	int i;

	for(i=0;i<PFPU_REG_COUNT;i++) {
		if(pfpu_is_reserved(i)) continue;
		if(!sc->terminals[i].valid)
			return i;
	}
	return -1;
}

int compiler_add_variable(struct compiler_state *sc, const char *name)
{
	int i;

	for(i=0;i<PFPU_REG_COUNT;i++)
		if(sc->terminals[i].valid
			&& !sc->terminals[i].isconst
			&& (strcmp(sc->terminals[i].id.name, name) == 0)
		) return i;
	
	i = find_free_terminal(sc);
	if(i == -1) return -1;

	sc->terminals[i].valid = 1;
	sc->terminals[i].isconst = 0;
	strcpy(sc->terminals[i].id.name, name);

	return i;
}

int compiler_add_constant(struct compiler_state *sc, float x)
{
	int i;

	for(i=0;i<PFPU_REG_COUNT;i++)
		if(sc->terminals[i].valid
			&& sc->terminals[i].isconst
			&& (sc->terminals[i].id.x == x)
		) return i;

	i = find_free_terminal(sc);
	if(i == -1) return -1;

	sc->terminals[i].valid = 1;
	sc->terminals[i].isconst = 1;
	sc->terminals[i].id.x = x;

	return i;
}

int compiler_add_isn(struct compiler_state *sc, int opcode, int opa, int opb, int dest)
{
	int len;

	len = sc->prog_length;
	if(len >= PFPU_PROGSIZE) return 0;

	sc->prog[len].opa = opa;
	sc->prog[len].opb = opb;
	sc->prog[len].opcode = opcode;
	sc->prog[len].dest = dest;

	sc->prog_length++;
	return 1;
}

int compiler_add_vreg(struct compiler_state *sc)
{
	return sc->n_vregs++;
}

static int operator2opcode(const char *operator)
{
	if(strcmp(operator, "+") == 0) return PFPU_OPCODE_FADD;
	if(strcmp(operator, "-") == 0) return PFPU_OPCODE_FSUB;
	if(strcmp(operator, "*") == 0) return PFPU_OPCODE_FMUL;
	if(strcmp(operator, "/") == 0) return PFPU_OPCODE_FDIV;
	if(strcmp(operator, "sin") == 0) return PFPU_OPCODE_SIN;
	if(strcmp(operator, "cos") == 0) return PFPU_OPCODE_COS;
	if(strcmp(operator, "above") == 0) return PFPU_OPCODE_ABOVE;
	if(strcmp(operator, "equal") == 0) return PFPU_OPCODE_EQUAL;
	else return -1;
}

/*
 * Compiles a node.
 * Returns the virtual register the result of the node gets written to,
 * and -1 in case of error.
 * If reg >= 0, it forces the result to be written to this particular register.
 */
static int int_compile(struct compiler_state *sc, struct ast_node *node, int reg)
{
	int opa, opb;
	int opcode;
	
	if(node->label[0] == 0) {
		/* AST node is a constant */
		opa = compiler_add_constant(sc, node->contents.constant);
		if(opa == -1) return -1;
		if(reg >= 0) {
			if(!compiler_add_isn(sc, PFPU_OPCODE_COPY, opa, 0, reg)) return -1;
		} else
			reg = opa;
		return reg;
	}
	if(node->contents.branches.a == NULL) {
		/* AST node is an input variable */
		opa = compiler_add_variable(sc, node->label);
		if(opa == -1) return -1;
		if(reg >= 0) {
			if(!compiler_add_isn(sc, PFPU_OPCODE_COPY, opa, 0, reg)) return -1;
		} else
			reg = opa;
		return reg;
	}
	/* AST node is an operator or function */
	opa = int_compile(sc, node->contents.branches.a, -1);
	if(opa == -1) return -1;
	opb = 0;
	if(node->contents.branches.b != NULL) {
		opb = int_compile(sc, node->contents.branches.b, -1);
		if(opb == -1) return -1;
	}
	
	if(reg < 0) reg = compiler_add_vreg(sc);
	if(reg < 0) return -1;
	opcode = operator2opcode(node->label);
	if(opcode < 0) return -1;
	if((opcode == PFPU_OPCODE_SIN)||(opcode == PFPU_OPCODE_COS)) {
		/*
		 * Trigo functions are implemented with several instructions
		 * because we must convert the floating point argument in radians
		 * from MilkDrop presets to an integer expressed in 1/8192 turns
		 * for PFPU hardware.
		 */
		int const_reg;
		int mul_reg;
		int f2i_reg;
		
		const_reg = compiler_add_constant(sc, PFPU_TRIG_CONV);
		mul_reg = compiler_add_vreg(sc);
		f2i_reg = compiler_add_vreg(sc);
		if((const_reg == -1)||(mul_reg == -1)||(f2i_reg == -1)) return -1;
		
		if(!compiler_add_isn(sc, PFPU_OPCODE_FMUL, const_reg, opa, mul_reg)) return -1;
		if(!compiler_add_isn(sc, PFPU_OPCODE_F2I, mul_reg, 0, f2i_reg)) return -1;
		if(!compiler_add_isn(sc, opcode, f2i_reg, 0, reg)) return -1;
	} else {
		if(!compiler_add_isn(sc, opcode, opa, opb, reg)) return -1;
	}
	
	return reg;
}

int compiler_compile_equation(struct compiler_state *sc, const char *target, struct ast_node *node)
{
	int reg;

	reg = compiler_add_variable(sc, target);
	if(reg < 0) return -1;
	reg = int_compile(sc, node, reg);
	
	return reg;
}

void compiler_get_initial_regs(struct compiler_state *sc, struct compiler_initial *initials, float *regs)
{
	int i;

	for(i=0;i<PFPU_REG_COUNT;i++) {
		regs[i] = 0.0f;
		if(sc->terminals[i].valid) {
			if(sc->terminals[i].isconst)
				regs[i] = sc->terminals[i].id.x;
			else {
				int j;

				for(j=0;j<PFPU_REG_COUNT;j++) {
					if(strcmp(sc->terminals[i].id.name, initials[j].name) == 0) {
						regs[i] = initials[j].x;
						break;
					}
				}
			}
		}
	}
}

void print_opcode(int opcode)
{
	switch(opcode) {
		case PFPU_OPCODE_NOP:   printf("NOP   "); break;
		case PFPU_OPCODE_FADD:  printf("FADD  "); break;
		case PFPU_OPCODE_FSUB:  printf("FSUB  "); break;
		case PFPU_OPCODE_FMUL:  printf("FMUL  "); break;
		case PFPU_OPCODE_FDIV:  printf("FDIV  "); break;
		case PFPU_OPCODE_F2I:   printf("F2I   "); break;
		case PFPU_OPCODE_I2F:   printf("I2F   "); break;
		case PFPU_OPCODE_VECT:  printf("VECT  "); break;
		case PFPU_OPCODE_SIN:   printf("SIN   "); break;
		case PFPU_OPCODE_COS:   printf("COS   "); break;
		case PFPU_OPCODE_ABOVE: printf("ABOVE "); break;
		case PFPU_OPCODE_EQUAL: printf("EQUAL "); break;
		case PFPU_OPCODE_COPY:  printf("COPY  "); break;
		default:                printf("XXX   "); break;
	}
}

int get_arity(int opcode)
{
	switch(opcode) {
		case PFPU_OPCODE_FADD:
		case PFPU_OPCODE_FSUB:
		case PFPU_OPCODE_FMUL:
		case PFPU_OPCODE_FDIV:
		case PFPU_OPCODE_VECT:
		case PFPU_OPCODE_EQUAL:
		case PFPU_OPCODE_ABOVE:
			return 2;
		case PFPU_OPCODE_F2I:
		case PFPU_OPCODE_I2F:
		case PFPU_OPCODE_SIN:
		case PFPU_OPCODE_COS:
		case PFPU_OPCODE_COPY:
			return 1;
		default:
			return 0;
	}
}

void print_vprogram(struct compiler_state *sc)
{
	int i;

	for(i=0;i<sc->prog_length;i++) {
		printf("%04d: ", i);
		print_opcode(sc->prog[i].opcode);
		switch(get_arity(sc->prog[i].opcode)) {
			case 2:
				printf("R%04d,R%04d ", sc->prog[i].opa, sc->prog[i].opb);
				break;
			case 1:
				printf("R%04d       ", sc->prog[i].opa);
				break;
			case 0:
				printf("            ");
		}
		printf("-> R%04d", sc->prog[i].dest);
		printf("\n");
	}
}

void print_terminals(struct compiler_state *sc)
{
	int i;

	for(i=0;i<PFPU_REG_COUNT;i++) {
		if(sc->terminals[i].valid) {
			printf("R%03d ", i);
			if(sc->terminals[i].isconst)
#ifdef EMULATION
				printf("%f\n", sc->terminals[i].id.x);
#else
				printf("%f\n", &sc->terminals[i].id.x);
#endif
			else
				printf("%s\n", sc->terminals[i].id.name);
		}
	}
}

