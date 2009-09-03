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

#include <libc.h>
#include <malloc.h>

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
	s->limit = input + strlen(input);
	
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
		[\x20\r\t]				{ goto std; }
		"\n"					{ return TOK_NEWLINE; }
		"//" ([\x00-\x09\x0b-\xff])* "\n"	{ return TOK_NEWLINE; }
		"[" ([\x00-\x09\x0b-\xff])* "\n"	{ goto std; }
		";"					{ return TOK_SEMICOLON; }
		[0-9]+					{ return TOK_CONSTANT; }
		[0-9]* "." [0-9]*			{ return TOK_CONSTANT; }
		[a-zA-Z_0-9]+				{ return TOK_IDENT; }
		"+"					{ return TOK_PLUS; }
		"-"					{ return TOK_MINUS; }
		"*"					{ return TOK_MULTIPLY; }
		"/"					{ return TOK_DIVIDE; }
		"%"					{ return TOK_PERCENT; }
		"("					{ return TOK_LPAREN; }
		")"					{ return TOK_RPAREN; }
		","					{ return TOK_COMMA; }
		"="					{ return TOK_EQUAL; }
		[\x00-\xff]				{ return TOK_ERROR; }
	*/
}

int get_token(struct scanner *s, unsigned char *buffer, int length)
{
	int total_length;
	int copy_length;
	int i;
	
	total_length = copy_length = s->cursor - s->old_cursor;
	if(copy_length >= length)
		copy_length = length - 1;
	for(i=0;i<copy_length;i++)
		buffer[i] = s->old_cursor[i];
	buffer[copy_length] = 0;
	return total_length;
}
