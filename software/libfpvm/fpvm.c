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
#include <base/version.h>

#include <fpvm/is.h>
#include <fpvm/fpvm.h>

#include "ast.h"
#include "parser_helper.h"

const char *fpvm_version()
{
	return VERSION;
}

void fpvm_init(struct fpvm_fragment *fragment, int vector_mode)
{
	fragment->last_error[0] = 0;

	fragment->nbindings = 3;
	fragment->bindings[0].isvar = 1;
	fragment->bindings[0].b.v[0] = '_';
	fragment->bindings[0].b.v[1] = 'X';
	fragment->bindings[0].b.v[2] = 'i';
	fragment->bindings[0].b.v[3] = 0;
	fragment->bindings[1].isvar = 1;
	fragment->bindings[1].b.v[0] = '_';
	fragment->bindings[1].b.v[1] = 'Y';
	fragment->bindings[1].b.v[2] = 'i';
	fragment->bindings[1].b.v[3] = 0;
	/* Prevent binding of R2 (we need it for "if") */
	fragment->bindings[2].isvar = 1;
	fragment->bindings[2].b.v[0] = 0;

	fragment->ntbindings = 2;
	fragment->tbindings[0].reg = -1;
	fragment->tbindings[0].sym[0] = '_';
	fragment->tbindings[0].sym[1] = 'X';
	fragment->tbindings[0].sym[2] = 'o';
	fragment->tbindings[0].sym[3] = 0;
	fragment->tbindings[1].reg = -2;
	fragment->tbindings[1].sym[0] = '_';
	fragment->tbindings[1].sym[1] = 'Y';
	fragment->tbindings[1].sym[2] = 'o';
	fragment->tbindings[1].sym[3] = 0;

	fragment->nrenamings = 0;

	fragment->next_sur = -3;
	fragment->ninstructions = 0;

	fragment->bind_mode = 0;
	fragment->vector_mode = vector_mode;
}

int fpvm_bind(struct fpvm_fragment *fragment, const char *sym)
{
	if(fragment->nbindings == FPVM_MAXBINDINGS) {
		snprintf(fragment->last_error, FPVM_MAXERRLEN, "Failed to allocate register for variable: %s", sym);
		return FPVM_INVALID_REG;
	}
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

	for(i=0;i<fragment->nrenamings;i++)
		if(strcmp(sym, fragment->renamings[i].sym) == 0)
			return fragment->renamings[i].reg;
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
	if(fragment->ntbindings == FPVM_MAXTBINDINGS) {
		snprintf(fragment->last_error, FPVM_MAXERRLEN, "Failed to allocate register for variable: %s", sym);
		return FPVM_INVALID_REG;
	}
	fragment->tbindings[fragment->ntbindings].reg = fragment->next_sur;
	strcpy(fragment->tbindings[fragment->ntbindings].sym, sym);
	fragment->ntbindings++;
	return fragment->next_sur--;
}

static int rename_reg(struct fpvm_fragment *fragment, const char *sym, int reg)
{
	int i;

	for(i=0;i<fragment->nrenamings;i++)
		if(strcmp(sym, fragment->renamings[i].sym) == 0) {
			fragment->renamings[i].reg = reg;
			return 1;
		}
	if(fragment->nrenamings == FPVM_MAXRENAMINGS) {
		snprintf(fragment->last_error, FPVM_MAXERRLEN, "Failed to allocate renamed register for variable: %s", sym);
		return 0;
	}
	fragment->renamings[fragment->nrenamings].reg = reg;
	strcpy(fragment->renamings[fragment->nrenamings].sym, sym);
	fragment->nrenamings++;
	return 1;
}

