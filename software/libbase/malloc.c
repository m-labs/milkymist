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

#ifndef PC_TEST
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <console.h>
#else
#include <stdio.h>
#endif

#include "malloc.h"

/* from http://en.wikipedia.org/wiki/Binary_GCD_algorithm */
static unsigned int gcd(unsigned int u, unsigned int v)
{
	int shift;
	
	/* GCD(0,x) := x */
	if (u == 0 || v == 0)
		return u | v;
	
	/* Let shift := lg K, where K is the greatest power of 2
	 * dividing both u and v. */
	for(shift = 0; ((u | v) & 1) == 0; ++shift) {
		u >>= 1;
		v >>= 1;
	}
	
	while ((u & 1) == 0) u >>= 1;
	
	/* From here on, u is always odd. */
	do {
		while ((v & 1) == 0)  /* Loop X */
			v >>= 1;
		
		/* Now u and v are both odd, so diff(u, v) is even.
		 * Let u = min(u, v), v = diff(u, v)/2. */
		if (u < v) {
			v -= u;
		} else {
			unsigned int diff = u - v;
			u = v;
			v = diff;
		}
		v >>= 1;
	} while (v != 0);
	
	return u << shift;
}

static unsigned int lcm(unsigned int u, unsigned int v)
{
	return u*v/gcd(u, v);
}

/*
 * Memory is split in elements of the size of a bookkeeping
 * record (struct m_bk).
 * Those records are placed in front of each chunk.
 */
struct m_bk {
	/* Indice of next element. If there is no next element,
	 * this condition can be spotted by using the last_allocated
	 * field of the bank, and this indice is invalid.
	 */
	unsigned int next;
	/* Size of the allocation in elements, counting this one. */
	unsigned int size;
} __attribute__((packed));

struct malloc_bank *m_banks;
static unsigned int m_nbanks;
static unsigned int m_defaultbank;

static inline struct m_bk *getbk(unsigned int bank)
{
	return (struct m_bk *)(m_banks[bank].addr_start);
}

static inline unsigned int getnbk(unsigned int bank)
{
	return (m_banks[bank].addr_end - m_banks[bank].addr_start)/sizeof(struct m_bk);
}

void malloc_init(struct malloc_bank *banks, unsigned int n, unsigned int defaultbank)
{
	unsigned int i;
	
	m_banks = banks;
	m_nbanks = n;
	m_defaultbank = defaultbank;
	
	for(i=0;i<n;i++) {
		m_banks[i].first_allocated = -1;
		m_banks[i].last_allocated = -1;
	}
}

