/*
 * pfpuasm.c - PFPU assembler
 *
 * Copyright 2012 by Werner Almesberger
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <signal.h>

#include "hw/pfpu.h"

#include "pfpuasm.h"


#define	CPP	"cpp"


uint32_t prog[PFPU_PROGSIZE];
uint32_t *pc = prog;

uint32_t regs[PFPU_REG_COUNT];
int max_reg = 0;

int auto_nop = 0;


int yyparse(void);


static pid_t pid = 0;


static void kill_cpp(void)
{
	if (pid)
		kill(pid, SIGTERM);
}


static void cpp(int n_args, char *const *args)
{
	char **argv;
	int fds[2];

	argv = malloc((n_args+2)*sizeof(const char *));
	if (!argv) {
		perror("malloc");
		exit(1);
	}
	argv[0] = CPP;
	memcpy(argv+1, args, sizeof(const char *)*(n_args+1));
	if (pipe(fds) < 0) {
		perror("pipe");
		exit(1);
	}
	pid = fork();
	if (pid < 0) {
		perror("fork");
		exit(1);
	}
	if (!pid) {
		close(fds[0]);
		if (dup2(fds[1], 1) < 0) {
			perror("dup2");
			exit(1);
		}
		execvp(CPP, argv);
		perror(CPP);
		exit(1);
	}
	close(fds[1]);
	if (dup2(fds[0], 0) < 0) {
		perror("dup2");
		exit(1);
	}
	atexit(kill_cpp);
}


#define	ATTR(op, ar)				\
	[PFPU_OPCODE_##op] = {			\
		.name = #op,			\
		.latency = PFPU_LATENCY_##op,	\
		.arity = ar			\
	}

#define	PFPU_LATENCY_NOP	0	/* fake */

static struct attr {
	const char *name;
	int latency;
	int arity;
} attrs[16] = {
	ATTR(NOP, 0),
	ATTR(FADD, 2),
	ATTR(FSUB, 2),
	ATTR(FMUL, 2),
	ATTR(FABS, 1),
	ATTR(F2I, 1),
	ATTR(I2F, 1),
	ATTR(VECTOUT, 2),
	ATTR(SIN, 1),
	ATTR(COS, 1),
	ATTR(ABOVE, 2),
	ATTR(EQUAL, 2),
	ATTR(COPY, 2),
	ATTR(IF, 2),
	ATTR(TSIGN, 2),
	ATTR(QUAKE, 1),
};


static void usage(const char *name)
{
	fprintf(stderr, "usage: %s [-a] [cpp_options] [file]\n", name);
	exit(1);
}


int main(int argc, char *const *argv)
{
	const uint32_t *p;
	const uint32_t *r;
	int c;

	while ((c = getopt(argc, argv, "a")) != EOF)
		switch (c) {
		case 'a':
			auto_nop = 1;
			break;
		default:
			usage(*argv);
		}
	cpp(argc-optind, argv+optind);
	(void) yyparse();

	for (r = regs+PFPU_SPREG_COUNT; r <= regs+max_reg; r++)
		printf("0x%08x\t# R%u = %f\n",
		    *r, (unsigned) (r-regs), i2f(*r));
	for (p = prog; p != pc; p++) {
		int opcode = (*p >> OPCODE_SHIFT) & OPCODE_MASK;
		int opa = (*p >> OPA_SHIFT) & OPA_MASK;
		int opb = (*p >> OPB_SHIFT) & OPB_MASK;
		int dest;
		const struct attr *attr = attrs+opcode;

		printf("%08x\t# %3u: %s", *p, (unsigned) (p-prog), attr->name);
		switch (attr->arity) {
		case 0:
			break;
		case 1:
			printf("\tR%d", opa);
			break;
		case 2:
			printf("\tR%d, R%d", opa, opb);
			break;
		default:
			abort();
		}
		if (attr->latency) {
			dest = (p[attr->latency] >> DEST_SHIFT) & DEST_MASK;
			printf(" -> R%d @ %u",
			    dest, (unsigned) (p-prog)+attr->latency);
		}
		dest = (*p >> DEST_SHIFT) & DEST_MASK;
		if (dest)
			printf("\t\tdest R%d", dest);
		putchar('\n');
	}
	return 0;
}
