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

%include {
	#include <assert.h>
	#include <string.h>
	#include <stdlib.h>
	#include <malloc.h>
	#include <math.h>
	#include "ast.h"
}

%start_symbol start
%extra_argument {struct preset **parseout}
%token_type {void *}

%token_destructor { free($$); }

%type preset {struct preset *}
%destructor preset { free($$); }
%type line {struct preset_line *}
%type line_p {struct preset_line *}
%destructor line_p { free($$); }
%type line_e {struct preset_line *}
%destructor line_e { free($$); }
%type parameter {struct preset_parameter *}
%destructor parameter { free($$); }
%type equation {struct preset_equation *}
%destructor equation { free($$); }
%type node {struct ast_node *}
%destructor node { free($$); }

start(S) ::= preset(P). {
	S = P;
	*parseout = S;
}

preset(P) ::= line(L). {
	P = malloc(sizeof(struct preset));
	P->lines = L;
	P->last_line = L;
}

preset(P) ::= preset(B) TOK_NEWLINE line(L). {
	P = B;
	if(L != NULL) {
		if(P->lines == NULL) {
			P->lines = L;
			P->last_line = L;
		} else {
			P->last_line->next = L;
			P->last_line = L;
		}
	}
}

preset(P) ::= preset(B) TOK_NEWLINE. { P = B; }

line(A) ::= line_p(B). { A = B; }
line(A) ::= line_e(B). { A = B; }
line(A) ::= line_n. { A = NULL; }

line_p(L) ::= TOK_IDENT(I) TOK_EQUAL TOK_CONSTANT(C). {
	L = malloc(sizeof(struct preset_line));
	strncpy(L->label, I, sizeof(L->label));
	L->label[sizeof(L->label)-1] = 0;
	L->iseq = 0;
	L->contents.parameter = atof(C);
}

line_p(L) ::= TOK_IDENT(I) TOK_EQUAL TOK_MINUS TOK_CONSTANT(C). {
	L = malloc(sizeof(struct preset_line));
	strncpy(L->label, I, sizeof(L->label));
	L->label[sizeof(L->label)-1] = 0;
	L->iseq = 0;
	L->contents.parameter = -atof(C);
}

line_e(L) ::= TOK_IDENT(I) TOK_EQUAL equation(E). {
	L = malloc(sizeof(struct preset_line));
	strncpy(L->label, I, sizeof(L->label));
	L->label[sizeof(L->label)-1] = 0;
	L->iseq = 1;
	L->contents.equations = E;
}

line_e(L) ::= line_e(B) TOK_SEMICOLON equation(E). {
	L = B;
	if(L->contents.equations != NULL) {
		struct preset_equation *current;
		
		current = L->contents.equations;
		while(current->next != NULL)
			current = current->next;
		current->next = E;
	} else
		L->contents.equations = E; /* should not happen */
}

line_e(L) ::= line_e(B) TOK_SEMICOLON. { L = B; }

line_n ::= TOK_IDENT TOK_EQUAL.

equation(E) ::= TOK_IDENT(I) TOK_EQUAL node(N). {
	E = malloc(sizeof(struct preset_equation));
	strncpy(E->target, I, sizeof(E->target));
	E->target[sizeof(E->target)-1] = 0;
	E->topnode = N;
	E->next = NULL;
}

node(N) ::= TOK_CONSTANT(C). {
	N = malloc(sizeof(struct ast_node));
	N->label[0] = 0;
	N->contents.constant = atof(C);
}

node(N) ::= TOK_IDENT(I). {
	N = malloc(sizeof(struct ast_node));
	strncpy(N->label, I, sizeof(N->label));
	N->label[sizeof(N->label)-1] = 0;
	N->contents.branches.a = NULL;
}

%left TOK_PLUS.
%left TOK_MINUS.
%left TOK_MULTIPLY.
%left TOK_DIVIDE.
%left TOK_PERCENT.
%left TOK_NOT.

node(N) ::= node(A) TOK_PLUS node(B). {
	N = malloc(sizeof(struct ast_node));
	N->label[0] = '+';
	N->label[1] = 0;
	N->contents.branches.a = A;
	N->contents.branches.b = B;
}

node(N) ::= node(A) TOK_MINUS node(B). {
	N = malloc(sizeof(struct ast_node));
	N->label[0] = '-';
	N->label[1] = 0;
	N->contents.branches.a = A;
	N->contents.branches.b = B;
}

node(N) ::= node(A) TOK_MULTIPLY node(B). {
	N = malloc(sizeof(struct ast_node));
	N->label[0] = '*';
	N->label[1] = 0;
	N->contents.branches.a = A;
	N->contents.branches.b = B;
}

node(N) ::= node(A) TOK_DIVIDE node(B). {
	N = malloc(sizeof(struct ast_node));
	N->label[0] = '/';
	N->label[1] = 0;
	N->contents.branches.a = A;
	N->contents.branches.b = B;
}

node(N) ::= node(A) TOK_PERCENT node(B). {
	N = malloc(sizeof(struct ast_node));
	N->label[0] = '%';
	N->label[1] = 0;
	N->contents.branches.a = A;
	N->contents.branches.b = B;
}

node(N) ::= TOK_MINUS node(A). [TOK_NOT] {
	N = malloc(sizeof(struct ast_node));
	N->label[0] = '!';
	N->label[1] = 0;
	N->contents.branches.a = A;
}

node(N) ::= TOK_IDENT(I) TOK_LPAREN node(A) TOK_RPAREN. {
	N = malloc(sizeof(struct ast_node));
	strncpy(N->label, I, sizeof(N->label));
	N->label[sizeof(N->label)-1] = 0;
	N->contents.branches.a = A;
}

node(N) ::= TOK_IDENT(I) TOK_LPAREN node(A) TOK_COMMA node(B) TOK_RPAREN. {
	N = malloc(sizeof(struct ast_node));
	strncpy(N->label, I, sizeof(N->label));
	N->label[sizeof(N->label)-1] = 0;
	N->contents.branches.a = A;
	N->contents.branches.b = B;
}

node(N) ::= TOK_IDENT(I) TOK_LPAREN node(A) TOK_COMMA node(B) TOK_COMMA node(C) TOK_RPAREN. {
	N = malloc(sizeof(struct ast_node));
	strncpy(N->label, I, sizeof(N->label));
	N->label[sizeof(N->label)-1] = 0;
	N->contents.branches.a = A;
	N->contents.branches.b = B;
	N->contents.branches.c = C;
}

node(N) ::= TOK_LPAREN node(A) TOK_RPAREN. {
	N = A;
}