static int sym_to_reg(struct fpvm_fragment *fragment, const char *sym, int *created)
{
	int r;
	if(created) *created = 0;
	r = lookup(fragment, sym);
	if(r == FPVM_INVALID_REG) {
		if(created) *created = 1;
		if(fragment->bind_mode)
			r = fpvm_bind(fragment, sym);
		else
			r = tbind(fragment, sym);
	}
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
	if(fragment->nbindings == FPVM_MAXBINDINGS) {
		snprintf(fragment->last_error, FPVM_MAXERRLEN, "Failed to allocate register for constant");
		return FPVM_INVALID_REG;
	}
	fragment->bindings[fragment->nbindings].isvar = 0;
	fragment->bindings[fragment->nbindings].b.c = c;
	return fragment->nbindings++;
}

static int find_negative_constant(struct fpvm_fragment *fragment)
{
	int i;

	for(i=0;i<fragment->nbindings;i++) {
		if(!fragment->bindings[i].isvar &&
			(fragment->bindings[i].b.c < 0.0))
			return i;
	}
	return const_to_reg(fragment, -1.0);
}

static int add_isn(struct fpvm_fragment *fragment, int opcode, int opa, int opb, int dest)
{
	int len;

	len = fragment->ninstructions;
	if(len >= FPVM_MAXCODELEN) {
		snprintf(fragment->last_error, FPVM_MAXERRLEN, "Ran out of program space");
		return 0;
	}

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
	if(strcmp(operator, "abs") == 0) return FPVM_OPCODE_FABS;
	if(strcmp(operator, "isin") == 0) return FPVM_OPCODE_SIN;
	if(strcmp(operator, "icos") == 0) return FPVM_OPCODE_COS;
	if(strcmp(operator, "above") == 0) return FPVM_OPCODE_ABOVE;
	if(strcmp(operator, "equal") == 0) return FPVM_OPCODE_EQUAL;
	if(strcmp(operator, "i2f") == 0) return FPVM_OPCODE_I2F;
	if(strcmp(operator, "f2i") == 0) return FPVM_OPCODE_F2I;
	if(strcmp(operator, "if") == 0) return FPVM_OPCODE_IF;
	if(strcmp(operator, "tsign") == 0) return FPVM_OPCODE_TSIGN;
	if(strcmp(operator, "quake") == 0) return FPVM_OPCODE_QUAKE;
	else return -1;
}

static int add_inv_sqrt_step(struct fpvm_fragment *fragment, int reg_y, int reg_x, int reg_out)
{
	int reg_onehalf;
	int reg_twohalf;
	int reg_yy;
	int reg_hx;
	int reg_hxyy;
	int reg_sub;

	reg_yy = fragment->next_sur--;
	reg_hx = fragment->next_sur--;
	reg_hxyy = fragment->next_sur--;
	reg_sub = fragment->next_sur--;

	reg_onehalf = const_to_reg(fragment, 0.5f);
	if(reg_onehalf == FPVM_INVALID_REG) return 0;
	reg_twohalf = const_to_reg(fragment, 1.5f);
	if(reg_twohalf == FPVM_INVALID_REG) return 0;

	if(!add_isn(fragment, FPVM_OPCODE_FMUL, reg_y, reg_y, reg_yy)) return 0;
	if(!add_isn(fragment, FPVM_OPCODE_FMUL, reg_onehalf, reg_x, reg_hx)) return 0;
	if(!add_isn(fragment, FPVM_OPCODE_FMUL, reg_hx, reg_yy, reg_hxyy)) return 0;
	if(!add_isn(fragment, FPVM_OPCODE_FSUB, reg_twohalf, reg_hxyy, reg_sub)) return 0;
	if(!add_isn(fragment, FPVM_OPCODE_FMUL, reg_sub, reg_y, reg_out)) return 0;

	return 1;
}

static int add_inv_sqrt(struct fpvm_fragment *fragment, int reg_in, int reg_out)
{
	int reg_y, reg_y2;

	reg_y = fragment->next_sur--;
	reg_y2 = fragment->next_sur--;

	if(!add_isn(fragment, FPVM_OPCODE_QUAKE, reg_in, 0, reg_y)) return 0;
	if(!add_inv_sqrt_step(fragment, reg_y, reg_in, reg_y2)) return 0;
	if(!add_inv_sqrt_step(fragment, reg_y2, reg_in, reg_out)) return 0;

	return 1;
}

