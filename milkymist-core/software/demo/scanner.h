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

#ifndef __SCANNER_H
#define __SCANNER_H

#define TOK_ERROR	(-1)
#define TOK_EOF		0

#include "parser.h"

struct scanner {
	unsigned char *marker;
	unsigned char *old_cursor;
	unsigned char *cursor;
	unsigned char *limit;
};

struct scanner *new_scanner(unsigned char *input);
void delete_scanner(struct scanner *s);

/* get to the next token and return its type */
int scan(struct scanner *s);

/* get the string comprising the current token
 * length is the size of the passed buffer, counting
 * the terminating NUL character.
 * returns the number of characters actually written
 * to the buffer, not counting the NUL character.
 */
int get_token(struct scanner *s, unsigned char *buffer, int length);

#endif /* __SCANNER_H */

