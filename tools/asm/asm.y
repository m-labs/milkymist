%{
/*
 * asm.y - PFPU assembler
 *
 * Copyright 2012 by Werner Almesberger
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#include <stdint.h>

#include "hw/pfpu.h"

#include "pfpuasm.h"

#include "y.tab.h"


#define	UNARY(op, opa, dest) \
	emit(PFPU_OPCODE_##op, opa, 0, dest, PFPU_LATENCY_##op)
#define	BINARY(op, opa, opb, dest) \
	emit(PFPU_OPCODE_##op, opa, opb, dest, PFPU_LATENCY_##op)


static void emit(int opcode, int opa, int opb, int dest, int latency)
{
	*pc++ |= opcode << OPCODE_SHIFT | opb << OPB_SHIFT | opa << OPA_SHIFT;

	if (dest <= 0)
		return;

	if (pc[latency-1] & (DEST_MASK << DEST_SHIFT))
		yyerror("destination conflict");
	pc[latency-1] |= dest << DEST_SHIFT;
}

%}

%union {
	float f;
	uint32_t i;
	int reg;
};

%token		TOK_NOP TOK_FADD TOK_FSUB TOK_FMUL TOK_FABS
%token		TOK_F2I TOK_I2F TOK_VECTOUT TOK_SIN TOK_COS
%token		TOK_ABOVE TOK_EQUAL TOK_COPY TOK_IF TOK_TSIGN TOK_QUAKE

%token		ARROW

%token	<f>	FLOAT
%token	<i>	HEX
%token	<reg>	REG

%type	<i>	value

%%

all:
	regs ops;

regs:
	| reg regs;

reg:
	REG '=' value
		{
			regs[$1] = $3;
			if ($1 > max_reg)
				max_reg = $1;
		}
	;

value:
	HEX
		{
			$$ = $1;
		}
	| FLOAT
		{
			$$ = f2i($1);
		}
	;

ops:
	| op ops;

op:
	TOK_NOP
		{
			emit(PFPU_OPCODE_NOP, 0, 0, 0, -1);
		}
	| TOK_FADD REG ',' REG ARROW REG
		{
			BINARY(FADD, $2, $4, $6);
		}
	| TOK_FSUB REG ',' REG ARROW REG
		{
			BINARY(FSUB, $2, $4, $6);
		}
	| TOK_FMUL REG ',' REG ARROW REG
		{
			BINARY(FMUL, $2, $4, $6);
		}
	| TOK_FABS REG ARROW REG
		{
			UNARY(FABS, $2, $4);
		}
	| TOK_F2I REG ARROW REG
		{
			UNARY(F2I, $2, $4);
		}
	| TOK_I2F REG ARROW REG
		{
			UNARY(I2F, $2, $4);
		}
	| TOK_VECTOUT REG ',' REG ARROW REG
		{
			BINARY(VECTOUT, $2, $4, $6);
		}
	| TOK_SIN REG ARROW REG
		{
			UNARY(SIN, $2, $4);
		}
	| TOK_COS REG ARROW REG
		{
			UNARY(COS, $2, $4);
		}
	| TOK_ABOVE REG ',' REG ARROW REG
		{
			BINARY(ABOVE, $2, $4, $6);
		}
	| TOK_EQUAL REG ',' REG ARROW REG
		{
			BINARY(EQUAL, $2, $4, $6);
		}
	| TOK_COPY REG ARROW REG
		{
			UNARY(COPY, $2, $4);
		}
	| TOK_IF REG ',' REG ARROW REG
		{
			BINARY(IF, $2, $4, $6);
		}
	| TOK_TSIGN REG ',' REG ARROW REG
		{
			BINARY(TSIGN, $2, $4, $6);
		}
	| TOK_QUAKE REG ',' REG ARROW REG
		{
			BINARY(QUAKE, $2, $4, $6);
		}
	;
