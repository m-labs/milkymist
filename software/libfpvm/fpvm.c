/*
 * Milkymist VJ SoC (Software)
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

#include <string.h>
#include <stdio.h>

#include <fpvm/is.h>
#include <fpvm/fpvm.h>

#include "ast.h"
#include "parser_helper.h"

void fpvm_init(struct fpvm_fragment *fragment)
{
	fragment->nbindings = 3;
	fragment->bindings[0].isvar = 1;
	fragment->bindings[0].b.v[0] = 'X';
	fragment->bindings[0].b.v[1] = 'i';
	fragment->bindings[0].b.v[2] = 0;
	fragment->bindings[1].isvar = 1;
	fragment->bindings[1].b.v[0] = 'Y';
	fragment->bindings[1].b.v[1] = 'i';
	fragment->bindings[1].b.v[2] = 0;
	fragment->bindings[2].isvar = 1; /* flags */
	fragment->bindings[2].b.v[0] = 0;

	fragment->ntbindings = 2;
	fragment->tbindings[0].reg = -1;
	fragment->tbindings[0].sym[0] = 'X';
	fragment->tbindings[0].sym[1] = 'o';
	fragment->tbindings[0].sym[2] = 0;
	fragment->tbindings[1].reg = -2;
	fragment->tbindings[1].sym[0] = 'Y';
	fragment->tbindings[1].sym[1] = 'o';
	fragment->tbindings[1].sym[2] = 0;
	
	fragment->next_sur = -3;
	fragment->ninstructions = 0;
}

int fpvm_bind(struct fpvm_fragment *fragment, const char *sym)
{
	if(fragment->nbindings == FPVM_MAXBINDINGS) return -1;
	fragment->bindings[fragment->nbindings].isvar = 1;
	strcpy(fragment->bindings[fragment->nbindings].b.v, sym);
	return fragment->nbindings++;
}

void fpvm_set_xin(struct fpvm_fragment *fragment, const char *sym)
{
	strcpy(fragment->bindings[0].b.v, sym);
}

void fpvm_set_yin(struct fpvm_fragment *fragment, const char *sym)
{
	strcpy(fragment->bindings[1].b.v, sym);
}

void fpvm_set_xout(struct fpvm_fragment *fragment, const char *sym)
{
	strcpy(fragment->tbindings[0].sym, sym);
}

void fpvm_set_yout(struct fpvm_fragment *fragment, const char *sym)
{
	strcpy(fragment->tbindings[1].sym, sym);
}

static int lookup(struct fpvm_fragment *fragment, const char *sym)
{
	int i;

	for(i=0;i<fragment->nbindings;i++)
		if(fragment->bindings[i].isvar &&
			(strcmp(sym, fragment->bindings[i].b.v) == 0))
			return i;
	for(i=0;i<fragment->ntbindings;i++)
		if(strcmp(sym, fragment->tbindings[i].sym) == 0)
			return fragment->tbindings[i].reg;
	return FPVM_INVALID_REG;
}

static int tbind(struct fpvm_fragment *fragment, const char *sym)
{
	if(fragment->ntbindings == FPVM_MAXTBINDINGS) return FPVM_INVALID_REG;
	fragment->tbindings[fragment->ntbindings].reg = fragment->next_sur;
	strcpy(fragment->tbindings[fragment->ntbindings].sym, sym);
	fragment->ntbindings++;
	return fragment->next_sur--;
}

static int sym_to_reg(struct fpvm_fragment *fragment, const char *sym)
{
	int r;
	r = lookup(fragment, sym);
	if(r == FPVM_INVALID_REG)
		r = tbind(fragment, sym);
	return r;
}

static int const_to_reg(struct fpvm_fragment *fragment, float c)
{
	int i;

	for(i=0;i<fragment->nbindings;i++) {
		if(!fragment->bindings[i].isvar &&
			(fragment->bindings[i].b.c == c))
			return i;
	}
	/* not already bound */
	if(fragment->nbindings == FPVM_MAXBINDINGS)
		return FPVM_INVALID_REG;
	fragment->bindings[fragment->nbindings].isvar = 0;
	fragment->bindings[fragment->nbindings].b.c = c;
	return fragment->nbindings++;
}

