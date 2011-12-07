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


	struct ast_node *node(const char *id, struct ast_node *a,
	     struct ast_node *b, struct ast_node *c)
	{
		struct ast_node *n;

		n = malloc(sizeof(struct ast_node));
		strncpy(n->label, id, sizeof(n->label));
		n->label[sizeof(n->label)-1] = 0;
		n->contents.branches.a = a;
		n->contents.branches.b = b;
		n->contents.branches.c = c;
		return n;
	}
}

%start_symbol start
%extra_argument {struct ast_node **parseout}
%token_type {void *}

%token_destructor { free($$); }

%type node {struct ast_node *}
%destructor node { free($$); }

start(S) ::= node(N). {
	S = N;
	*parseout = S;
}

node(N) ::= TOK_CONSTANT(C). {
	N = node("", NULL, NULL, NULL);
	N->contents.constant = atof(C);
}

node(N) ::= ident(I). {
	N = node(I, NULL, NULL, NULL);
}

%left TOK_PLUS TOK_MINUS.
%left TOK_MULTIPLY TOK_DIVIDE TOK_PERCENT.
%left TOK_NOT.

node(N) ::= node(A) TOK_PLUS node(B). {
	N = node("+", A, B, NULL);
}

node(N) ::= node(A) TOK_MINUS node(B). {
	N = node("-", A, B, NULL);
}

node(N) ::= node(A) TOK_MULTIPLY node(B). {
	N = node("*", A, B, NULL);
}

node(N) ::= node(A) TOK_DIVIDE node(B). {
	N = node("/", A, B, NULL);
}

node(N) ::= node(A) TOK_PERCENT node(B). {
	N = node("%", A, B, NULL);
}

node(N) ::= TOK_MINUS node(A). [TOK_NOT] {
	N = node("!", A, NULL, NULL);
}

node(N) ::= unary(I) TOK_LPAREN node(A) TOK_RPAREN. {
	N = node(I, A, NULL, NULL);
}

node(N) ::= binary(I) TOK_LPAREN node(A) TOK_COMMA node(B) TOK_RPAREN. {
	N = node(I, A, B, NULL);
}

node(N) ::= ternary(I) TOK_LPAREN node(A) TOK_COMMA node(B) TOK_COMMA node(C)
    TOK_RPAREN. {
	N = node(I, A, B, C);
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
