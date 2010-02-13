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

#include <stdio.h>
#include <string.h>
#include <hw/pfpu.h>
#include <hw/tmu.h>

#include <hal/pfpu.h>

#include "ast.h"
#include "compiler.h"
#include "scheduler.h"
#include "eval.h"

//#define EVAL_DEBUG

/****************************************************************/
/* PER-FRAME VARIABLES                                          */
/****************************************************************/

static const char pfv_names[EVAL_PFV_COUNT][IDENTIFIER_SIZE] = {
	"cx",
	"cy",
	"rot",
	"dx",
	"dy",
	"zoom",
	"decay",
	"wave_mode",
	"wave_scale",
	"wave_additive",
	"wave_usedots",
	"bMaximizeWaveColor",
	"wave_thick",
	"wave_x",
	"wave_y",
	"wave_r",
	"wave_g",
	"wave_b",
	"wave_a",

	"time",
	"bass",
	"mid",
	"treb",
	"bass_att",
	"mid_att",
	"treb_att"
};

static int pfv_from_name(const char *name)
{
	int i;
	for(i=0;i<EVAL_PFV_COUNT;i++)
		if(strcmp(pfv_names[i], name) == 0) return i;
	if(strcmp(name, "fDecay") == 0) return pfv_decay;
	if(strcmp(name, "nWaveMode") == 0) return pfv_wave_mode;
	if(strcmp(name, "fWaveScale") == 0) return pfv_wave_scale;
	if(strcmp(name, "bAdditiveWaves") == 0) return pfv_wave_additive;
	if(strcmp(name, "bWaveDots") == 0) return pfv_wave_usedots;
	if(strcmp(name, "bWaveThick") == 0) return pfv_wave_thick;
	if(strcmp(name, "fWaveAlpha") == 0) return pfv_wave_a;
	return -1;
}

static void load_defaults(struct eval_state *sc)
{
	int i;

	for(i=0;i<EVAL_PFV_COUNT;i++)
		sc->pfv_initial[i] = 0.0f;
	sc->pfv_initial[pfv_zoom] = 1.0f;
	sc->pfv_initial[pfv_decay] = 1.0f;
	sc->pfv_initial[pfv_wave_mode] = 1.0f;
	sc->pfv_initial[pfv_wave_scale] = 1.0f;
	sc->pfv_initial[pfv_wave_r] = 1.0f;
	sc->pfv_initial[pfv_wave_g] = 1.0f;
	sc->pfv_initial[pfv_wave_b] = 1.0f;
	sc->pfv_initial[pfv_wave_a] = 1.0f;
}

static void generate_initial(struct eval_state *sc, struct preset *ast)
{
	struct preset_line *line;

	load_defaults(sc);

	line = ast->lines;
	while(line != NULL) {
		if(!line->iseq) {
			int pfv;

			pfv = pfv_from_name(line->label);
			if(pfv >= 0)
				sc->pfv_initial[pfv] = line->contents.parameter;
		}
		line = line->next;
	}
}

void eval_reset_pfv(struct eval_state *sc)
{
	int i;
	for(i=0;i<PFPU_REG_COUNT;i++)
		sc->perframe_regs_current[i] = sc->perframe_regs_init[i];
}

