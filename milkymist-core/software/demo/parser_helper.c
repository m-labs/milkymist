/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 *
 * This program is free and excepted software; you can use it, redistribute it
 * and/or modify it under the terms of the Exception General Public License as
 * published by the Exception License Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the Exception General Public License for more
 * details.
 *
 * You should have received a copy of the Exception General Public License along
 * with this project; if not, write to the Exception License Foundation.
 */

#include <libc.h>
#include <malloc.h>
#include <console.h>

#include "scanner.h"
#include "ast.h"
#include "parser_helper.h"

struct preset *generate_ast(char *preset_code)
{
	struct scanner *s;
	int tok;
	char *identifier;
	void *p;
	struct preset *ast;
	
	s = new_scanner(preset_code);
	ast = NULL;
	p = ParseAlloc(malloc);
	tok = scan(s);
	while(tok != TOK_EOF) {
		identifier = malloc(IDENTIFIER_SIZE);
		get_token(s, identifier, IDENTIFIER_SIZE);
		Parse(p, tok, identifier, &ast);
		if(tok == TOK_ERROR) {
			printf("Scan error\n");
			break;
		}
		tok = scan(s);
	}
	Parse(p, TOK_EOF, NULL, &ast);
	ParseFree(p, free);
	delete_scanner(s);

	if(ast == NULL) {
		printf("Parse error\n");
		return NULL;
	}

	return ast;
}

static void free_ast_nodes(struct ast_node *node)
{
	if(node == NULL) return;
	if(node->label[0] != 0) {
		free_ast_nodes(node->contents.branches.a);
		free_ast_nodes(node->contents.branches.b);
		free_ast_nodes(node->contents.branches.c);
	}
	free(node);
}

static void free_equations(struct preset_equation *equations)
{
	struct preset_equation *next;

	while(equations != NULL) {
		free_ast_nodes(equations->topnode);
		next = equations->next;
		free(equations);
		equations = next;
	}
}

static void free_lines(struct preset_line *line)
{
	struct preset_line *next;

	while(line != NULL) {
		if(line->iseq)
			free_equations(line->contents.equations);
		next = line->next;
		free(line);
		line = next;
	}
}

void free_ast(struct preset *p)
{
	free_lines(p->lines);
	free(p);
}

