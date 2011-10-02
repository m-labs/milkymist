/*
 * lnfpus.c - O(n) ... O(n^2) scheduler
 *
 * Copyright (C) 2011 Werner Almesberger
 *
 * Based on gfpus.c
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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>

#include <fpvm/is.h>
#include <fpvm/fpvm.h>
#include <fpvm/pfpu.h>
#include <fpvm/schedulers.h>

#include <hw/pfpu.h>


//#define	REG_STATS
#define	LCPF	/* longest critical path first */

//#define DEBUG
#ifdef DEBUG
#define	Dprintf printf
#else
#define	Dprintf(...)
#endif


#define	MAX_LATENCY	8	/* maximum latency; okay to make this bigger */

#define	CODE(n)		(((pfpu_instruction *) (code+(n)))->i)


struct list {
	struct list *next, *prev;
};


struct insn {
	struct list more;		/* more insns on same schedule */
	struct fpvm_instruction *vm_insn;
	struct data_ref {
		struct list more;	/* more refs sharing the data */
		struct insn *insn;	/* insn this is part of */
		struct insn *dep;	/* insn we depend on */
	} opa, opb, dest, cond;
	int arity;
	int latency;
	int rmw;	/* non-zero if instruction is read-modify-write */
	int unresolved;	/* number of data refs we need before we can sched */
	int earliest;	/* earliest cycle dependencies seen so far are met */
	struct list dependants;	/* list of dependencies (constant) */
	int num_dependants;	/* number of dependencies */
	struct insn *next_setter; /* next setter of the same register */
#ifdef LCPF
	int distance;		/* minimum cycles on this path until the end */
#endif
};


struct vm_reg {
	struct insn *setter;	/* instruction setting it; NULL if none */
	struct insn *first_setter; /* first setter */
	int pfpu_reg;		/* underlying PFPU register */
	int refs;		/* usage count */
};


struct pfpu_reg {
	struct list more;	/* list of unallocated PFPU registers */
	int vm_reg;		/* corresponding FPVM register if allocated */
	int used;		/* used somewhere in the program */
};


static struct sched_ctx {
	struct fpvm_fragment *frag;
	struct insn insns[FPVM_MAXCODELEN];
	struct vm_reg *regs;	/* dynamically allocated */
	struct pfpu_reg pfpu_regs[PFPU_REG_COUNT];
	struct list unallocated; /* unallocated registers */
	struct list unscheduled; /* unscheduled insns */
	struct list waiting;	/* insns waiting to be scheduled */
	struct list ready[PFPU_PROGSIZE]; /* insns ready at nth cycle */
	int cycle;		/* the current cycle */
#ifdef REG_STATS
	int max_regs, curr_regs;	/* allocation statistics */
#endif
} *sc;


/* ----- Register initialization ------------------------------------------- */


/*
 * Straight from gfpus.c, only with some whitespace changes.
 */

static void get_registers(struct fpvm_fragment *fragment,
    unsigned int *registers)
{
	int i;
	union {
		float f;
		unsigned int n;
	} fconv;

	for(i = 0; i < fragment->nbindings; i++)
		if(fragment->bindings[i].isvar)
			registers[i] = 0;
		else {
			fconv.f = fragment->bindings[i].b.c;
			registers[i] = fconv.n;
		}
	for(; i < PFPU_REG_COUNT; i++)
		registers[i] = 0;
}


/* ----- Doubly-linked list ------------------------------------------------ */


/*
 * Use the naming conventions of include/linux/list.h
 */


#ifdef DEBUG

static void list_poison(struct list *list)
{
	list->next = list->prev = NULL;
}

#else /* DEBUG */

#define list_poison(list)

#endif /* !DEBUG */


static void list_init(struct list *list)
{
	list->next = list->prev = list;
}


static void list_del(struct list *item)
{
	assert(item->next != item);
	item->prev->next = item->next;
	item->next->prev = item->prev;
	list_poison(item);
}


static void *list_pop(struct list *list)
{
	struct list *first;

	first = list->next;
	if(first == list)
		return NULL;
	list_del(first);
	return first;
}


static void list_add_tail(struct list *list, struct list *item)
{
	item->next = list;
	item->prev = list->prev;
	list->prev->next = item;
	list->prev = item;
}


