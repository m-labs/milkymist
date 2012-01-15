%{
/*
 * asm.l - PFPU assembler
 *
 * Copyright 2012 by Werner Almesberger
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#include <stdlib.h>
#include <stdio.h>

#include "pfpuasm.h"

#include "y.tab.h"


static int lineno = 1;

%}

%%

NOP|nop				return TOK_NOP;
FADD|fadd			return TOK_FADD;
FSUB|fsub			return TOK_FSUB;
FMUL|fmul			return TOK_FMUL;
FABS|fabs			return TOK_FABS;
F2I|f2i				return TOK_F2I;
I2F|i2f				return TOK_I2F;
VECTOUT|vectout			return TOK_VECTOUT;
SIN|sin				return TOK_SIN;
COS|cos				return TOK_COS;
ABOVE|above			return TOK_ABOVE;
EQUAL|equal			return TOK_EQUAL;
COPY|copy			return TOK_COPY;
IF|if				return TOK_IF;
TSIGN|tsign			return TOK_TSIGN;
QUAKE|quake			return TOK_QUAKE;

[Rr][0-9]+			{ yylval.reg = atoi(yytext+1);
				  return REG; }

"->"				return ARROW;

[0-9]+"."?[0-9]*|"."[0-9]+ 	{ yylval.f = atof(yytext);
				  return FLOAT; }
0[Xx][0-9a-fA-F]+		{ yylval.i = strtoul(yytext, NULL, 0);
				  return HEX; }

[ \t]				;
\n				lineno++;

^#\ [0-9]+\ \"[^"]*\"(\ [0-9]+)*\n {
				  lineno = strtol(yytext+2, NULL, 0); }

.				return *yytext;

%%

void yyerror(const char *s)
{
	fprintf(stderr, "%d: %s\n", lineno, s);
	exit(1);
}
