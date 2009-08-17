/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 *
 * This program is free and excepted software; you can use it, redistribute it
 * and/or modify it under the terms of the Exception General Public License as
 * published by the Exception License Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the Exception General Public License for more
 * details.
 *
 * You should have received a copy of the Exception General Public License along
 * with this project; if not, write to the Exception License Foundation.
 */

#include <libc.h>
#include <console.h>
#include <hw/pfpu.h>

#include "scheduler.h"

//#define SCHEDULER_DEBUG

static int get_latency(int opcode)
{
	switch(opcode) {
		case PFPU_OPCODE_FADD: return PFPU_LATENCY_FADD;
		case PFPU_OPCODE_FSUB: return PFPU_LATENCY_FSUB;
		case PFPU_OPCODE_FMUL: return PFPU_LATENCY_FMUL;
		case PFPU_OPCODE_FDIV: return PFPU_LATENCY_FDIV;
		case PFPU_OPCODE_F2I: return PFPU_LATENCY_F2I;
		case PFPU_OPCODE_I2F: return PFPU_LATENCY_I2F;
		case PFPU_OPCODE_VECT: return PFPU_LATENCY_VECT;
		case PFPU_OPCODE_SIN: return PFPU_LATENCY_SIN;
		case PFPU_OPCODE_COS: return PFPU_LATENCY_COS;
		case PFPU_OPCODE_ABOVE: return PFPU_LATENCY_ABOVE;
		case PFPU_OPCODE_EQUAL: return PFPU_LATENCY_EQUAL;
		case PFPU_OPCODE_COPY: return PFPU_LATENCY_COPY;
		default: return -1;
	}
}

void scheduler_init(struct scheduler_state *sc)
{
	int i;

	for(i=0;i<PFPU_REG_COUNT;i++)
		sc->dont_touch[i] = pfpu_is_reserved(i);
	for(i=0;i<PFPU_REG_COUNT;i++)
		sc->register_allocation[i] = -1;
	for(i=0;i<PFPU_PROGSIZE;i++)
		sc->exits[i] = -1;
	for(i=0;i<PFPU_PROGSIZE;i++)
		sc->prog[i].w = 0;
	sc->last_exit = -1;
}

void scheduler_dont_touch(struct scheduler_state *sc, struct compiler_terminal *terminals)
{
	int i;

	for(i=0;i<PFPU_REG_COUNT;i++)
		if(terminals[i].valid)
			sc->dont_touch[i] = 1;
}

/*
 * Check that any instruction before 'instruction'
 * that writes to register 'reg' has completed at cycle 'cycle'.
 * Returns 1 if ok.
 */
static int check_hazard_write(struct scheduler_state *sc, int reg, int cycle, int instruction, vpfpu_instruction *visn)
{
	int i;

	#ifdef SCHEDULER_DEBUG
	printf("check_hazard_write: reg=%d cycle=%d isn=%d: ", reg, cycle, instruction);
	#endif
	for(i=instruction-1;i>=0;i--)
		if(visn[i].dest == reg) {
			#ifdef SCHEDULER_DEBUG
			printf("previous isn %d ", i);
			#endif
			if((sc->exits[i] > 0) && (cycle > sc->exits[i])) {
				#ifdef SCHEDULER_DEBUG
				printf("completed (%d)\n", sc->exits[i]);
				#endif
				return 1;
			} else {
				#ifdef SCHEDULER_DEBUG
				printf("not completed (%d)\n", sc->exits[i]);
				#endif
				return 0;
			}
		}
	#ifdef SCHEDULER_DEBUG
	printf("no previous isn\n");
	#endif
	return 1;
}

/*
 * Check that any instruction before 'instruction'
 * that reads register 'reg' has been scheduled.
 * Returns 1 if ok.
 */
