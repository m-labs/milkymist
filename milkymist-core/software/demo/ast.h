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

#ifndef __AST_H
#define __AST_H

#define NDEBUG

#define IDENTIFIER_SIZE 24

struct preset_equation;

struct preset_line {
	char label[IDENTIFIER_SIZE];		   /* the left side: bSolarize, ib_g, per_frame_1, ... */
	int iseq;				   /* union tag */
	union {
		float parameter;		   /* one numeric value for a parameter */
		struct preset_equation *equations; /* a list of equations (separated by semicolons) */
	} contents;
	struct preset_line *next;
};

/* maximum supported arity is 3 */
struct ast_branches {
	struct ast_node *a;
	struct ast_node *b;
	struct ast_node *c;
};

struct ast_node {
	/*
	 * label is an empty string:
	 *   node is a constant
	 * label is not an empty string and branch A is null:
	 *   node is variable "label"
	 * label is not an empty string and branch A is not null:
	 *   node is function/operator "label"
	 */
	char label[IDENTIFIER_SIZE];
	union {
		struct ast_branches branches;
		float constant;
	} contents;
};

struct preset_equation {
	char target[IDENTIFIER_SIZE];
	struct ast_node *topnode;
	struct preset_equation *next;
};

struct preset {
	struct preset_line *lines;
	struct preset_line *last_line;
};

void *ParseAlloc(void *(*mallocProc)(size_t));
void ParseFree(void *p, void (*freeProc)(void*));
void Parse(void *yyp, int yymajor, void *yyminor, struct preset **p);

#endif /* __AST_H */