void *mallocex(unsigned int size, unsigned int bank, unsigned int alignment)
{
	struct malloc_bank *b;
	unsigned int extra;
	unsigned int datastart;
	int freespace;
	struct m_bk *bk;
	int curindex;
	int allocindex;
	
	if(size == 0) return NULL;
	
	/* Resolve alignment and size constraints */
	alignment = lcm(alignment, sizeof(struct m_bk));
	if((size % sizeof(struct m_bk)) != 0)
		size += sizeof(struct m_bk) - (size % sizeof(struct m_bk));
	
	b = &m_banks[bank]; /* convenience pointers */
	bk = getbk(bank);
	
	/* First, try allocation at the beginning of the bank */
	
	/* How much space we will need to respect the alignment constraint */
	datastart = b->addr_start + sizeof(struct m_bk);
	if((datastart % alignment) != 0)
		extra = alignment - (datastart % alignment);
	else
		extra = 0;
	
	/* Case: bank is entirely free */
	if(b->first_allocated == -1) {
		freespace = b->addr_end - b->addr_start;
		if(freespace < (size + extra + sizeof(struct m_bk)))
			return NULL; /* bank is too small for requested buffer */
			
		/* Everything OK, perform the allocation */
		extra /= sizeof(struct m_bk);
		size /= sizeof(struct m_bk);
		bk[extra].size = size+1;
		b->first_allocated = extra;
		b->last_allocated = extra;
		return &bk[extra+1];
	}
	
	/* Case: can allocate at the very beginning of the bank */
	freespace = sizeof(struct m_bk)*b->first_allocated;
	if(freespace >= (size + extra + sizeof(struct m_bk))) {
		extra /= sizeof(struct m_bk);
		size /= sizeof(struct m_bk);
		bk[extra].next = b->first_allocated;
		bk[extra].size = size+1;
		b->first_allocated = extra;
		return &bk[extra+1];
	}
	
	/* Case: can allocate after the last chunk */
	datastart = b->addr_start
		+ (b->last_allocated+bk[b->last_allocated].size+1)*sizeof(struct m_bk);
	if((datastart % alignment) != 0)
		extra = alignment - (datastart % alignment);
	else
		extra = 0;
	freespace = sizeof(struct m_bk)*(getnbk(bank) - b->last_allocated - bk[b->last_allocated].size);
	if(freespace >= (size + extra + sizeof(struct m_bk))) {
		extra /= sizeof(struct m_bk);
		size /= sizeof(struct m_bk);
		allocindex = b->last_allocated + bk[b->last_allocated].size + extra;
		bk[b->last_allocated].next = allocindex;
		bk[allocindex].size = size+1;
		b->last_allocated = allocindex;
		return &bk[allocindex+1];
	}
	
	/* Case: can allocate between two chunks */
	curindex = b->first_allocated;
	while(curindex < b->last_allocated) {
		int nextindex;
		
		nextindex = bk[curindex].next;
		
		datastart = b->addr_start
			+ (curindex+bk[curindex].size+1)*sizeof(struct m_bk);
		if((datastart % alignment) != 0)
			extra = alignment - (datastart % alignment);
		else
			extra = 0;
		
		freespace = sizeof(struct m_bk)*(nextindex - (curindex + bk[curindex].size));
		
		if(freespace >= (size + extra + sizeof(struct m_bk))) {
			extra /= sizeof(struct m_bk);
			size /= sizeof(struct m_bk);
			
			allocindex = curindex + bk[curindex].size + extra;
			bk[allocindex].size = size+1;
			bk[allocindex].next = nextindex;
			bk[curindex].next = allocindex;
			
			return &bk[allocindex+1];
		}
		
		curindex = nextindex;
	}
	return NULL;
}

#ifdef PC_TEST
void test_free(void *p)
#else
void free(void *p)
#endif
{
	struct malloc_bank *b;
	struct m_bk *bk;
	unsigned int i;
	unsigned int pa;
	unsigned int pbki;
	
	pa = (unsigned int)p;
	
	//printf("free: %08x\n", pa);
	
	/* Find which bank p belongs to */
	b = NULL;
	bk = NULL;
	for(i=0;i<m_nbanks;i++) 
		if((m_banks[i].addr_start <= pa) && (m_banks[i].addr_end > pa)) {
			bk = getbk(i);
			b = &m_banks[i];
			break;
		}
	if(b == NULL) {
#ifdef PC_TEST
		printf("ERR: Trying to free a pointer out of any bank\n");
#endif
		return;
	}

	/* Case: freeing the only chunk */
	if(b->first_allocated == b->last_allocated) {
		/* We assume p is the data of the only chunk (as it should) */
		b->first_allocated = -1;
		b->last_allocated = -1;
		return;
	}
	
	pbki = (pa - b->addr_start)/sizeof(struct m_bk) - 1;
	
	/* Case: freeing the first chunk */
	if(pbki == b->first_allocated) {
		b->first_allocated = bk[b->first_allocated].next;
		return;
	}
	
	/* Case: freeing the last chunk */
	if(pbki == b->last_allocated) {
		i = b->first_allocated;
		while(bk[i].next != pbki)
			i = bk[i].next;
		b->last_allocated = i;
		return;
	}
	
	/* Case: freeing a chunk between two others */
	i = b->first_allocated;
	while(bk[i].next != pbki)
		i = bk[i].next;
	bk[i].next = bk[pbki].next;
}

#ifdef PC_TEST
void *test_malloc(size_t size)
#else
void *malloc(size_t size)
#endif
{
	void *r;
	r = mallocex(size, m_defaultbank, 1);
	//printf("alloc: %08x\n", (unsigned int)r);
	return r;
}

#ifdef PC_TEST
void *test_calloc(size_t nmemb, size_t size)
#else
void *calloc(size_t nmemb, size_t size)
#endif
{
	void *ret;

	size *= nmemb;
	ret = malloc(size);
	if(ret == NULL) return ret;
	memset(ret, 0, size);
	return ret;
}