static void list_add(struct list *list, struct list *item)
{
	item->next = list->next;
	item->prev = list;
	list->next->prev = item;
	list->next = item;
}


static void list_concat(struct list *a, struct list *b)
{
	if(b->next != b) {
		a->prev->next = b->next;
		b->next->prev = a->prev;
		b->prev->next = a;
		a->prev = b->prev;
	}
	list_poison(b);
}


/*
 * Do not delete elements from the list while traversing it with foreach !
 */

#define	foreach(var, head) \
	for(var = (void *) ((head))->next; \
	    (var) != (void *) (head); \
	    var = (void *) ((struct list *) (var))->next)


/* ----- Register management ----------------------------------------------- */


static int vm_reg2idx(int reg)
{
	return reg >= 0 ? reg : sc->frag->nbindings-reg;
}


static int alloc_reg(struct insn *setter)
{
	struct pfpu_reg *reg;
	int vm_reg, pfpu_reg, vm_idx;

	vm_reg = setter->vm_insn->dest;
	if(vm_reg >= 0) {
		pfpu_reg = vm_reg;
		sc->pfpu_regs[vm_reg].vm_reg = vm_reg; /* @@@ global init */
	} else {
		reg = list_pop(&sc->unallocated);
		if(!reg)
			return -1;

		#ifdef REG_STATS
		sc->curr_regs++;
		if(sc->curr_regs > sc->max_regs)
			sc->max_regs = sc->curr_regs;
		#endif

		reg->vm_reg = vm_reg;
		pfpu_reg = reg-sc->pfpu_regs;
	}

	Dprintf("  alloc reg %d -> %d\n", vm_reg, pfpu_reg);

	vm_idx = vm_reg2idx(vm_reg);
	sc->regs[vm_idx].setter = setter;
	sc->regs[vm_idx].pfpu_reg = pfpu_reg;
	sc->regs[vm_idx].refs = setter->num_dependants+1;

	return pfpu_reg;
}


static void put_reg(int vm_reg)
{
	int vm_idx;
	struct vm_reg *reg;

	if(vm_reg >= 0)
		return;

	vm_idx = vm_reg2idx(vm_reg);
	reg = sc->regs+vm_idx;

	assert(reg->refs);
	if(--reg->refs)
		return;

	Dprintf("  free reg %d\n", reg->pfpu_reg);

#ifdef REG_STATS
	assert(sc->curr_regs);
	sc->curr_regs--;
#endif

	/*
	 * Prepend so that register numbers stay small and bugs reveal
	 * themselves more rapidly.
	 */
	list_add(&sc->unallocated, &sc->pfpu_regs[reg->pfpu_reg].more);

	/* clear it for style only */
	reg->setter = NULL;
	reg->pfpu_reg = 0;
}


static int lookup_pfpu_reg(int vm_reg)
{
	return vm_reg >= 0 ? vm_reg : sc->regs[vm_reg2idx(vm_reg)].pfpu_reg;
}


static void mark(int vm_reg)
{
	if(vm_reg > 0)
		sc->pfpu_regs[vm_reg].used = 1;
}


static int init_registers(struct fpvm_fragment *frag,
    unsigned int *registers)
{
	int i;

	get_registers(frag, registers);

	for(i = 0; i != frag->ninstructions; i++) {
		mark(frag->code[i].opa);
		mark(frag->code[i].opb);
		mark(frag->code[i].dest);
	}

	list_init(&sc->unallocated);
	for(i = PFPU_SPREG_COUNT; i != PFPU_REG_COUNT; i++)
		if(!sc->pfpu_regs[i].used)
			list_add_tail(&sc->unallocated, &sc->pfpu_regs[i].more);

	return 0;
}


/* ----- Instruction scheduler --------------------------------------------- */


static struct vm_reg *add_data_ref(struct insn *insn, struct data_ref *ref,
    int reg_num)
{
	struct vm_reg *reg;

	reg = sc->regs+vm_reg2idx(reg_num);
	ref->insn = insn;
	ref->dep = reg->setter;
	if(insn->vm_insn->dest == reg_num)
		insn->rmw = 1;
	if(!ref->dep)
		reg->refs++;
	else {
		list_add_tail(&ref->dep->dependants, &ref->more);
		ref->dep->num_dependants++;
		insn->unresolved++;

		Dprintf("insn %lu: reg %d setter %lu unresolved %d\n",
		    insn-sc->insns, reg_num, reg->setter-sc->insns,
		    insn->unresolved);
	}
	return reg;
}