static int add_isn(struct fpvm_fragment *fragment, int opcode, int opa, int opb, int dest)
{
	int len;

	len = fragment->ninstructions;
	if(len >= FPVM_MAXCODELEN) return 0;

	fragment->code[len].opa = opa;
	fragment->code[len].opb = opb;
	fragment->code[len].opcode = opcode;
	fragment->code[len].dest = dest;

	fragment->ninstructions++;
	return 1;
}

static int operator2opcode(const char *operator)
{
	if(strcmp(operator, "+") == 0) return FPVM_OPCODE_FADD;
	if(strcmp(operator, "-") == 0) return FPVM_OPCODE_FSUB;
	if(strcmp(operator, "*") == 0) return FPVM_OPCODE_FMUL;
	if(strcmp(operator, "/") == 0) return FPVM_OPCODE_FDIV;
	if(strcmp(operator, "sin") == 0) return FPVM_OPCODE_SIN;
	if(strcmp(operator, "cos") == 0) return FPVM_OPCODE_COS;
	if(strcmp(operator, "above") == 0) return FPVM_OPCODE_ABOVE;
	if(strcmp(operator, "equal") == 0) return FPVM_OPCODE_EQUAL;
	else return -1;
}

/*
 * Compiles a node.
 * Returns the register the result of the node gets written to,
 * and FPVM_INVALID_REG in case of error.
 * If reg != FPVM_INVALID_REG,
 * it forces the result to be written to this particular register.
 */
static int compile(struct fpvm_fragment *fragment, int reg, struct ast_node *node)
{
	int opa, opb;
	int opcode;

	if(node->label[0] == 0) {
		/* AST node is a constant */
		opa = const_to_reg(fragment, node->contents.constant);
		if(opa == FPVM_INVALID_REG) return FPVM_INVALID_REG;
		if(reg != FPVM_INVALID_REG) {
			if(!add_isn(fragment, FPVM_OPCODE_COPY, opa, 0, reg)) return FPVM_INVALID_REG;
		} else
			reg = opa;
		return reg;
	}
	if(node->contents.branches.a == NULL) {
		/* AST node is a variable */
		opa = sym_to_reg(fragment, node->label);
		if(opa == FPVM_INVALID_REG) return FPVM_INVALID_REG;
		if(reg != FPVM_INVALID_REG) {
			if(!add_isn(fragment, FPVM_OPCODE_COPY, opa, 0, reg)) return FPVM_INVALID_REG;
		} else
			reg = opa;
		return reg;
	}
	/* AST node is an operator or function */
	opa = compile(fragment, FPVM_INVALID_REG, node->contents.branches.a);
	if(opa == FPVM_INVALID_REG) return FPVM_INVALID_REG;
	opb = 0;
	if(node->contents.branches.b != NULL) {
		opb = compile(fragment, FPVM_INVALID_REG, node->contents.branches.b);
		if(opb == FPVM_INVALID_REG) return FPVM_INVALID_REG;
	}

	if(reg == FPVM_INVALID_REG) reg = fragment->next_sur--;
	opcode = operator2opcode(node->label);
	if(opcode < 0) return -1;
	if((opcode == FPVM_OPCODE_SIN)||(opcode == FPVM_OPCODE_COS)) {
		/*
		 * Trigo functions are implemented with several instructions
		 * because we must convert the floating point argument in radians
		 * from MilkDrop presets to an integer expressed in 1/8192 turns
		 * for FPVM hardware.
		 */
		int const_reg;
		int mul_reg;
		int f2i_reg;

		const_reg = const_to_reg(fragment, FPVM_TRIG_CONV);
		if(const_reg == FPVM_INVALID_REG) return FPVM_INVALID_REG;
		mul_reg = fragment->next_sur--;
		f2i_reg = fragment->next_sur--;

		if(!add_isn(fragment, FPVM_OPCODE_FMUL, const_reg, opa, mul_reg)) return FPVM_INVALID_REG;
		if(!add_isn(fragment, FPVM_OPCODE_F2I, mul_reg, 0, f2i_reg)) return FPVM_INVALID_REG;
		if(!add_isn(fragment, opcode, f2i_reg, 0, reg)) return FPVM_INVALID_REG;
	} else {
		if(!add_isn(fragment, opcode, opa, opb, reg)) return FPVM_INVALID_REG;
	}

	return reg;
}