static int generate_perframe(struct eval_state *sc, struct preset *ast)
{
	struct compiler_state compiler;
	struct compiler_initial initials[PFPU_REG_COUNT];
	int i;
	struct scheduler_state scheduler;
	struct preset_line *line;

	compiler_init(&compiler);

	/* Add equations from MilkDrop */
	line = ast->lines;
	while(line != NULL) {
		if(line->iseq && (strncmp(line->label, "per_frame_", 10) == 0)) {
			struct preset_equation *equation;

			equation = line->contents.equations;
			while(equation != NULL) {
				if(!compiler_compile_equation(&compiler, equation->target, equation->topnode)) return 0;
				equation = equation->next;
			}
		}
		line = line->next;
	}

	/* Generate initial register content */
	for(i=0;i<PFPU_REG_COUNT;i++)
		initials[i].name[0] = 0;
	for(i=0;i<EVAL_PFV_COUNT;i++) {
		strcpy(initials[i].name, pfv_names[i]);
		initials[i].x = sc->pfv_initial[i];
	}
	compiler_get_initial_regs(&compiler, initials, sc->perframe_regs_init);
	eval_reset_pfv(sc);

	/* Find out which variables we must read from the PFPU */
	for(i=0;i<EVAL_PFV_COUNT;i++) {
		int j;

		for(j=0;j<PFPU_REG_COUNT;j++)
			if(
				compiler.terminals[j].valid
				&& !compiler.terminals[j].isconst
				&& (strcmp(compiler.terminals[j].id.name, pfv_names[i]) == 0)
			) break;
		if(j < PFPU_REG_COUNT)
			sc->pfv_allocation[i] = j;
		else
			sc->pfv_allocation[i] = -1;
	}

	#ifdef EVAL_DEBUG
	printf("======== Per-frame virtual program ========\n");
	print_vprogram(&compiler);
	printf("======== Per-frame static register allocation ========\n");
	print_terminals(&compiler);
	printf("======== Per-frame variables from PFPU ========\n");
	for(i=0;i<EVAL_PFV_COUNT;i++)
		if(sc->pfv_allocation[i] != -1)
			printf("R%03d - %s\n", sc->pfv_allocation[i], pfv_names[i]);
	#endif

	/* Schedule instructions */
	scheduler_init(&scheduler);
	scheduler_dont_touch(&scheduler, compiler.terminals);
	scheduler_schedule(&scheduler, compiler.prog, compiler.prog_length);
	/* patch the program to make a dummy DMA at the end (otherwise PFPU never finishes) */
	scheduler.prog[scheduler.last_exit].i.opcode = PFPU_OPCODE_COPY;
	scheduler.last_exit += PFPU_LATENCY_COPY;
	if(scheduler.last_exit >= PFPU_PROGSIZE) return 0;
	scheduler.prog[scheduler.last_exit].i.dest = PFPU_REG_OUT;

	#ifdef EVAL_DEBUG
	printf("======== Per-frame HW program ========\n");
	print_program(&scheduler);
	#endif

	sc->perframe_prog_length = scheduler.last_exit+1;
	for(i=0;i<=scheduler.last_exit;i++)
		sc->perframe_prog[i].w = scheduler.prog[i].w;
	for(;i<PFPU_PROGSIZE;i++)
		sc->perframe_prog[i].w = 0;

	return 1;
}

static unsigned int dummy[2];

void eval_pfv_fill_td(struct eval_state *sc, struct pfpu_td *td, pfpu_callback callback, void *user)
{
	td->output = &dummy[0];
	td->hmeshlast = 0;
	td->vmeshlast = 0;
	td->program = sc->perframe_prog;
	td->progsize = sc->perframe_prog_length;
	td->registers = sc->perframe_regs_current;
	td->update = 1;
	td->invalidate = 0; /* < we don't care if our dummy variable has coherency problems */
	td->callback = callback;
	td->user = user;
}

float eval_read_pfv(struct eval_state *sc, int pfv)
{
	if(sc->pfv_allocation[pfv] < 0)
		return sc->pfv_initial[pfv];
	else
		return sc->perframe_regs_current[sc->pfv_allocation[pfv]];
}

void eval_write_pfv(struct eval_state *sc, int pfv, float x)
{
	if(sc->pfv_allocation[pfv] >= 0)
		sc->perframe_regs_current[sc->pfv_allocation[pfv]] = x;
}

/****************************************************************/
/* PER-VERTEX VARIABLES                                         */
/****************************************************************/

static int generate_pervertex(struct eval_state *sc, struct preset *ast)
{
	int i;
	struct scheduler_state scheduler;
	vpfpu_instruction vprog[PFPU_PROGSIZE];
	unsigned int vlen;
	
	sc->pvv_allocation[pvv_hmeshsize] = 3;
	sc->pvv_allocation[pvv_vmeshsize] = 4;
	sc->pvv_allocation[pvv_hres] = 5;
	sc->pvv_allocation[pvv_vres] = 6;
	sc->pvv_allocation[pvv_cx] = 7;
	sc->pvv_allocation[pvv_cy] = 8;
	sc->pvv_allocation[pvv_rot] = 9;
	sc->pvv_allocation[pvv_dx] = 10;
	sc->pvv_allocation[pvv_dy] = 11;
	sc->pvv_allocation[pvv_zoom] = 12;

	for(i=0;i<PFPU_REG_COUNT;i++)
		sc->pervertex_regs[i] = 0.0f;
	sc->pervertex_regs[3] = 1.0f/(float)sc->hmeshlast;
	sc->pervertex_regs[4] = 1.0f/(float)sc->vmeshlast;
	sc->pervertex_regs[5] = (float)sc->hres;
	sc->pervertex_regs[6] = (float)sc->vres;
	sc->pervertex_regs[13] = PFPU_TRIG_CONV;
	sc->pervertex_regs[14] = (1 << TMU_FIXEDPOINT_SHIFT);

	vlen = 0;
	
#define ADD_ISN(_opcode, _opa, _opb, _dest) do { \
		vprog[vlen].opcode = _opcode; \
		vprog[vlen].opa = _opa; \
		vprog[vlen].opb = _opb; \
		vprog[vlen].dest = _dest; \
		vlen++; \
	} while(0)