static void init_scheduler(struct fpvm_fragment *frag)
{
	int i;
	struct insn *insn;
	struct vm_reg *reg;
	struct data_ref *ref;

	list_init(&sc->unscheduled);
	list_init(&sc->waiting);
	for(i = 0; i != PFPU_PROGSIZE; i++)
		list_init(sc->ready+i);

	for(i = 0; i != frag->ninstructions; i++) {
		insn = sc->insns+i;
		insn->vm_insn = frag->code+i;
		insn->arity = fpvm_get_arity(frag->code[i].opcode);
		insn->latency = pfpu_get_latency(frag->code[i].opcode);
		list_init(&insn->dependants);
		switch (insn->arity) {
			case 3:
				add_data_ref(insn, &insn->cond, FPVM_REG_IFB);
				/* fall through */
			case 2:
				add_data_ref(insn, &insn->opb, frag->code[i].opb);
				/* fall through */
			case 1:
				add_data_ref(insn, &insn->opa, frag->code[i].opa);
				/* fall through */
			case 0:
				reg = sc->regs+vm_reg2idx(frag->code[i].dest);
				if(reg->setter) {
					reg->setter->next_setter = insn;
					foreach(ref, &reg->setter->dependants)
						if(ref->insn != insn)
							insn->unresolved++;
					if(!insn->rmw)
						insn->unresolved++;
				} else {
					if(!insn->rmw)
						insn->unresolved += reg->refs;
					reg->first_setter = insn;
				}
				reg->setter = insn;
				break;
			default:
				abort();
		}
		if(insn->unresolved)
			list_add_tail(&sc->unscheduled, &insn->more);
		else
			list_add_tail(&sc->ready[0], &insn->more);
	}

#ifdef LCPF
	struct data_ref *dep;

	for(i = frag->ninstructions-1; i >= 0; i--) {
		insn = sc->insns+i;
#if 0
		/*
		 * Theoretically, we should consider the distance through
		 * write-write dependencies too. In practice, this would
		 * mainly matter if we had operations whose result is ignored.
		 * This is a degenerate case that's probably not worth
		 * spending much effort on.
		 */
		if(insn->next_setter) {
			insn->distance =
			    insn->next_setter->distance-insn->distance+1;
			if(insn->distance < 1)
				insn->distance = 1;
		}
#endif
		foreach(dep, &insn->dependants)
			if(dep->insn->distance > insn->distance)
				insn->distance = dep->insn->distance;
		/*
		 * While it would be more correct to add one for the cycle
		 * following the write cycle, this also has the effect of
		 * producing slighly worse results on the example set of
		 * patches. Let's thus keep this "bug" for now.
		 */
//		insn->distance += insn->latency+1;
		insn->distance += insn->latency;
	}
#endif
}


static void unblock(struct insn *insn)
{
	int slot;

	assert(insn->unresolved);
	if(--insn->unresolved)
		return;
	Dprintf("  unblocked %lu -> %u\n", insn-sc->insns, insn->earliest);
	list_del(&insn->more);
	slot = insn->earliest;
	if(slot <= sc->cycle)
		slot = sc->cycle+1;
	list_add_tail(sc->ready+slot, &insn->more);
}


static void put_reg_by_ref(struct data_ref *ref, int vm_reg)
{
	struct insn *setter = ref->dep;
	struct vm_reg *reg;

	if(setter) {
		put_reg(setter->vm_insn->dest);
		if(setter->next_setter && setter->next_setter != ref->insn)
			unblock(setter->next_setter);
	} else {
		reg = sc->regs+vm_reg2idx(vm_reg);
		if(reg->first_setter && !reg->first_setter->rmw)
			unblock(reg->first_setter);
	}
}


static void unblock_after(struct insn *insn, int cycle)
{
	if(insn->earliest <= cycle)
		insn->earliest = cycle+1;
	unblock(insn);
}


