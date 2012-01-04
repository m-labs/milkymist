/*
 * Milkymist SoC (Software)
 * Copyright (C) 2007, 2008, 2009, 2010, 2011 Sebastien Bourdeauducq
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
#include <base/version.h>

#include <fpvm/is.h>
#include <fpvm/symbol.h>
#include <fpvm/fpvm.h>
#include <fpvm/ast.h>


struct sym *_Xi, *_Yi, *_Xo, *_Yo; /* unique, provided by user of libfpvm */

static struct sym dummy_sym = { .name = "" };

const char *fpvm_version(void)
{
	return VERSION;
}

void fpvm_do_init(struct fpvm_fragment *fragment, int vector_mode)
{
	fragment->last_error[0] = 0;
	fragment->bind_callback = NULL;
	fragment->bind_callback_user = NULL;

	fragment->nbindings = 3;
	fragment->bindings[0].isvar = 1;
	fragment->bindings[0].b.v = _Xi;
	fragment->bindings[1].isvar = 1;
	fragment->bindings[1].b.v = _Yi;
	/* Prevent binding of R2 (we need it for "if") */
	fragment->bindings[2].isvar = 1;
	fragment->bindings[2].b.v = &dummy_sym;

	fragment->ntbindings = 2;
	fragment->tbindings[0].reg = -1;
	fragment->tbindings[0].sym = _Xo;
	fragment->tbindings[1].reg = -2;
	fragment->tbindings[1].sym = _Yo;

	fragment->nrenamings = 0;

	fragment->next_sur = -3;
	fragment->ninstructions = 0;

	fragment->bind_mode = FPVM_BIND_NONE;
	fragment->vector_mode = vector_mode;
}

const char *fpvm_get_last_error(struct fpvm_fragment *fragment)
{
	return fragment->last_error;
}

void fpvm_set_bind_callback(struct fpvm_fragment *fragment,
    fpvm_bind_callback callback, void *user)
{
	fragment->bind_callback = callback;
	fragment->bind_callback_user = user;
}

void fpvm_set_bind_mode(struct fpvm_fragment *fragment, int bind_mode)
{
	fragment->bind_mode = bind_mode;
}

int fpvm_bind(struct fpvm_fragment *fragment, struct sym *sym)
{
	int r;
	
	if(fragment->nbindings == FPVM_MAXBINDINGS) {
		snprintf(fragment->last_error, FPVM_MAXERRLEN,
		    "Failed to allocate register for variable: %s", sym->name);
		return FPVM_INVALID_REG;
	}
	r = fragment->nbindings++;
	fragment->bindings[r].isvar = 1;
	fragment->bindings[r].b.v = sym;
	if(fragment->bind_callback != NULL)
		fragment->bind_callback(fragment->bind_callback_user, sym, r);
	return r;
}

void fpvm_set_xin(struct fpvm_fragment *fragment, struct sym *sym)
{
	fragment->bindings[0].b.v = sym;
}

void fpvm_set_yin(struct fpvm_fragment *fragment, struct sym *sym)
{
	fragment->bindings[1].b.v = sym;
}

void fpvm_set_xout(struct fpvm_fragment *fragment, struct sym *sym)
{
	fragment->tbindings[0].sym = sym;
}

void fpvm_set_yout(struct fpvm_fragment *fragment, struct sym *sym)
{
	fragment->tbindings[1].sym = sym;
}

static int lookup(struct fpvm_fragment *fragment, struct sym *sym)
{
	int i;

	for(i=0;i<fragment->nrenamings;i++)
		if(sym == fragment->renamings[i].sym)
			return fragment->renamings[i].reg;
	for(i=0;i<fragment->nbindings;i++)
		if(fragment->bindings[i].isvar &&
			(sym == fragment->bindings[i].b.v))
			return i;
	for(i=0;i<fragment->ntbindings;i++)
		if(sym == fragment->tbindings[i].sym)
			return fragment->tbindings[i].reg;
	return FPVM_INVALID_REG;
}