static int add_int(struct fpvm_fragment *fragment, int reg_in, int reg_out)
{
	int reg_i;

	reg_i = fragment->next_sur--;
	if(!add_isn(fragment, FPVM_OPCODE_F2I, reg_in, 0, reg_i)) return FPVM_INVALID_REG;
	if(!add_isn(fragment, FPVM_OPCODE_I2F, reg_i, 0, reg_out)) return FPVM_INVALID_REG;
	return 1;
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
		if(fragment->bind_mode) {
			opa = sym_to_reg(fragment, node->label, NULL);
			if(opa == FPVM_INVALID_REG) return FPVM_INVALID_REG;
		} else {
			opa = lookup(fragment, node->label);
			if((opa == FPVM_INVALID_REG)||(opa == fragment->final_dest)) {
				snprintf(fragment->last_error, FPVM_MAXERRLEN, "Reading unbound variable: %s", node->label);
				return FPVM_INVALID_REG;
			}
		}
		if(reg != FPVM_INVALID_REG) {
			if(!add_isn(fragment, FPVM_OPCODE_COPY, opa, 0, reg)) return FPVM_INVALID_REG;
		} else
			reg = opa;
		return reg;
	}
	if((strcmp(node->label, "!") == 0) && (node->contents.branches.a->label[0] == 0)) {
		/* Node is a negative constant */
		struct ast_node *n;

		n = node->contents.branches.a;
		opa = const_to_reg(fragment, -n->contents.constant);
		if(opa == FPVM_INVALID_REG) return FPVM_INVALID_REG;
		if(reg != FPVM_INVALID_REG) {
			if(!add_isn(fragment, FPVM_OPCODE_COPY, opa, 0, reg)) return FPVM_INVALID_REG;
		} else
			reg = opa;
		return reg;
	}
	/* AST node is an operator or function */
	if(strcmp(node->label, "if") == 0) {
		/*
		 * "if" must receive a special treatment.
		 * It is implemented as a ternary function,
		 * but its first parameter is hardwired to R2 (FPVM_REG_IFB) and implicit.
		 * We must compute the other parameters first, as they may clobber R2.
		 */
		opa = compile(fragment, FPVM_INVALID_REG, node->contents.branches.b);
		if(opa == FPVM_INVALID_REG) return FPVM_INVALID_REG;
		opb = compile(fragment, FPVM_INVALID_REG, node->contents.branches.c);
		if(opb == FPVM_INVALID_REG) return FPVM_INVALID_REG;
		if(compile(fragment, FPVM_REG_IFB, node->contents.branches.a) == FPVM_INVALID_REG)
			return FPVM_INVALID_REG;
	} else {
		opa = compile(fragment, FPVM_INVALID_REG, node->contents.branches.a);
		if(opa == FPVM_INVALID_REG) return FPVM_INVALID_REG;
		opb = 0;
		if(node->contents.branches.b != NULL) {
			opb = compile(fragment, FPVM_INVALID_REG, node->contents.branches.b);
			if(opb == FPVM_INVALID_REG) return FPVM_INVALID_REG;
		}
	}

	if(reg == FPVM_INVALID_REG) reg = fragment->next_sur--;
	if(strcmp(node->label, "below") == 0) {
		/*
		 * "below" is like "above", but with reversed operands.
		 */
		if(!add_isn(fragment, FPVM_OPCODE_ABOVE, opb, opa, reg)) return FPVM_INVALID_REG;
	} else if((strcmp(node->label, "sin") == 0)||(strcmp(node->label, "cos") == 0)) {
		/*
		 * Trigo functions are implemented with several instructions.
		 * We must convert the floating point argument in radians
		 * to an integer expressed in 1/8192 turns for FPVM.
		 */
		int reg_const;
		int reg_mul;
		int reg_f2i;

		if(strcmp(node->label, "sin") == 0)
			opcode = FPVM_OPCODE_SIN;
		else
			opcode = FPVM_OPCODE_COS;

		reg_const = const_to_reg(fragment, FPVM_TRIG_CONV);
		if(reg_const == FPVM_INVALID_REG) return FPVM_INVALID_REG;
		reg_mul = fragment->next_sur--;
		reg_f2i = fragment->next_sur--;

		if(!add_isn(fragment, FPVM_OPCODE_FMUL, reg_const, opa, reg_mul)) return FPVM_INVALID_REG;
		if(!add_isn(fragment, FPVM_OPCODE_F2I, reg_mul, 0, reg_f2i)) return FPVM_INVALID_REG;
		if(!add_isn(fragment, opcode, reg_f2i, 0, reg)) return FPVM_INVALID_REG;
	} else if(strcmp(node->label, "sqrt") == 0) {
		/*
		 * Square root is implemented with a variant of the Quake III algorithm.
		 * See http://en.wikipedia.org/wiki/Fast_inverse_square_root
		 * sqrt(x) = x*(1/sqrt(x))
		 */
		int reg_invsqrt;
		reg_invsqrt = fragment->next_sur--;
		if(!add_inv_sqrt(fragment, opa, reg_invsqrt)) return FPVM_INVALID_REG;
		if(!add_isn(fragment, FPVM_OPCODE_FMUL, opa, reg_invsqrt, reg)) return FPVM_INVALID_REG;
	} else if(strcmp(node->label, "invsqrt") == 0) {
		if(!add_inv_sqrt(fragment, opa, reg)) return FPVM_INVALID_REG;
	} else if(strcmp(node->label, "/") == 0) {
		/*
		 * Floating point division is implemented as
		 * a/b = a*(1/sqrt(b))*(1/sqrt(b))
		 */
		int reg_a2;
		int reg_b2;
		int reg_invsqrt;
		int reg_invsqrt2;

		reg_a2 = fragment->next_sur--;
		reg_b2 = fragment->next_sur--;
		reg_invsqrt = fragment->next_sur--;
		reg_invsqrt2 = fragment->next_sur--;

		/* Transfer the sign of the result to a and make b positive */
		if(!add_isn(fragment, FPVM_OPCODE_TSIGN, opa, opb, reg_a2)) return FPVM_INVALID_REG;
		if(!add_isn(fragment, FPVM_OPCODE_FABS, opb, 0, reg_b2)) return FPVM_INVALID_REG;

		if(!add_inv_sqrt(fragment, reg_b2, reg_invsqrt)) return FPVM_INVALID_REG;
		if(!add_isn(fragment, FPVM_OPCODE_FMUL, reg_invsqrt, reg_invsqrt, reg_invsqrt2)) return FPVM_INVALID_REG;
		if(!add_isn(fragment, FPVM_OPCODE_FMUL, reg_invsqrt2, reg_a2, reg)) return FPVM_INVALID_REG;
	} else if(strcmp(node->label, "%") == 0) {
		int reg_invsqrt;
		int reg_invsqrt2;
		int reg_div;
		int reg_idiv;
		int reg_bidiv;

		reg_invsqrt = fragment->next_sur--;
		reg_invsqrt2 = fragment->next_sur--;
		reg_div = fragment->next_sur--;
		reg_idiv = fragment->next_sur--;
		reg_bidiv = fragment->next_sur--;

		if(!add_inv_sqrt(fragment, opb, reg_invsqrt)) return FPVM_INVALID_REG;
		if(!add_isn(fragment, FPVM_OPCODE_FMUL, reg_invsqrt, reg_invsqrt, reg_invsqrt2)) return FPVM_INVALID_REG;
		if(!add_isn(fragment, FPVM_OPCODE_FMUL, reg_invsqrt2, opa, reg_div)) return FPVM_INVALID_REG;
		if(!add_int(fragment, reg_div, reg_idiv)) return FPVM_INVALID_REG;
		if(!add_isn(fragment, FPVM_OPCODE_FMUL, opb, reg_idiv, reg_bidiv)) return FPVM_INVALID_REG;
		if(!add_isn(fragment, FPVM_OPCODE_FSUB, opa, reg_bidiv, reg)) return FPVM_INVALID_REG;
	} else if(strcmp(node->label, "min") == 0) {
		if(!add_isn(fragment, FPVM_OPCODE_ABOVE, opa, opb, FPVM_REG_IFB)) return FPVM_INVALID_REG;
		if(!add_isn(fragment, FPVM_OPCODE_IF, opb, opa, reg)) return FPVM_INVALID_REG;
	} else if(strcmp(node->label, "max") == 0) {
		if(!add_isn(fragment, FPVM_OPCODE_ABOVE, opa, opb, FPVM_REG_IFB)) return FPVM_INVALID_REG;
		if(!add_isn(fragment, FPVM_OPCODE_IF, opa, opb, reg)) return FPVM_INVALID_REG;
	} else if(strcmp(node->label, "sqr") == 0) {
		if(!add_isn(fragment, FPVM_OPCODE_FMUL, opa, opa, reg)) return FPVM_INVALID_REG;
	} else if(strcmp(node->label, "int") == 0) {
		if(!add_int(fragment, opa, reg)) return FPVM_INVALID_REG;
	} else if(strcmp(node->label, "!") == 0) {
		opb = find_negative_constant(fragment);
		if(opb == FPVM_INVALID_REG) return FPVM_INVALID_REG;
		if(!add_isn(fragment, FPVM_OPCODE_TSIGN, opa, opb, reg)) return FPVM_INVALID_REG;
	} else {
		/* Normal case */
		opcode = operator2opcode(node->label);
		if(opcode < 0) {
			snprintf(fragment->last_error, FPVM_MAXERRLEN, "Operation not supported: %s", node->label);
			return FPVM_INVALID_REG;
		}
		if(!add_isn(fragment, opcode, opa, opb, reg)) return FPVM_INVALID_REG;
	}

	return reg;
}

