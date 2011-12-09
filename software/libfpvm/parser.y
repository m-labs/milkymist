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

%include {
	#include <assert.h>
	#include <string.h>
	#include <stdlib.h>
	#include <malloc.h>
	#include <math.h>
	#include "ast.h"
	#include "parser.h"


	const enum ast_op tok2op[] = {
		[TOK_IDENT]	= op_ident,
		[TOK_CONSTANT]	= op_constant,
		[TOK_PLUS]	= op_plus,
		[TOK_MINUS]	= op_minus,
		[TOK_MULTIPLY]	= op_multiply,
		[TOK_DIVIDE]	= op_divide,
		[TOK_PERCENT]	= op_percent,
		[TOK_ABS]	= op_abs,
		[TOK_ISIN]	= op_isin,
		[TOK_ICOS]	= op_icos,
		[TOK_SIN]	= op_sin,
		[TOK_COS]	= op_cos,
		[TOK_ABOVE]	= op_above,
		[TOK_BELOW]	= op_below,
		[TOK_EQUAL]	= op_equal,
		[TOK_I2F]	= op_i2f,
		[TOK_F2I]	= op_f2i,
		[TOK_IF]	= op_if,
		[TOK_TSIGN]	= op_tsign,
		[TOK_QUAKE]	= op_quake,
		[TOK_NOT]	= op_not,
		[TOK_SQR]	= op_sqr,
		[TOK_SQRT]	= op_sqrt,
		[TOK_INVSQRT]	= op_invsqrt,
		[TOK_MIN]	= op_min,
		[TOK_MAX]	= op_max,
		[TOK_INT]	= op_int,
		
	};

	struct ast_node *node(int token, const char *id, struct ast_node *a,
	     struct ast_node *b, struct ast_node *c)
	{
		struct ast_node *n;

		n = malloc(sizeof(struct ast_node));
		n->op = tok2op[token];
		n->label = id;
		n->contents.branches.a = a;
		n->contents.branches.b = b;
		n->contents.branches.c = c;
		return n;
	}
}

%start_symbol start
%extra_argument {struct ast_node **parseout}
%token_type {struct id *}

%token_destructor { free($$); }

%type start {struct ast_node *}
%type node {struct ast_node *}
%destructor node { free($$); }

start(S) ::= node(N). {
	S = N;
	*parseout = S;
}

node(N) ::= TOK_CONSTANT(C). {
	N = node(TOK_CONSTANT, "", NULL, NULL, NULL);
	N->contents.constant = C->constant;
}

node(N) ::= ident(I). {
	N = node(I->token, I->label, NULL, NULL, NULL);
}

%left TOK_PLUS TOK_MINUS.
%left TOK_MULTIPLY TOK_DIVIDE TOK_PERCENT.
%left TOK_NOT.

node(N) ::= node(A) TOK_PLUS node(B). {
	N = node(TOK_PLUS, "+", A, B, NULL);
}

node(N) ::= node(A) TOK_MINUS node(B). {
	N = node(TOK_MINUS, "-", A, B, NULL);
}

node(N) ::= node(A) TOK_MULTIPLY node(B). {
	N = node(TOK_MULTIPLY, "*", A, B, NULL);
}

node(N) ::= node(A) TOK_DIVIDE node(B). {
	N = node(TOK_DIVIDE, "/", A, B, NULL);
}

node(N) ::= node(A) TOK_PERCENT node(B). {
	N = node(TOK_PERCENT, "%", A, B, NULL);
}

node(N) ::= TOK_MINUS node(A). [TOK_NOT] {
	N = node(TOK_NOT, "!", A, NULL, NULL);
}

node(N) ::= unary(I) TOK_LPAREN node(A) TOK_RPAREN. {
	N = node(I->token, I->label, A, NULL, NULL);
}

node(N) ::= binary(I) TOK_LPAREN node(A) TOK_COMMA node(B) TOK_RPAREN. {
	N = node(I->token, I->label, A, B, NULL);
}

node(N) ::= ternary(I) TOK_LPAREN node(A) TOK_COMMA node(B) TOK_COMMA node(C)
    TOK_RPAREN. {
	N = node(I->token, I->label, A, B, C);
}

node(N) ::= TOK_LPAREN node(A) TOK_RPAREN. {
	N = A;
}

ident(O) ::= TOK_IDENT(I).	{ O = I; }
ident(O) ::= unary(I).		{ O = I; }
ident(O) ::= binary(I).		{ O = I; }
ident(O) ::= ternary(I).	{ O = I; }

unary(O) ::= TOK_ABS(I).	{ O = I; }
unary(O) ::= TOK_COS(I).	{ O = I; }
unary(O) ::= TOK_F2I(I).	{ O = I; }
unary(O) ::= TOK_ICOS(I).	{ O = I; }
unary(O) ::= TOK_I2F(I).	{ O = I; }
unary(O) ::= TOK_INT(I).	{ O = I; }
unary(O) ::= TOK_INVSQRT(I).	{ O = I; }
unary(O) ::= TOK_ISIN(I).	{ O = I; }
unary(O) ::= TOK_QUAKE(I).	{ O = I; }
unary(O) ::= TOK_SIN(I).	{ O = I; }
unary(O) ::= TOK_SQR(I).	{ O = I; }
unary(O) ::= TOK_SQRT(I).	{ O = I; }

binary(O) ::= TOK_ABOVE(I).	{ O = I; }
binary(O) ::= TOK_BELOW(I).	{ O = I; }
binary(O) ::= TOK_EQUAL(I).	{ O = I; }
binary(O) ::= TOK_MAX(I).	{ O = I; }
binary(O) ::= TOK_MIN(I).	{ O = I; }
binary(O) ::= TOK_TSIGN(I).	{ O = I; }

ternary(O) ::= TOK_IF(I).	{ O = I; }