static int tbind(struct fpvm_fragment *fragment, struct sym *sym)
{
	if(fragment->ntbindings == FPVM_MAXTBINDINGS) {
		snprintf(fragment->last_error, FPVM_MAXERRLEN,
		    "Failed to allocate register for variable: %s", sym->name);
		return FPVM_INVALID_REG;
	}
	fragment->tbindings[fragment->ntbindings].reg = fragment->next_sur;
	fragment->tbindings[fragment->ntbindings].sym = sym;
	fragment->ntbindings++;
	return fragment->next_sur--;
}

static int rename_reg(struct fpvm_fragment *fragment, struct sym *sym, int reg)
{
	int i;

	for(i=0;i<fragment->nrenamings;i++)
		if(sym == fragment->renamings[i].sym) {
			fragment->renamings[i].reg = reg;
			return 1;
		}
	if(fragment->nrenamings == FPVM_MAXRENAMINGS) {
		snprintf(fragment->last_error, FPVM_MAXERRLEN,
		    "Failed to allocate renamed register for variable: %s",
		    sym->name);
		return 0;
	}
	fragment->renamings[fragment->nrenamings].reg = reg;
	fragment->renamings[fragment->nrenamings].sym = sym;
	fragment->nrenamings++;
	return 1;
}

static int sym_to_reg(struct fpvm_fragment *fragment, struct sym *sym,
    int dest, int *created)
{
	int r;
	if(created) *created = 0;
	r = lookup(fragment, sym);
	if(r == FPVM_INVALID_REG) {
		if(created) *created = 1;
		if((fragment->bind_mode == FPVM_BIND_ALL) ||
		    ((fragment->bind_mode == FPVM_BIND_SOURCE) && !dest))
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
		snprintf(fragment->last_error, FPVM_MAXERRLEN,
		    "Failed to allocate register for constant");
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

static int add_isn(struct fpvm_fragment *fragment, int opcode,
    int opa, int opb, int dest)
{
	int len;

	len = fragment->ninstructions;
	if(len >= FPVM_MAXCODELEN) {
		snprintf(fragment->last_error, FPVM_MAXERRLEN,
		    "Ran out of program space");
		return 0;
	}

	fragment->code[len].opa = opa;
	fragment->code[len].opb = opb;
	fragment->code[len].opcode = opcode;
	fragment->code[len].dest = dest;

	fragment->ninstructions++;
	return 1;
}

static int operator2opcode(enum ast_op op)
{
	switch (op) {
	case op_plus:		return FPVM_OPCODE_FADD;
	case op_minus:		return FPVM_OPCODE_FSUB;
	case op_multiply:	return FPVM_OPCODE_FMUL;
	case op_abs:		return FPVM_OPCODE_FABS;
	case op_isin:		return FPVM_OPCODE_SIN;
	case op_icos:		return FPVM_OPCODE_COS;
	case op_above:		return FPVM_OPCODE_ABOVE;
	case op_equal:		return FPVM_OPCODE_EQUAL;
	case op_i2f:		return FPVM_OPCODE_I2F;
	case op_f2i:		return FPVM_OPCODE_F2I;
	case op_if:		return FPVM_OPCODE_IF;
	case op_tsign:		return FPVM_OPCODE_TSIGN;
	case op_quake:		return FPVM_OPCODE_QUAKE;
	default:
		return -1;
	}
}

#define	ADD_ISN_RET(op, opa, opb, dest) \
	if(!add_isn(fragment, op, opa, opb, dest)) return

#define	ADD_ISN_0(op, opa, opb, dest) \
	do { ADD_ISN_RET(op, opa, opb, dest) 0; } while (0)

#define	ADD_ISN(op, opa, opb, dest) \
	do { ADD_ISN_RET(op, opa, opb, dest) FPVM_INVALID_REG; } while (0)

#define	ADD_INV_SQRT(in, out)				\
	do {						\
		if(!add_inv_sqrt(fragment, in, out))	\
			return FPVM_INVALID_REG;	\
	} while (0)

#define	ADD_INT(in, out)				\
	do {						\
		if(!add_int(fragment, in, out))		\
			return FPVM_INVALID_REG;	\
	} while (0)

#define	COMPILE(reg, node)				\
	({ int tmp = compile(fragment, reg, node);	\
	    if(tmp == FPVM_INVALID_REG) return tmp;	\
	    tmp; })

#define	REG_ALLOC() \
	(fragment->next_sur--)

#define	REG_CONST_RET(val, ret)			\
	({ int tmp = const_to_reg(fragment, val);	\
	   if(tmp == FPVM_INVALID_REG) return ret; 	\
	   tmp; })

#define	REG_CONST_0(val) \
	REG_CONST_RET(val, 0)

#define	REG_CONST(val) \
	REG_CONST_RET(val, FPVM_INVALID_REG)

static int add_inv_sqrt_step(struct fpvm_fragment *fragment,
    int reg_y, int reg_x, int reg_out)
{
	int reg_onehalf = REG_CONST_0(0.5f);
	int reg_twohalf = REG_CONST(1.5f);
	int reg_yy = REG_ALLOC();
	int reg_hx = REG_ALLOC();
	int reg_hxyy = REG_ALLOC();
	int reg_sub = REG_ALLOC();

	ADD_ISN_0(FPVM_OPCODE_FMUL, reg_y, reg_y, reg_yy);
	ADD_ISN_0(FPVM_OPCODE_FMUL, reg_onehalf, reg_x, reg_hx);
	ADD_ISN_0(FPVM_OPCODE_FMUL, reg_hx, reg_yy, reg_hxyy);
	ADD_ISN_0(FPVM_OPCODE_FSUB, reg_twohalf, reg_hxyy, reg_sub);
	ADD_ISN_0(FPVM_OPCODE_FMUL, reg_sub, reg_y, reg_out);

	return 1;
}

static int add_inv_sqrt(struct fpvm_fragment *fragment, int reg_in, int reg_out)
{
	int reg_y = REG_ALLOC();
	int reg_y2 = REG_ALLOC();

	ADD_ISN_0(FPVM_OPCODE_QUAKE, reg_in, 0, reg_y);
	if(!add_inv_sqrt_step(fragment, reg_y, reg_in, reg_y2)) return 0;
	if(!add_inv_sqrt_step(fragment, reg_y2, reg_in, reg_out)) return 0;

	return 1;
}

static int add_int(struct fpvm_fragment *fragment, int reg_in, int reg_out)
{
	int reg_i = REG_ALLOC();

	ADD_ISN(FPVM_OPCODE_F2I, reg_in, 0, reg_i);
	ADD_ISN(FPVM_OPCODE_I2F, reg_i, 0, reg_out);
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

	switch(node->op) {
	case op_constant:
		/* AST node is a constant */
		opa = REG_CONST(node->contents.constant);
		if(reg != FPVM_INVALID_REG)
			ADD_ISN(FPVM_OPCODE_COPY, opa, 0, reg);
		else
			reg = opa;
		return reg;
	case op_ident:
		/* AST node is a variable */
		if(fragment->bind_mode) {
			opa = sym_to_reg(fragment, node->sym, 0, NULL);
			if(opa == FPVM_INVALID_REG) return FPVM_INVALID_REG;
		} else {
			opa = lookup(fragment, node->sym);
			if((opa == FPVM_INVALID_REG)||
			    (opa == fragment->final_dest)) {
				snprintf(fragment->last_error, FPVM_MAXERRLEN,
				    "Reading unbound variable: %s",
				    node->sym->name);
				return FPVM_INVALID_REG;
			}
		}
		if(reg != FPVM_INVALID_REG)
			ADD_ISN(FPVM_OPCODE_COPY, opa, 0, reg);
		else
			reg = opa;
		return reg;
	case op_if:
		/*
		 * "if" must receive a special treatment.
		 * It is implemented as a ternary function,
		 * but its first parameter is hardwired to R2 (FPVM_REG_IFB)
		 * and implicit.
		 * We must compute the other parameters first, as they may
		 * clobber R2.
		 */
		opa = COMPILE(FPVM_INVALID_REG, node->contents.branches.b);
		opb = COMPILE(FPVM_INVALID_REG, node->contents.branches.c);
		(void) COMPILE(FPVM_REG_IFB, node->contents.branches.a);
		break;
	case op_negate:
		if(node->contents.branches.a->op == op_constant) {
			/* Node is a negative constant */
			struct ast_node *n;

			n = node->contents.branches.a;
			opa = REG_CONST(-n->contents.constant);
			if(reg != FPVM_INVALID_REG)
				ADD_ISN(FPVM_OPCODE_COPY, opa, 0, reg);
			else
				reg = opa;
			return reg;
		}
		/* fall through */
	default:
		/* AST node is an operator or function */
		opa = COMPILE(FPVM_INVALID_REG, node->contents.branches.a);
		opb = 0;
		if(node->contents.branches.b != NULL) {
			opb = COMPILE(FPVM_INVALID_REG,
			    node->contents.branches.b);
		}
	}

	if(reg == FPVM_INVALID_REG)
		reg = fragment->next_sur--;

	switch(node->op) {
	case op_below:
		/*
		 * "below" is like "above", but with reversed operands.
		 */
		ADD_ISN(FPVM_OPCODE_ABOVE, opb, opa, reg);
		break;
	case op_sin:
	case op_cos: {
		/*
		 * Trigo functions are implemented with several instructions.
		 * We must convert the floating point argument in radians
		 * to an integer expressed in 1/8192 turns for FPVM.
		 */
		int reg_const = REG_CONST(FPVM_TRIG_CONV);
		int reg_mul = REG_ALLOC();
		int reg_f2i = REG_ALLOC();

		if(node->op == op_sin)
			opcode = FPVM_OPCODE_SIN;
		else
			opcode = FPVM_OPCODE_COS;

		ADD_ISN(FPVM_OPCODE_FMUL, reg_const, opa, reg_mul);
		ADD_ISN(FPVM_OPCODE_F2I, reg_mul, 0, reg_f2i);
		ADD_ISN(opcode, reg_f2i, 0, reg);
		break;
	}
	case op_sqrt: {
		/*
		 * Square root is implemented with a variant of the Quake III
		 * algorithm.
		 * See http://en.wikipedia.org/wiki/Fast_inverse_square_root
		 * sqrt(x) = x*(1/sqrt(x))
		 */
		int reg_invsqrt = REG_ALLOC();

		ADD_INV_SQRT(opa, reg_invsqrt);
		ADD_ISN(FPVM_OPCODE_FMUL, opa, reg_invsqrt, reg);
		break;
	}
	case op_invsqrt:
		ADD_INV_SQRT(opa, reg);
		break;
	case op_divide: {
		/*
		 * Floating point division is implemented as
		 * a/b = a*(1/sqrt(b))*(1/sqrt(b))
		 */
		int reg_a2 = REG_ALLOC();
		int reg_b2 = REG_ALLOC();
		int reg_invsqrt = REG_ALLOC();
		int reg_invsqrt2 = REG_ALLOC();

		/* Transfer the sign of the result to a and make b positive */
		ADD_ISN(FPVM_OPCODE_TSIGN, opa, opb, reg_a2);
		ADD_ISN(FPVM_OPCODE_FABS, opb, 0, reg_b2);

		ADD_INV_SQRT(reg_b2, reg_invsqrt);
		ADD_ISN(FPVM_OPCODE_FMUL, reg_invsqrt, reg_invsqrt,
		    reg_invsqrt2);
		ADD_ISN(FPVM_OPCODE_FMUL, reg_invsqrt2, reg_a2, reg);
		break;
	}
	case op_percent: {
		int reg_invsqrt = REG_ALLOC();
		int reg_invsqrt2 = REG_ALLOC();
		int reg_div = REG_ALLOC();
		int reg_idiv = REG_ALLOC();
		int reg_bidiv = REG_ALLOC();

		ADD_INV_SQRT(opb, reg_invsqrt);
		ADD_ISN(FPVM_OPCODE_FMUL, reg_invsqrt, reg_invsqrt,
		    reg_invsqrt2);
		ADD_ISN(FPVM_OPCODE_FMUL, reg_invsqrt2, opa, reg_div);
		ADD_INT(reg_div, reg_idiv);
		ADD_ISN(FPVM_OPCODE_FMUL, opb, reg_idiv, reg_bidiv);
		ADD_ISN(FPVM_OPCODE_FSUB, opa, reg_bidiv, reg);
		break;
	}
	case op_min:
		ADD_ISN(FPVM_OPCODE_ABOVE, opa, opb, FPVM_REG_IFB);
		ADD_ISN(FPVM_OPCODE_IF, opb, opa, reg);
		break;
	case op_max:
		ADD_ISN(FPVM_OPCODE_ABOVE, opa, opb, FPVM_REG_IFB);
		ADD_ISN(FPVM_OPCODE_IF, opa, opb, reg);
		break;
	case op_sqr:
		ADD_ISN(FPVM_OPCODE_FMUL, opa, opa, reg);
		break;
	case op_int:
		ADD_INT(opa, reg);
		break;
	case op_negate:
		opb = find_negative_constant(fragment);
		if(opb == FPVM_INVALID_REG)
			return FPVM_INVALID_REG;
		ADD_ISN(FPVM_OPCODE_TSIGN, opa, opb, reg);
		break;
	default:
		/* Normal case */
		opcode = operator2opcode(node->op);
		if(opcode < 0) {
			snprintf(fragment->last_error, FPVM_MAXERRLEN,
			    "Operation not supported: %d", node->op);
			return FPVM_INVALID_REG;
		}
		ADD_ISN(opcode, opa, opb, reg);
		break;
	}

	return reg;
}

struct fpvm_backup {
	int ntbindings;
	int next_sur;
	int ninstructions;
};

static void fragment_backup(struct fpvm_fragment *fragment,
    struct fpvm_backup *backup)
{
	backup->ntbindings = fragment->ntbindings;
	backup->next_sur = fragment->next_sur;
	backup->ninstructions = fragment->ninstructions;
}

static void fragment_restore(struct fpvm_fragment *fragment,
    struct fpvm_backup *backup)
{
	fragment->ntbindings = backup->ntbindings;
	fragment->next_sur = backup->next_sur;
	fragment->ninstructions = backup->ninstructions;
}

int fpvm_do_assign(struct fpvm_fragment *fragment, struct sym *dest,
    struct ast_node *n)
{
	int dest_reg;
	struct fpvm_backup backup;
	int created;
	int use_renaming;

	fragment_backup(fragment, &backup);

	/* do not rename output X and Y */
	use_renaming = fragment->vector_mode
		&& (dest != fragment->tbindings[0].sym)
		&& (dest != fragment->tbindings[1].sym);
	if(use_renaming) {
		dest_reg = fragment->next_sur;
		fragment->next_sur--;
		created = 1;
	} else
		dest_reg = sym_to_reg(fragment, dest, 1, &created);
	if(dest_reg == FPVM_INVALID_REG) {
		snprintf(fragment->last_error, FPVM_MAXERRLEN,
		    "Failed to allocate register for destination");
		fragment_restore(fragment, &backup);
		return 0;
	}

	if(created)
		fragment->final_dest = dest_reg;
	else
		fragment->final_dest = FPVM_INVALID_REG;
	if(compile(fragment, dest_reg, n) == FPVM_INVALID_REG) {
		fragment_restore(fragment, &backup);
		return 0;
	}
	if(use_renaming) {
		if(!rename_reg(fragment, dest, dest_reg)) {
			fragment_restore(fragment, &backup);
			return 0;
		}
	}

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
			printf("%s\n", fragment->bindings[i].b.v->name);
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
		printf("%s\n", fragment->tbindings[i].sym->name);
	}
	printf("== Code:\n");
	for(i=0;i<fragment->ninstructions;i++) {
		printf("%04d: ", i);
		fpvm_print_opcode(fragment->code[i].opcode);
		switch(fpvm_get_arity(fragment->code[i].opcode)) {
			case 3:
			case 2:
				printf("R%04d,R%04d ", fragment->code[i].opa,
				     fragment->code[i].opb);
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
