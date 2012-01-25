/*
 * Milkymist SoC (Software)
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

#ifndef __FPVM_AST_H
#define __FPVM_AST_H

enum ast_op {
	op_trouble,	/* null value */
	op_ident,
	op_constant,
	op_plus,
	op_minus,
	op_multiply,
	op_divide,
	op_percent,
	op_abs,
	op_isin,
	op_icos,
	op_sin,
	op_cos,
	op_above,
	op_below,
	op_equal,
	op_i2f,
	op_f2i,
	op_if,
	op_tsign,
	op_quake,
	op_negate,
	op_sqr,
	op_sqrt,
	op_invsqrt,
	op_min,
	op_max,
	op_int,
	op_bnot,
	op_band,
	op_bor,
};

/* maximum supported arity is 3 */
struct ast_branches {
	struct ast_node *a;
	struct ast_node *b;
	struct ast_node *c;
};

struct ast_node {
	enum ast_op op;
	struct fpvm_sym *sym;
	union {
		struct ast_branches branches;
		float constant;
	} contents;
};

static inline int node_is_op(const struct ast_node *n)
{
	return n->op >= op_plus;
}

#endif /* __FPVM_AST_H */
