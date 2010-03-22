/*
 * Milkymist VJ SoC (Software)
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

#ifndef __FPVM_FPVM_H
#define __FPVM_FPVM_H

#include <fpvm/is.h>

#define FPVM_MAXBINDINGS	128
#define FPVM_MAXTBINDINGS	128
#define FPVM_MAXCODELEN		2048
#define FPVM_MAXSYMLEN		32

#define FPVM_INVALID_REG	FPVM_MAXBINDINGS

struct fpvm_binding {
	int isvar;
	union {
		float c;
		char v[FPVM_MAXSYMLEN];
	} b;
};

struct fpvm_tbinding {
	int reg;
	char sym[FPVM_MAXSYMLEN];
};

struct fpvm_fragment {
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

	/* Next single-use-register to allocate */
	int next_sur;
	
	int ninstructions;
	struct fpvm_instruction code[FPVM_MAXCODELEN];
};

void fpvm_init(struct fpvm_fragment *fragment);

int fpvm_bind(struct fpvm_fragment *fragment, const char *sym);
void fpvm_set_xin(struct fpvm_fragment *fragment, const char *sym);
void fpvm_set_yin(struct fpvm_fragment *fragment, const char *sym);
void fpvm_set_xout(struct fpvm_fragment *fragment, const char *sym);
void fpvm_set_yout(struct fpvm_fragment *fragment, const char *sym);

int fpvm_assign(struct fpvm_fragment *fragment, const char *dest, const char *expr);

int fpvm_done(struct fpvm_fragment *fragment);

void fpvm_dump(struct fpvm_fragment *fragment);

#endif /* __FPVM_FPVM_H */