int fpvm_assign(struct fpvm_fragment *fragment, const char *dest, const char *expr)
{
	struct ast_node *n;
	int dest_reg;

	n = fpvm_parse(expr);
	if(n == NULL) return 0;

	dest_reg = sym_to_reg(fragment, dest);
	if(dest_reg == FPVM_INVALID_REG) {
		fpvm_parse_free(n);
		return 0;
	}

	if(compile(fragment, dest_reg, n) == FPVM_INVALID_REG) {
		fpvm_parse_free(n);
		return 0;
	}

	fpvm_parse_free(n);
	return 1;
}

int fpvm_done(struct fpvm_fragment *fragment)
{
	return add_isn(fragment, FPVM_OPCODE_VECTOUT, -1, -2, 0);
}

static void print_opcode(int opcode)
{
	switch(opcode) {
		case FPVM_OPCODE_NOP:     printf("NOP     "); break;
		case FPVM_OPCODE_FADD:    printf("FADD    "); break;
		case FPVM_OPCODE_FSUB:    printf("FSUB    "); break;
		case FPVM_OPCODE_FMUL:    printf("FMUL    "); break;
		case FPVM_OPCODE_FDIV:    printf("FDIV    "); break;
		case FPVM_OPCODE_F2I:     printf("F2I     "); break;
		case FPVM_OPCODE_I2F:     printf("I2F     "); break;
		case FPVM_OPCODE_VECTOUT: printf("VECTOUT "); break;
		case FPVM_OPCODE_SIN:     printf("SIN     "); break;
		case FPVM_OPCODE_COS:     printf("COS     "); break;
		case FPVM_OPCODE_ABOVE:   printf("ABOVE   "); break;
		case FPVM_OPCODE_EQUAL:   printf("EQUAL   "); break;
		case FPVM_OPCODE_COPY:    printf("COPY    "); break;
		default:                  printf("XXX     "); break;
	}
}

static int get_arity(int opcode)
{
	switch(opcode) {
		case FPVM_OPCODE_FADD:
		case FPVM_OPCODE_FSUB:
		case FPVM_OPCODE_FMUL:
		case FPVM_OPCODE_FDIV:
		case FPVM_OPCODE_VECTOUT:
		case FPVM_OPCODE_EQUAL:
		case FPVM_OPCODE_ABOVE:
			return 2;
		case FPVM_OPCODE_F2I:
		case FPVM_OPCODE_I2F:
		case FPVM_OPCODE_SIN:
		case FPVM_OPCODE_COS:
		case FPVM_OPCODE_COPY:
			return 1;
		default:
			return 0;
	}
}

void fpvm_dump(struct fpvm_fragment *fragment)
{
	int i;
	
	printf("== Permanent bindings:\n");
	for(i=0;i<fragment->nbindings;i++) {
		printf("R%03d ", i);
		if(fragment->bindings[i].isvar)
			printf("%s\n", fragment->bindings[i].b.v);
		else
#ifdef PRINTF_FLOAT
			printf("%f\n", fragment->bindings[i].b.c);
#else
			printf("%f\n", &fragment->bindings[i].b.c);
#endif
	}
	printf("== Transient bindings:\n");
	for(i=0;i<fragment->ntbindings;i++) {
		printf("R%03d ", fragment->tbindings[i].reg);
		printf("%s\n", fragment->tbindings[i].sym);
	}
	printf("== Code:\n");
	for(i=0;i<fragment->ninstructions;i++) {
		printf("%04d: ", i);
		print_opcode(fragment->code[i].opcode);
		switch(get_arity(fragment->code[i].opcode)) {
			case 2:
				printf("R%04d,R%04d ", fragment->code[i].opa, fragment->code[i].opb);
				break;
			case 1:
				printf("R%04d       ", fragment->code[i].opa);
				break;
			case 0:
				printf("            ");
				break;
		}
		printf("-> R%04d", fragment->code[i].dest);
		printf("\n");
	}
}
