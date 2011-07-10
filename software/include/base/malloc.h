/*
 * Milkymist SoC (Software)
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

#ifndef __MALLOC_H
#define __MALLOC_H

/* NB. Start and end addresses must be multiples of 8. */
struct malloc_bank {
	unsigned int addr_start;
	unsigned int addr_end;
	int first_allocated; /* initialized by the allocator */
	int last_allocated; /* initialized by the allocator */
};

void malloc_init(struct malloc_bank *banks, unsigned int n, unsigned int defaultbank);
void *mallocex(unsigned int size, unsigned int bank, unsigned int alignment);

#ifdef PC_TEST
void test_free(void *p);
#endif

#ifdef PC_TEST
void *test_malloc(size_t size);
#endif

#ifdef PC_TEST
void *test_calloc(size_t nmemb, size_t size);
#else
void *calloc(size_t nmemb, size_t size);
#endif

#endif /* __MALLOC_H */