struct fpvm_backup {
	int ntbindings;
	int next_sur;
	int ninstructions;
};

static void fragment_backup(struct fpvm_fragment *fragment, struct fpvm_backup *backup)
{
	backup->ntbindings = fragment->ntbindings;
	backup->next_sur = fragment->next_sur;
	backup->ninstructions = fragment->ninstructions;
}

static void fragment_restore(struct fpvm_fragment *fragment, struct fpvm_backup *backup)
{
	fragment->ntbindings = backup->ntbindings;
	fragment->next_sur = backup->next_sur;
	fragment->ninstructions = backup->ninstructions;
}

int fpvm_assign(struct fpvm_fragment *fragment, const char *dest, const char *expr)
{
	struct ast_node *n;
	int dest_reg;
	struct fpvm_backup backup;
	int created;
	int use_renaming;

	n = fpvm_parse(expr);
	if(n == NULL) {
		snprintf(fragment->last_error, FPVM_MAXERRLEN, "Parse error");
		return 0;
	}

	fragment_backup(fragment, &backup);

	use_renaming = fragment->vector_mode
		&& (strcmp(dest, fragment->tbindings[0].sym) != 0) /* do not rename output X and Y */
		&& (strcmp(dest, fragment->tbindings[1].sym) != 0);
	if(use_renaming) {
		dest_reg = fragment->next_sur;
		fragment->next_sur--;
		created = 1;
	} else
		dest_reg = sym_to_reg(fragment, dest, &created);
	if(dest_reg == FPVM_INVALID_REG) {
		snprintf(fragment->last_error, FPVM_MAXERRLEN, "Failed to allocate register for destination");
		fpvm_parse_free(n);
		fragment_restore(fragment, &backup);
		return 0;
	}

	if(created)
		fragment->final_dest = dest_reg;
	else
		fragment->final_dest = FPVM_INVALID_REG;
	if(compile(fragment, dest_reg, n) == FPVM_INVALID_REG) {
		fpvm_parse_free(n);
		fragment_restore(fragment, &backup);
		return 0;
	}
	if(use_renaming) {
		if(!rename_reg(fragment, dest, dest_reg)) {
			fpvm_parse_free(n);
			fragment_restore(fragment, &backup);
			return 0;
		}
	}

	fpvm_parse_free(n);
	return 1;
}