static int check_hazard_read(struct scheduler_state *sc, int reg, int instruction, vpfpu_instruction *visn)
{
	int i;

	for(i=instruction-1;i>0;i--) {
		if(sc->exits[i] < 0) {
			switch(get_arity(visn[i].opcode)) {
				case 2:
					if(visn[i].opb == reg) return 0;
					/* fall through */
				case 1:
					if(visn[i].opa == reg) return 0;
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

static int allocate_physical_register(struct scheduler_state *sc, int reg)
{
	int i;
	
	if(reg < PFPU_REG_COUNT) return reg;
	for(i=0;i<PFPU_REG_COUNT;i++) {
		if(sc->dont_touch[i]) continue;
		if(sc->register_allocation[i] < 0) {
			sc->register_allocation[i] = reg;
			return i;
		}
	}
	return -1;
}

static int find_physical_register(struct scheduler_state *sc, int reg)
{
	int i;
	
	if(reg < PFPU_REG_COUNT) return reg;
	for(i=0;i<PFPU_REG_COUNT;i++)
		if(sc->register_allocation[i] == reg) return i;
	return -1;
}

static void try_free_register(struct scheduler_state *sc, vpfpu_instruction *visn, int firstisn, int lastisn, int reg)
{
	int i;
	
	if(reg < PFPU_REG_COUNT) return;
	
	for(i=firstisn;i<=lastisn;i++) {
		switch(get_arity(visn[i].opcode)) {
			case 2:
				if(visn[i].opb == reg) return;
				/* fall through */
			case 1:
				if(visn[i].opa == reg) return;
				/* fall through */
			case 0:
				break;
			default:
				/* should not get here */
				return;
		}
	}

	#ifdef SCHEDULER_DEBUG
	printf("freeing virtual register %d (physical:", reg);
	#endif
	for(i=0;i<PFPU_REG_COUNT;i++)
		if(sc->register_allocation[i] == reg) {
			#ifdef SCHEDULER_DEBUG
			printf(" %d", i);
			#endif
			sc->register_allocation[i] = -1;
		}
	#ifdef SCHEDULER_DEBUG
	printf(")\n");
	#endif
}

/*
 * -1: fatal error
 *  0: instruction cannot be scheduled
 *  1: instruction was scheduled
 */
static int schedule_one(struct scheduler_state *sc, int cycle, int instruction, vpfpu_instruction *visn, int vlength)
{
	int exit;
	int opa, opb, dest;
	
	if(sc->exits[instruction] != -1) return 0; /* already scheduled */

	exit = get_latency(visn[instruction].opcode);
	if(exit < 0) {
		#ifdef SCHEDULER_DEBUG
		printf("schedule_one: invalid opcode\n");
		#endif
		return -1;
	}
	exit += cycle;
	if(exit >= PFPU_PROGSIZE) {
		#ifdef SCHEDULER_DEBUG
		printf("schedule_one: instruction can never exit\n");
		#endif
		return -1;
	}

	if(sc->prog[exit].i.dest != 0) return 0; /* exit conflict */
	
	/* Check for RAW hazards */
	switch(get_arity(visn[instruction].opcode)) {
		case 2:
			if(!check_hazard_write(sc, visn[instruction].opb, cycle, instruction, visn)) return 0;
			/* fall through */
		case 1:
			if(!check_hazard_write(sc, visn[instruction].opa, cycle, instruction, visn)) return 0;
			/* fall through */
		case 0:
			break;
		default:
			#ifdef SCHEDULER_DEBUG
			printf("schedule_one: unexpected arity\n");
			#endif
			return -1;
	}
	/* Check for WAR hazards */
	if(!check_hazard_read(sc, visn[instruction].dest, instruction, visn)) return 0;
	/* Check for WAW hazards */
	if(!check_hazard_write(sc, visn[instruction].dest, cycle, instruction, visn)) return 0;

	/* OK - Instruction can be scheduled */

	/* Find operands */
	opa = opb = 0;
	switch(get_arity(visn[instruction].opcode)) {
		case 2:
			opb = find_physical_register(sc, visn[instruction].opb);
			/* fall through */
		case 1:
			opa = find_physical_register(sc, visn[instruction].opa);
			/* fall through */
		case 0:
			break;
		default:
			#ifdef SCHEDULER_DEBUG
			printf("schedule_one: unexpected arity\n");
			#endif
			return -1;
	}
	if((opa < 0)||(opb < 0)) {
		#ifdef SCHEDULER_DEBUG
		printf("schedule_one: operands not found\n");
		#endif
		return -1;
	}

	/* If operands are not used by further instructions, free their registers */
	switch(get_arity(visn[instruction].opcode)) {
		case 2:
			try_free_register(sc, visn, instruction+1, vlength-1, visn[instruction].opb);
			/* fall through */
		case 1:
			try_free_register(sc, visn, instruction+1, vlength-1, visn[instruction].opa);
			/* fall through */
		case 0:
			break;
		default:
			#ifdef SCHEDULER_DEBUG
			printf("schedule_one: unexpected arity\n");
			#endif
			return -1;
	}

	/* Find destination */
	dest = allocate_physical_register(sc, visn[instruction].dest);
	if(dest == -1) {
		#ifdef SCHEDULER_DEBUG
		printf("schedule_one: destination not found\n");
		#endif
		return -1;
	}
	sc->register_allocation[dest] = visn[instruction].dest;

	/* Write instruction */
	sc->prog[cycle].i.opa = opa;
	sc->prog[cycle].i.opb = opb;
	sc->prog[cycle].i.opcode = visn[instruction].opcode;
	sc->prog[exit].i.dest = dest;
	sc->exits[instruction] = exit;
	if(exit > sc->last_exit) sc->last_exit = exit;

	return 1;
}

int scheduler_schedule(struct scheduler_state *sc, vpfpu_instruction *visn, int vlength)
{
	int i, j;
	int remaining;
	int r;

	if(vlength < 1) return 1;
	remaining = vlength;
	for(i=0;i<PFPU_PROGSIZE;i++) {
		for(j=0;j<vlength;j++) {
			r = schedule_one(sc, i, j, visn, vlength);
			if(r == -1) {
				#ifdef SCHEDULER_DEBUG
				printf("scheduler_schedule: returned error, cycle=%d visn=%d\n", i, j);
				#endif
				return 0;
			}
			if(r == 1) {
				remaining--;
				if(remaining == 0) return 1;
				break;
			}
			/* r == 0 */
		}
	}
	
	#ifdef SCHEDULER_DEBUG
	printf("scheduler_schedule: out of program space\n");
	#endif
	return 0;
}

void print_program(struct scheduler_state *sc)
{
	int i;
	int exits;

	exits = 0;
	for(i=0;i<=sc->last_exit;i++) {
		int latency;

		printf("%04d: ", i);

		print_opcode(sc->prog[i].i.opcode);

		switch(get_arity(sc->prog[i].i.opcode)) {
			case 2:
				printf("R%03d,R%03d ", sc->prog[i].i.opa, sc->prog[i].i.opb);
				break;
			case 1:
				printf("R%03d      ", sc->prog[i].i.opa);
				break;
			case 0:
				printf("          ");
		}

		latency = get_latency(sc->prog[i].i.opcode);
		if(sc->prog[i].i.opcode != PFPU_OPCODE_NOP)
			printf("[L=%d E=%04d] ", latency, i+latency);
		else
			printf("             ");

		if(sc->prog[i].i.dest != 0) {
			printf("-> R%03d", sc->prog[i].i.dest);
			exits++;
		}

		printf("\n");
	}
	printf("Efficiency: %d%%\n", 100*exits/(sc->last_exit+1));
}
