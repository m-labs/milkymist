/*
 * Milkymist SoC (Software)
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

#include <stdio.h>

#include <fpvm/is.h>
#include <fpvm/fpvm.h>
#include <fpvm/pfpu.h>
#include <fpvm/gfpus.h>

#include <hw/pfpu.h>

//#define GFPUS_DEBUG

static void get_registers(struct fpvm_fragment *fragment, unsigned int *registers)
{
	int i;
	union {
		float f;
		unsigned int n;
	} fconv;

	for(i=0;i<fragment->nbindings;i++)
		if(fragment->bindings[i].isvar)
			registers[i] = 0;
		else {
			fconv.f = fragment->bindings[i].b.c;
			registers[i] = fconv.n;
		}
	for(;i<PFPU_REG_COUNT;i++)
		registers[i] = 0;
}

struct scheduler_state {
	struct fpvm_fragment *fragment;
	
	int dont_touch[PFPU_REG_COUNT];
	int register_allocation[PFPU_REG_COUNT];
	int exits[FPVM_MAXCODELEN];
	int last_exit;
	pfpu_instruction *prog;
};

static void init_scheduler_state(struct scheduler_state *sc, struct fpvm_fragment *fragment, unsigned int *code)
{
	int i;
	
	sc->fragment = fragment;
	sc->prog = (pfpu_instruction *)code;
	
	for(i=0;i<PFPU_SPREG_COUNT;i++)
		sc->dont_touch[i] = 1;
	for(;i<PFPU_REG_COUNT;i++)
		sc->dont_touch[i] = 0;
	for(i=0;i<PFPU_REG_COUNT;i++)
		sc->register_allocation[i] = FPVM_INVALID_REG;
	for(i=0;i<FPVM_MAXCODELEN;i++)
		sc->exits[i] = -1;
	for(i=0;i<PFPU_PROGSIZE;i++)
		sc->prog[i].w = 0;
	sc->last_exit = -1;

	for(i=0;i<fragment->ninstructions;i++) {
		if(fragment->code[i].opa > 0)
			sc->dont_touch[fragment->code[i].opa] = 1;
		if(fragment->code[i].opb > 0)
			sc->dont_touch[fragment->code[i].opb] = 1;
		if(fragment->code[i].dest > 0)
			sc->dont_touch[fragment->code[i].dest] = 1;
	}
}

/*
 * Check that any instruction before 'instruction'
 * that writes to register 'reg' has completed at cycle 'cycle'.
 * Returns 1 if ok.
 */
static int check_hazard_write(struct scheduler_state *sc, int reg, int cycle, int instruction)
{
	int i;

	#ifdef GFPUS_DEBUG
	printf("check_hazard_write: reg=%d cycle=%d isn=%d: ", reg, cycle, instruction);
	#endif
	for(i=instruction-1;i>=0;i--)
		if(sc->fragment->code[i].dest == reg) {
			#ifdef GFPUS_DEBUG
			printf("previous isn %d ", i);
			#endif
			if((sc->exits[i] > 0) && (cycle > sc->exits[i])) {
				#ifdef GFPUS_DEBUG
				printf("completed (%d)\n", sc->exits[i]);
				#endif
				return 1;
			} else {
				#ifdef GFPUS_DEBUG
				printf("not completed (%d)\n", sc->exits[i]);
				#endif
				return 0;
			}
		}
	#ifdef GFPUS_DEBUG
	printf("no previous isn\n");
	#endif
	return 1;
}

/*
 * Check that any instruction before 'instruction'
 * that reads register 'reg' has been scheduled.
 * Returns 1 if ok.
 */
static int check_hazard_read(struct scheduler_state *sc, int reg, int instruction)
{
	int i;

	for(i=instruction-1;i>0;i--) {
		if(sc->exits[i] < 0) {
			switch(fpvm_get_arity(sc->fragment->code[i].opcode)) {
				case 2:
					if(sc->fragment->code[i].opb == reg) return 0;
					/* fall through */
				case 1:
					if(sc->fragment->code[i].opa == reg) return 0;
					/* fall through */
				case 0:
					break;
				default:
					/* we should not get here - make the compilation fail */
					return 0;
			}
		}
	}
	return 1;
}