void fpvm_get_references(struct fpvm_fragment *fragment, int *references)
{
	int i;

	for(i=0;i<FPVM_MAXBINDINGS;i++)
		references[i] = 0;
	for(i=0;i<fragment->ninstructions;i++) {
		if(fragment->code[i].opcode == FPVM_OPCODE_IF)
			references[2] = 1;
		if(fragment->code[i].opa > 0)
			references[fragment->code[i].opa] = 1;
		if(fragment->code[i].opb > 0)
			references[fragment->code[i].opb] = 1;
		if(fragment->code[i].dest > 0)
			references[fragment->code[i].dest] = 1;
	}
}

int fpvm_finalize(struct fpvm_fragment *fragment)
{
	if(fragment->vector_mode)
		return add_isn(fragment, FPVM_OPCODE_VECTOUT, -1, -2, 0);
	else
		return 1;
}

void fpvm_print_opcode(int opcode)
{
	switch(opcode) {
		case FPVM_OPCODE_NOP:     printf("NOP     "); break;
		case FPVM_OPCODE_FADD:    printf("FADD    "); break;
		case FPVM_OPCODE_FSUB:    printf("FSUB    "); break;
		case FPVM_OPCODE_FMUL:    printf("FMUL    "); break;
		case FPVM_OPCODE_FABS:    printf("FABS    "); break;
		case FPVM_OPCODE_F2I:     printf("F2I     "); break;
		case FPVM_OPCODE_I2F:     printf("I2F     "); break;
		case FPVM_OPCODE_VECTOUT: printf("VECTOUT "); break;
		case FPVM_OPCODE_SIN:     printf("SIN     "); break;
		case FPVM_OPCODE_COS:     printf("COS     "); break;
		case FPVM_OPCODE_ABOVE:   printf("ABOVE   "); break;
		case FPVM_OPCODE_EQUAL:   printf("EQUAL   "); break;
		case FPVM_OPCODE_COPY:    printf("COPY    "); break;
		case FPVM_OPCODE_IF:      printf("IF<R2>  "); break;
		case FPVM_OPCODE_TSIGN:   printf("TSIGN   "); break;
		case FPVM_OPCODE_QUAKE:   printf("QUAKE   "); break;
		default:                  printf("XXX     "); break;
	}
}