static int issue(struct insn *insn, unsigned *code)
{
	struct data_ref *ref;
	int end, reg;

	end = sc->cycle+insn->latency;

	Dprintf("cycle %d: insn %lu L %d (A %d B %d)\n", sc->cycle,
	    insn-sc->insns, insn->latency, insn->vm_insn->opa,
	    insn->vm_insn->opb);

	switch (insn->arity) {
		case 3:
			put_reg_by_ref(&insn->cond, FPVM_REG_IFB);
			/* fall through */
		case 2:
			CODE(sc->cycle).opb = lookup_pfpu_reg(insn->vm_insn->opb);
			put_reg_by_ref(&insn->opb, insn->vm_insn->opb);
			/* fall through */
		case 1:
			CODE(sc->cycle).opa = lookup_pfpu_reg(insn->vm_insn->opa);
			put_reg_by_ref(&insn->opa, insn->vm_insn->opa);
			break;
		case 0:
			break;
		default:
			abort();
	}

	reg = alloc_reg(insn);
	if(reg < 0)
		return -1;
	CODE(end).dest = reg;
	CODE(sc->cycle).opcode = fpvm_to_pfpu(insn->vm_insn->opcode);

	foreach(ref, &insn->dependants)
		unblock_after(ref->insn, end);
	if(insn->next_setter && !insn->next_setter->rmw)
		unblock_after(insn->next_setter,
		    end-insn->next_setter->latency);

	return 0;
}


#ifdef DEBUG
static int count(const struct list *list)
{
	int n = 0;
	const struct list *p;

	for(p = list->next; p != list; p = p->next)
		n++;
	return n;
}
#endif


static int schedule(unsigned int *code)
{
	int remaining;
	int i, last, end;
	struct insn *insn;
	struct insn *best;

	remaining = sc->frag->ninstructions;
	for(i = 0; remaining; i++) {
		if(i == PFPU_PROGSIZE)
			return -1;

		sc->cycle = i;
		Dprintf("@%d --- remaining %d, waiting %d + ready %d\n",
		    i, remaining, count(&sc->waiting), count(&sc->ready[i]));

		list_concat(&sc->waiting, sc->ready+i);
		best = NULL;
		foreach(insn, &sc->waiting) {
			end = i+insn->latency;
			if(end >= PFPU_PROGSIZE)
				return -1;
			if(!CODE(end).dest) {
#ifdef LCPF
				if(!best || best->distance < insn->distance)
					best = insn;
#else
				best = insn;
				break;
#endif
			}
		}
		if(best) {
			if(issue(best, code) < 0)
				return -1;
			list_del(&best->more);
			remaining--;
		}
		if(CODE(i).dest)
			put_reg(sc->pfpu_regs[CODE(i).dest].vm_reg);
	}

	/*
	 * Add NOPs to cover unfinished instructions.
	 */
	last = i;
	end = i+MAX_LATENCY;
	if(end > PFPU_PROGSIZE)
		end = PFPU_PROGSIZE;
	while(i != end) {
		if(CODE(i).dest)
			last = i+1;
		i++;
	}
	return last;
}


int lnfpus_schedule(struct fpvm_fragment *frag, unsigned int *code,
    unsigned int *reg)
{
	/*
	 * allocate context and registers on stack because standalone FN has no
	 * memory allocator
	 */
	struct sched_ctx sc_alloc;
	struct vm_reg regs[frag->nbindings-frag->next_sur];
	pfpu_instruction vecout;
	int res;

	sc = &sc_alloc;
	memset(sc, 0, sizeof(*sc));
	sc->frag = frag;
	sc->regs = regs;
	memset(regs, 0, sizeof(regs));

	if(init_registers(frag, reg) < 0)
		return -1;
	init_scheduler(frag);

	memset(code, 0, PFPU_PROGSIZE*sizeof(*code));
	res = schedule(code);

#ifdef REG_STATS
	printf("regs: %d/%d\n", sc->curr_regs, sc->max_regs);
#endif

	if(res < 0)
		return res;
	if(frag->vector_mode)
		return res;
	if(res == PFPU_PROGSIZE)
		return -1;

	vecout.w = 0;
	vecout.i.opcode = FPVM_OPCODE_VECTOUT;
	code[res] = vecout.w;

	return res+1;
}
