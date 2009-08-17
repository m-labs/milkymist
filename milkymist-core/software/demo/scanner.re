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