#define BR(x) (x)			/* bound register */
#define FR(x) (PFPU_REG_COUNT+(x))	/* free register */

	/* Compute current coordinates as floating point in range 0..1 */
	ADD_ISN(PFPU_OPCODE_I2F,	BR(  0), BR(  0), FR(  0)); /* FR00: current X index in float */
	ADD_ISN(PFPU_OPCODE_I2F,	BR(  1), BR(  0), FR(  1)); /* FR01: current Y index in float */
	ADD_ISN(PFPU_OPCODE_FMUL,	FR(  0), BR(  3), FR(  2)); /* FR02: current X coord (0..1) */
	ADD_ISN(PFPU_OPCODE_FMUL,	FR(  1), BR(  4), FR(  3)); /* FR03: current Y coord (0..1) */

	/* Zoom */
	ADD_ISN(PFPU_OPCODE_FSUB,	FR(  2), BR(  7), FR(  4)); /* FR04: x-cx */
	ADD_ISN(PFPU_OPCODE_FSUB,	FR(  3), BR(  8), FR(  5)); /* FR05: y-cy */
	ADD_ISN(PFPU_OPCODE_FMUL,	FR(  4), BR( 12), FR(  6)); /* FR06: zoom*(x-cx) */
	ADD_ISN(PFPU_OPCODE_FMUL,	FR(  5), BR( 12), FR(  7)); /* FR07: zoom*(y-cy) */
	ADD_ISN(PFPU_OPCODE_FADD,	FR(  6), BR(  7), FR(  8)); /* FR08: final zoomed X: zoom*(x-cx)+cx */
	ADD_ISN(PFPU_OPCODE_FADD,	FR(  7), BR(  8), FR(  9)); /* FR09: final zoomed Y: zoom*(y-cy)+cy */
	
	/* Rotation */
	ADD_ISN(PFPU_OPCODE_FMUL,	BR( 13), BR(  9), FR( 80)); /* FR80: rot*conv */
	ADD_ISN(PFPU_OPCODE_F2I,	FR( 80), BR(  0), FR( 81)); /* FR81: int(rot*conv) */
	ADD_ISN(PFPU_OPCODE_COS,	FR( 81), BR(  0), FR( 10)); /* FR10: cos(rot*conv) */
	ADD_ISN(PFPU_OPCODE_SIN,	FR( 81), BR(  0), FR( 11)); /* FR11: sin(rot*conv) */
	ADD_ISN(PFPU_OPCODE_FSUB,	FR(  8), BR(  7), FR( 12)); /* FR12: u=x-cx */
	ADD_ISN(PFPU_OPCODE_FSUB,	FR(  9), BR(  8), FR( 13)); /* FR13: v=y-cy */
	ADD_ISN(PFPU_OPCODE_FMUL,	FR( 12), FR( 10), FR( 14)); /* FR14: u*cos */
	ADD_ISN(PFPU_OPCODE_FMUL,	FR( 12), FR( 11), FR( 15)); /* FR15: u*sin */
	ADD_ISN(PFPU_OPCODE_FMUL,	FR( 13), FR( 10), FR( 16)); /* FR16: v*cos */
	ADD_ISN(PFPU_OPCODE_FMUL,	FR( 13), FR( 11), FR( 17)); /* FR17: v*sin */
	ADD_ISN(PFPU_OPCODE_FSUB,	FR( 14), FR( 17), FR( 18)); /* FR18: u*cos - v*sin */
	ADD_ISN(PFPU_OPCODE_FADD,	FR( 15), FR( 16), FR( 19)); /* FR19: u*sin + v*cos */
	ADD_ISN(PFPU_OPCODE_FADD,	FR( 18), BR(  7), FR( 30)); /* FR30: final rotated X: ...+cx */
	ADD_ISN(PFPU_OPCODE_FADD,	FR( 19), BR(  8), FR( 31)); /* FR31: final rotated Y: ...+cy */
	
	/* Displacement */
	ADD_ISN(PFPU_OPCODE_FADD,	FR( 30), BR( 10), FR( 20)); /* FR20: X */
	ADD_ISN(PFPU_OPCODE_FADD,	FR( 31), BR( 11), FR( 21)); /* FR21: Y */

	/* Multiply to support the TMU fixed point format */
	ADD_ISN(PFPU_OPCODE_FMUL,	FR( 20), BR( 14), FR( 25)); /* FR25: X*FP */
	ADD_ISN(PFPU_OPCODE_FMUL,	FR( 21), BR( 14), FR( 26)); /* FR26: Y*FP */

	/* Convert to screen coordinates and generate vertex */
	ADD_ISN(PFPU_OPCODE_FMUL,	FR( 25), BR(  5), FR( 22)); /* FR22: X screen float */
	ADD_ISN(PFPU_OPCODE_FMUL,	FR( 26), BR(  6), FR( 23)); /* FR23: Y screen float */
	ADD_ISN(PFPU_OPCODE_F2I,	FR( 22), BR(  0), FR( 24)); /* FR26: X screen integer */
	ADD_ISN(PFPU_OPCODE_F2I,	FR( 23), BR(  0), FR( 25)); /* FR27: Y screen integer */
	ADD_ISN(PFPU_OPCODE_VECT,	FR( 25), FR( 24), BR(127)); /* put out vector */