static int allocate_pfpu_register(struct scheduler_state *sc, int reg)
{
	int i;

	if(reg >= 0) return reg;
	for(i=0;i<PFPU_REG_COUNT;i++) {
		if(sc->dont_touch[i]) continue;
		if(sc->register_allocation[i] == FPVM_INVALID_REG) {
			sc->register_allocation[i] = reg;
			return i;
		}
	}
	return -1;
}

static int find_pfpu_register(struct scheduler_state *sc, int reg)
{
	int i;

	if(reg >= 0) return reg;
	for(i=0;i<PFPU_REG_COUNT;i++)
		if(sc->register_allocation[i] == reg) return i;
	return -1;
}

static void try_free_register(struct scheduler_state *sc, int reg)
{
	int i;

	if(reg >= 0) return;

	for(i=0;i<sc->fragment->ninstructions;i++) {
		if(sc->exits[i] < 0) {
			switch(fpvm_get_arity(sc->fragment->code[i].opcode)) {
				case 2:
					if(sc->fragment->code[i].opb == reg) return;
					/* fall through */
				case 1:
					if(sc->fragment->code[i].opa == reg) return;
					/* fall through */
				case 0:
					break;
				default:
					/* should not get here */
					return;
			}
		}
	}

	#ifdef GFPUS_DEBUG
	printf("freeing FPVM register %d (PFPU:", reg);
	#endif
	for(i=0;i<PFPU_REG_COUNT;i++)
		if(sc->register_allocation[i] == reg) {
			#ifdef GFPUS_DEBUG
			printf(" %d", i);
			#endif
			sc->register_allocation[i] = FPVM_INVALID_REG;
		}
	#ifdef GFPUS_DEBUG
	printf(")\n");
	#endif
}

/*
 * -1: fatal error
 *  0: instruction cannot be scheduled
 *  1: instruction was scheduled
 */
