/*
 * Milkymist SoC (Software)
 * Copyright (C) 2007, 2008, 2009, 2010, 2011 Sebastien Bourdeauducq
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

/*
 * Floating Point Virtual Machine compiler.
 * This library takes a series of equations and turn them into
 * FPVM code that evaluates them.
 */

#ifndef __FPVM_FPVM_H
#define __FPVM_FPVM_H

#include <fpvm/is.h>
#include <fpvm/ast.h>
#include <fpvm/symbol.h>

#define FPVM_MAXBINDINGS	128
#define FPVM_MAXTBINDINGS	128
#define FPVM_MAXRENAMINGS	32
#define FPVM_MAXCODELEN		2048
#define FPVM_MAXSYMLEN		32

#define FPVM_INVALID_REG	FPVM_MAXBINDINGS

#define FPVM_MAXERRLEN		64

typedef void (*fpvm_bind_callback)(void *, struct fpvm_sym *, int);

struct fpvm_binding {
	int isvar;
	union {
		float c;
		struct fpvm_sym *v;
	} b;
};

struct fpvm_tbinding {
	int reg;
	struct fpvm_sym *sym;
};

enum {
	FPVM_BIND_NONE,
	FPVM_BIND_SOURCE,
	FPVM_BIND_ALL
};

struct fpvm_fragment {
	char last_error[FPVM_MAXERRLEN];
	fpvm_bind_callback bind_callback;
	void *bind_callback_user;
	
	/* A binding is a link between the FPVM and the user,
	 * made by permanently allocating a given register for the user.
	 * Constants fall in this category because they need to be initialized
	 * by the user.
	 * Index in the table is the register.
	 */
	int nbindings;
	struct fpvm_binding bindings[FPVM_MAXBINDINGS];

	/* A transient binding is only used internally with single use
	 * (negative) registers.
	 */
	int ntbindings;
	struct fpvm_tbinding tbindings[FPVM_MAXTBINDINGS];

	/*
	 * Renamings are bindings that override others.
	 * They are used internally in vector mode to prevent
	 * variables modified in one vector to altering the next vectors.
	 */
	int nrenamings;
	struct fpvm_tbinding renamings[FPVM_MAXRENAMINGS];

	/* Next single-use-register to allocate */
	int next_sur;
	
	int ninstructions;
	struct fpvm_instruction code[FPVM_MAXCODELEN];

	int bind_mode;

	/* internal use, to return an error with equations
	 * such as foo = ... foo ...
	 * when bind_mode = 0 and foo is unbound.
	 */
	int final_dest;
	int vector_mode;
};

extern struct fpvm_sym *_Xi, *_Yi, *_Xo, *_Yo;

const char *fpvm_version(void);

void fpvm_do_init(struct fpvm_fragment *fragment, int vector_mode);
const char *fpvm_get_last_error(struct fpvm_fragment *fragment);
void fpvm_set_bind_mode(struct fpvm_fragment *fragment, int bind_mode);
void fpvm_set_bind_callback(struct fpvm_fragment *fragment, fpvm_bind_callback callback, void *user);

int fpvm_bind(struct fpvm_fragment *fragment, struct fpvm_sym *sym);
void fpvm_set_xin(struct fpvm_fragment *fragment, struct fpvm_sym *sym);
void fpvm_set_yin(struct fpvm_fragment *fragment, struct fpvm_sym *sym);
void fpvm_set_xout(struct fpvm_fragment *fragment, struct fpvm_sym *sym);
void fpvm_set_yout(struct fpvm_fragment *fragment, struct fpvm_sym *sym);

int fpvm_do_assign(struct fpvm_fragment *fragment, struct fpvm_sym *dest,
    struct ast_node *n);

void fpvm_get_references(struct fpvm_fragment *fragment, int *references);

int fpvm_finalize(struct fpvm_fragment *fragment);

void fpvm_dump(struct fpvm_fragment *fragment);

void fpvm_print_opcode(int opcode);
int fpvm_get_arity(int opcode);

#endif /* __FPVM_FPVM_H */
