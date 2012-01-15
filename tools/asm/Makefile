#
# Makefile - Makefile of pfpuasm
#
# Copyright 2012 by Werner Almesberger
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#

CFLAGS = -g -Wall -I../../software/include
SLOPPY = -Wno-unused -Wno-implicit-function-declaration
LDLIBS = -lfl
OBJS = pfpuasm.o lex.yy.o y.tab.o

YACC = bison -y
YYFLAGS = -v

CC_normal	:= $(CC)
YACC_normal	:= $(YACC)
LEX_normal	:= $(LEX)
DEPEND_normal	:= $(CPP) $(CFLAGS) -MM -MG

CC_quiet	= @echo "  CC       " $@ && $(CC_normal)
YACC_quiet	= @echo "  YACC     " $@ && $(YACC_normal)
LEX_quiet	= @echo "  LEX      " $@ && $(LEX_normal)
GEN_quiet	= @echo "  GENERATE " $@ &&
DEPEND_quiet	= @$(DEPEND_normal)

ifeq ($(V),1)
    CC		= $(CC_normal)
    LEX		= $(LEX_normal)
    YACC	= $(YACC_normal)
    GEN		=
    DEPEND	= $(DEPEND_normal)
else
    CC		= $(CC_quiet)
    LEX		= $(LEX_quiet)
    YACC	= $(YACC_quiet)
    GEN		= $(GEN_quiet)
    DEPEND	= $(DEPEND_quiet)
endif

.PHONY:		all clean

all:		pfpuasm

pfpuasm:	$(OBJS)

lex.yy.c:	asm.l y.tab.h
		$(LEX) asm.l

lex.yy.o:	lex.yy.c y.tab.h
		$(CC) -c $(CFLAGS) $(SLOPPY) lex.yy.c

y.tab.c y.tab.h: asm.y
		$(YACC) $(YYFLAGS) -d asm.y

y.tab.o:	y.tab.c
		$(CC) -c $(CFLAGS) $(SLOPPY) y.tab.c

clean:
		rm -f $(OBJS)
		rm -f lex.yy.c y.tab.c y.tab.h