int fpvm_get_arity(int opcode)
{
	switch(opcode) {
		case FPVM_OPCODE_IF:
			return 3;
		case FPVM_OPCODE_FADD:
		case FPVM_OPCODE_FSUB:
		case FPVM_OPCODE_FMUL:
		case FPVM_OPCODE_VECTOUT:
		case FPVM_OPCODE_EQUAL:
		case FPVM_OPCODE_ABOVE:
		case FPVM_OPCODE_TSIGN:
			return 2;
		case FPVM_OPCODE_FABS:
		case FPVM_OPCODE_F2I:
		case FPVM_OPCODE_I2F:
		case FPVM_OPCODE_SIN:
		case FPVM_OPCODE_COS:
		case FPVM_OPCODE_COPY:
		case FPVM_OPCODE_QUAKE:
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
		printf("R%04d ", i);
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
		printf("R%04d ", fragment->tbindings[i].reg);
		printf("%s\n", fragment->tbindings[i].sym);
	}
	printf("== Code:\n");
	for(i=0;i<fragment->ninstructions;i++) {
		printf("%04d: ", i);
		fpvm_print_opcode(fragment->code[i].opcode);
		switch(fpvm_get_arity(fragment->code[i].opcode)) {
			case 3:
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
		if(fragment->code[i].dest != 0)
			printf("-> R%04d", fragment->code[i].dest);
		printf("\n");
	}
}