#undef BR
#undef FR
#undef ADD_ISN

	/* Schedule */
	scheduler_init(&scheduler);
	for(i=0;i<EVAL_PVV_COUNT;i++)
		scheduler.dont_touch[sc->pvv_allocation[i]] = 1;
	scheduler.dont_touch[13] = 1; /* PFPU_TRIG_CONV */
	scheduler.dont_touch[14] = 1; /* 1 << TMU_FIXEDPOINT_SHIFT */

	scheduler_schedule(&scheduler, vprog, vlen);

	#ifdef EVAL_DEBUG
	printf("======== Per-vertex HW program ========\n");
	print_program(&scheduler);
	#endif

	sc->pervertex_prog_length = scheduler.last_exit+1;
	for(i=0;i<=scheduler.last_exit;i++)
		sc->pervertex_prog[i].w = scheduler.prog[i].w;
	for(;i<PFPU_PROGSIZE;i++)
		sc->pervertex_prog[i].w = 0;

	return 1;
}

void eval_pfv_to_pvv(struct eval_state *sc)
{
	sc->pervertex_regs[sc->pvv_allocation[pvv_cx]] = eval_read_pfv(sc, pfv_cx);
	sc->pervertex_regs[sc->pvv_allocation[pvv_cy]] = eval_read_pfv(sc, pfv_cy);
	sc->pervertex_regs[sc->pvv_allocation[pvv_rot]] = -eval_read_pfv(sc, pfv_rot);
	sc->pervertex_regs[sc->pvv_allocation[pvv_dx]] = -eval_read_pfv(sc, pfv_dx);
	sc->pervertex_regs[sc->pvv_allocation[pvv_dy]] = -eval_read_pfv(sc, pfv_dy);
	sc->pervertex_regs[sc->pvv_allocation[pvv_zoom]] = 1.0/eval_read_pfv(sc, pfv_zoom);
}

void eval_pvv_fill_td(struct eval_state *sc, struct pfpu_td *td, struct tmu_vertex *vertices, pfpu_callback callback, void *user)
{
	td->output = (unsigned int *)vertices;
	td->hmeshlast = sc->hmeshlast;
	td->vmeshlast = sc->vmeshlast;
	td->program = sc->pervertex_prog;
	td->progsize = sc->pervertex_prog_length;
	td->registers = sc->pervertex_regs;
	td->update = 0; /* < no transfer of data in per-vertex equations between frames */
	td->invalidate = 1;
	td->callback = callback;
	td->user = user;
}

/****************************************************************/
/* GENERAL                                                      */
/****************************************************************/

void eval_init(struct eval_state *sc,
	unsigned int hmeshlast, unsigned int vmeshlast,
	unsigned int hres, unsigned int vres)
{
	sc->hmeshlast = hmeshlast;
	sc->vmeshlast = vmeshlast;
	sc->hres = hres;
	sc->vres = vres;
}

int eval_load_preset(struct eval_state *sc, struct preset *ast)
{
	generate_initial(sc, ast);
	if(!generate_perframe(sc, ast)) return 0;
	if(!generate_pervertex(sc, ast)) return 0;
	return 1;
}