static int schedule_one(struct scheduler_state *sc, int cycle, int instruction)
{
	int exit;
	int opa, opb, dest;

	if(sc->exits[instruction] != -1) return 0; /* already scheduled */

	exit = pfpu_get_latency(fpvm_to_pfpu(sc->fragment->code[instruction].opcode));
	if(exit < 0) {
		#ifdef GFPUS_DEBUG
		printf("schedule_one: invalid opcode\n");
		#endif
		return -1;
	}
	exit += cycle;
	if(exit >= PFPU_PROGSIZE) {
		#ifdef GFPUS_DEBUG
		printf("schedule_one: instruction can never exit\n");
		#endif
		return -1;
	}

	if(sc->prog[exit].i.dest != 0) return 0; /* exit conflict */

	/* Check for RAW hazards */
	switch(fpvm_get_arity(sc->fragment->code[instruction].opcode)) {
		case 3:
			/* 3rd operand is always R2 (REG_IFB) */
			if(!check_hazard_write(sc, FPVM_REG_IFB, cycle, instruction)) return 0;
			/* fall through */
		case 2:
			if(!check_hazard_write(sc, sc->fragment->code[instruction].opb, cycle, instruction)) return 0;
			/* fall through */
		case 1:
			if(!check_hazard_write(sc, sc->fragment->code[instruction].opa, cycle, instruction)) return 0;
			/* fall through */
		case 0:
			break;
		default:
			#ifdef GFPUS_DEBUG
			printf("schedule_one: unexpected arity\n");
			#endif
			return -1;
	}
	/* Check for WAR hazards */
	if(!check_hazard_read(sc, sc->fragment->code[instruction].dest, instruction)) return 0;
	/* Check for WAW hazards */
	if(!check_hazard_write(sc, sc->fragment->code[instruction].dest, cycle, instruction)) return 0;

	/* Instruction can be scheduled */

	/* Find operands */
	opa = opb = 0;
	switch(fpvm_get_arity(sc->fragment->code[instruction].opcode)) {
		case 3:
			/* 3rd operand is always R2 (REG_IFB) */
			/* fall through */
		case 2:
			opb = find_pfpu_register(sc, sc->fragment->code[instruction].opb);
			/* fall through */
		case 1:
			opa = find_pfpu_register(sc, sc->fragment->code[instruction].opa);
			/* fall through */
		case 0:
			break;
		default:
			#ifdef GFPUS_DEBUG
			printf("schedule_one: unexpected arity\n");
			#endif
			return -1;
	}
	if((opa < 0)||(opb < 0)) {
		#ifdef GFPUS_DEBUG
		int i;
		
		printf("schedule_one: operands not found\n");
		printf("looking for %d / %d, got %d / %d\n", sc->fragment->code[instruction].opa, sc->fragment->code[instruction].opb, opa, opb);
		printf("register allocation:\n");
		for(i=0;i<PFPU_REG_COUNT;i++)
			printf("%d: %d\n", i, sc->register_allocation[i]);
		#endif
		return -1;
	}

	sc->exits[instruction] = exit; /* write exit now (needed for try_free_register) */
	/* If operands are not used by other pending instructions, free their registers */
	switch(fpvm_get_arity(sc->fragment->code[instruction].opcode)) {
		case 3:
			try_free_register(sc, FPVM_REG_IFB);
			/* fall through */
		case 2:
			try_free_register(sc, sc->fragment->code[instruction].opb);
			/* fall through */
		case 1:
			try_free_register(sc, sc->fragment->code[instruction].opa);
			/* fall through */
		case 0:
			break;
		default:
			#ifdef GFPUS_DEBUG
			printf("schedule_one: unexpected arity\n");
			#endif
			return -1;
	}

	/* Find destination */
	if(sc->fragment->code[instruction].dest != 0) {
		dest = allocate_pfpu_register(sc, sc->fragment->code[instruction].dest);
		#ifdef GFPUS_DEBUG
		printf("allocated PFPU register: %d (for %d)\n", dest, sc->fragment->code[instruction].dest);
		#endif
		if(dest == -1) {
			#ifdef GFPUS_DEBUG
			printf("schedule_one: destination not found\n");
			#endif
			return -1;
		}
		sc->register_allocation[dest] = sc->fragment->code[instruction].dest;
	} else
		dest = 0;

	/* Write instruction */
	sc->prog[cycle].i.opa = opa;
	sc->prog[cycle].i.opb = opb;
	sc->prog[cycle].i.opcode = fpvm_to_pfpu(sc->fragment->code[instruction].opcode);
	sc->prog[exit].i.dest = dest;
	if(exit > sc->last_exit) sc->last_exit = exit;

	return 1;
}

static int schedule(struct scheduler_state *sc)
{
	int i, j;
	int remaining;
	int r;

	if(sc->fragment->ninstructions < 1) return 1;
	remaining = sc->fragment->ninstructions;
	for(i=0;i<FPVM_MAXCODELEN;i++) {
		for(j=0;j<sc->fragment->ninstructions;j++) {
			r = schedule_one(sc, i, j);
			if(r == -1) {
				#ifdef GFPUS_DEBUG
				printf("scheduler_schedule: returned error, cycle=%d isn=%d\n", i, j);
				#endif
				return 0;
			}
			if(r == 1) {
				remaining--;
				if(remaining == 0) {
					if(!sc->fragment->vector_mode) {
						/* add a VECTOUT at the end */
						sc->last_exit++;
						if(sc->last_exit >= PFPU_PROGSIZE)
							goto outofspace;
						sc->prog[sc->last_exit].i.opa = 0;
						sc->prog[sc->last_exit].i.opb = 0;
						sc->prog[sc->last_exit].i.opcode = FPVM_OPCODE_VECTOUT;
						sc->prog[sc->last_exit].i.dest = 0;
					}
					return 1;
				}
				break;
			}
			/* r == 0 */
		}
	}

outofspace:
	#ifdef GFPUS_DEBUG
	printf("scheduler_schedule: out of program space\n");
	#endif
	return 0;
}

int gfpus_schedule(struct fpvm_fragment *fragment, unsigned int *code, unsigned int *registers)
{
	struct scheduler_state sc;

	get_registers(fragment, registers);

	init_scheduler_state(&sc, fragment, code);
	if(!schedule(&sc)) return -1;

	return sc.last_exit + 1;
}

