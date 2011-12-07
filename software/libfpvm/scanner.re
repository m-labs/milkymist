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

#include <stdio.h>
#include <string.h>
#include <malloc.h>

#include "unique.h"
#include "scanner.h"

#define YYCTYPE     unsigned char
#define YYCURSOR    s->cursor
#define YYLIMIT     s->limit

/* refilling not supported */
#define YYMARKER s->marker
#define YYFILL(n)

struct scanner *new_scanner(unsigned char *input)
{
	struct scanner *s;
	
	s = malloc(sizeof(struct scanner));
	if(s == NULL) return NULL;
	
	s->marker = input;
	s->old_cursor = input;
	s->cursor = input;
	s->limit = input + strlen((char *)input);
	
	return s;
}

void delete_scanner(struct scanner *s)
{
	free(s);
}

int scan(struct scanner *s)
{
	std:
	if(s->cursor == s->limit) return TOK_EOF;
	s->old_cursor = s->cursor;
	
	/*!re2c
		[\x20\r\t]		{ goto std; }
		[0-9]+			{ return TOK_CONSTANT; }
		[0-9]* "." [0-9]*	{ return TOK_CONSTANT; }

		"above"			{ return TOK_ABOVE; }
		"abs"			{ return TOK_ABS; }
		"below"			{ return TOK_BELOW; }
		"cos"			{ return TOK_COS; }
		"equal"			{ return TOK_EQUAL; }
		"f2i"			{ return TOK_F2I; }
		"icos"			{ return TOK_ICOS; }
		"i2f"			{ return TOK_I2F; }
		"if"			{ return TOK_IF; }
		"int"			{ return TOK_INT; }
		"invsqrt"		{ return TOK_INVSQRT; }
		"isin"			{ return TOK_ISIN; }
		"max"			{ return TOK_MAX; }
		"min"			{ return TOK_MIN; }
		"quake"			{ return TOK_QUAKE; }
		"sin"			{ return TOK_SIN; }
		"sqr"			{ return TOK_SQR; }
		"sqrt"			{ return TOK_SQRT; }
		"tsign"			{ return TOK_TSIGN; }

		[a-zA-Z_0-9]+		{ return TOK_IDENT; }
		"+"			{ return TOK_PLUS; }
		"-"			{ return TOK_MINUS; }
		"*"			{ return TOK_MULTIPLY; }
		"/"			{ return TOK_DIVIDE; }
		"%"			{ return TOK_PERCENT; }
		"("			{ return TOK_LPAREN; }
		")"			{ return TOK_RPAREN; }
		","			{ return TOK_COMMA; }
		[\x00-\xff]		{ return TOK_ERROR; }
	*/
}

const char *get_token(struct scanner *s)
{
	return unique_n((const char *) s->old_cursor,
	    s->cursor - s->old_cursor);
}

float get_constant(struct scanner *s)
{
	const unsigned char *p;
	float v = 0;
	float m = 1;

	for(p = s->old_cursor; p != s->cursor; p++) {
		if(*p == '.')
			goto dot;
		v = v*10+(*p-'0');
	}
	return v;

dot:
	for(p++; p != s->cursor; p++) {
		m /= 10;
		v += m*(*p-'0');
	}
	return v;
}
