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
#include <fpvm/fpvm.h>

#include "eval.h"
#include "renderer.h"

//#define EVAL_DEBUG

/****************************************************************/
/* GENERAL                                                      */
/****************************************************************/

static float pfv_initial[EVAL_PFV_COUNT];		/* < preset initial conditions */
static int pfv_allocation[EVAL_PFV_COUNT];		/* < where per-frame variables are mapped in PFPU regf, -1 if unmapped */
static int perframe_prog_length;			/* < how many instructions in perframe_prog */
static pfpu_instruction perframe_prog[PFPU_PROGSIZE];	/* < PFPU per-frame microcode */
static float perframe_regs_init[PFPU_REG_COUNT];	/* < PFPU regf according to initial conditions and constants */
static float perframe_regs_current[PFPU_REG_COUNT];	/* < PFPU regf local copy (keeps data when PFPU is reloaded) */

static int pvv_allocation[EVAL_PVV_COUNT];		/* < where per-vertex variables are mapped in PFPU regf, -1 if unmapped */
static int pervertex_prog_length;			/* < how many instructions in pervertex_prog */
static pfpu_instruction pervertex_prog[PFPU_PROGSIZE];	/* < PFPU per-vertex microcode */
static float pervertex_regs[PFPU_REG_COUNT];		/* < PFPU regf according to per-frame variables, initial conditions and constants */

static void eval_load_defaults();

void eval_init()
{
	eval_load_defaults();
}

int eval_schedule()
{
	return 1;
}

/****************************************************************/
/* PER-FRAME VARIABLES                                          */
/****************************************************************/

static const char pfv_names[EVAL_PFV_COUNT][FPVM_MAXSYMLEN] = {
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
	
	"ob_size",
	"ob_r",
	"ob_g",
	"ob_b",
	"ob_a",
	"ib_size",
	"ib_r",
	"ib_g",
	"ib_b",
	"ib_a",

	"nMotionVectorsX",
	"nMotionVectorsY",
	"mv_dx",
	"mv_dy",
	"mv_l",
	"mv_r",
	"mv_g",
	"mv_b",
	"mv_a",
	
	"bTexWrap",

	"time",
	"bass",
	"mid",
	"treb",
	"bass_att",
	"mid_att",
	"treb_att"
};

int eval_pfv_from_name(const char *name)
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

static void eval_load_defaults()
{
	int i;

	for(i=0;i<EVAL_PFV_COUNT;i++)
		pfv_initial[i] = 0.0;
	pfv_initial[pfv_zoom] = 1.0;
	pfv_initial[pfv_decay] = 1.0;
	pfv_initial[pfv_wave_mode] = 1.0;
	pfv_initial[pfv_wave_scale] = 1.0;
	pfv_initial[pfv_wave_r] = 1.0;
	pfv_initial[pfv_wave_g] = 1.0;
	pfv_initial[pfv_wave_b] = 1.0;
	pfv_initial[pfv_wave_a] = 1.0;

	pfv_initial[pfv_mv_x] = 16.0;
	pfv_initial[pfv_mv_y] = 12.0;
	pfv_initial[pfv_mv_dx] = 0.02;
	pfv_initial[pfv_mv_dy] = 0.02;
	pfv_initial[pfv_mv_l] = 1.0;
}

void eval_set_initial(int pfv, float x)
{
	pfv_initial[pfv] = x;
}

void eval_reset_pfv()
{
	int i;
	for(i=0;i<PFPU_REG_COUNT;i++)
		perframe_regs_current[i] = perframe_regs_init[i];
}

int eval_reinit_pfv(int pfv)
{
	int r;

	r = pfv_allocation[pfv];
	if(r < 0) return 0;
	perframe_regs_current[r] = perframe_regs_init[r];
	return 1;
}

void eval_reinit_all_pfv()
{
	eval_reinit_pfv(pfv_cx);
	eval_reinit_pfv(pfv_cy);
	eval_reinit_pfv(pfv_rot);
	eval_reinit_pfv(pfv_dx);
	eval_reinit_pfv(pfv_dy);
	eval_reinit_pfv(pfv_zoom);
	eval_reinit_pfv(pfv_decay);
	
	eval_reinit_pfv(pfv_wave_mode);
	eval_reinit_pfv(pfv_wave_scale);
	eval_reinit_pfv(pfv_wave_additive);
	eval_reinit_pfv(pfv_wave_usedots);
	eval_reinit_pfv(pfv_wave_maximize_color);
	eval_reinit_pfv(pfv_wave_thick);
	
	eval_reinit_pfv(pfv_wave_x);
	eval_reinit_pfv(pfv_wave_y);
	eval_reinit_pfv(pfv_wave_r);
	eval_reinit_pfv(pfv_wave_g);
	eval_reinit_pfv(pfv_wave_b);
	eval_reinit_pfv(pfv_wave_a);

	eval_reinit_pfv(pfv_ob_size);
	eval_reinit_pfv(pfv_ob_r);
	eval_reinit_pfv(pfv_ob_g);
	eval_reinit_pfv(pfv_ob_b);
	eval_reinit_pfv(pfv_ob_a);

	eval_reinit_pfv(pfv_ib_size);
	eval_reinit_pfv(pfv_ib_r);
	eval_reinit_pfv(pfv_ib_g);
	eval_reinit_pfv(pfv_ib_b);
	eval_reinit_pfv(pfv_ib_a);

	eval_reinit_pfv(pfv_mv_x);
	eval_reinit_pfv(pfv_mv_y);
	eval_reinit_pfv(pfv_mv_dx);
	eval_reinit_pfv(pfv_mv_dy);
	eval_reinit_pfv(pfv_mv_l);
	eval_reinit_pfv(pfv_mv_r);
	eval_reinit_pfv(pfv_mv_g);
	eval_reinit_pfv(pfv_mv_b);
	eval_reinit_pfv(pfv_mv_a);
	
	eval_reinit_pfv(pfv_tex_wrap);
}

float eval_read_pfv(int pfv)
{
	if(pfv_allocation[pfv] < 0)
		return pfv_initial[pfv];
	else
		return perframe_regs_current[pfv_allocation[pfv]];
}

void eval_write_pfv(int pfv, float x)
{
	if(pfv_allocation[pfv] >= 0)
		perframe_regs_current[pfv_allocation[pfv]] = x;
}

int eval_add_per_frame(char *dest, char *val)
{
	return 1;
}

static unsigned int dummy[2];

void eval_pfv_fill_td(struct pfpu_td *td, pfpu_callback callback, void *user)
{
	td->output = &dummy[0];
	td->hmeshlast = 0;
	td->vmeshlast = 0;
	td->program = perframe_prog;
	td->progsize = perframe_prog_length;
	td->registers = perframe_regs_current;
	td->update = 1;
	td->invalidate = 0; /* < we don't care if our dummy variable has coherency problems */
	td->callback = callback;
	td->user = user;
}

/****************************************************************/
/* PER-VERTEX VARIABLES                                         */
/****************************************************************/

void eval_pfv_to_pvv()
{
	pervertex_regs[pvv_allocation[pvv_cx]] = eval_read_pfv(pfv_cx);
	pervertex_regs[pvv_allocation[pvv_cy]] = eval_read_pfv(pfv_cy);
	pervertex_regs[pvv_allocation[pvv_rot]] = -eval_read_pfv(pfv_rot);
	pervertex_regs[pvv_allocation[pvv_dx]] = -eval_read_pfv(pfv_dx);
	pervertex_regs[pvv_allocation[pvv_dy]] = -eval_read_pfv(pfv_dy);
	pervertex_regs[pvv_allocation[pvv_zoom]] = 1.0/eval_read_pfv(pfv_zoom);
}

int eval_add_per_vertex(char *dest, char *val)
{
	return 1;
}

void eval_pvv_fill_td(struct pfpu_td *td, struct tmu_vertex *vertices, pfpu_callback callback, void *user)
{
	td->output = (unsigned int *)vertices;
	td->hmeshlast = renderer_hmeshlast;
	td->vmeshlast = renderer_hmeshlast;
	td->program = pervertex_prog;
	td->progsize = pervertex_prog_length;
	td->registers = pervertex_regs;
	td->update = 0; /* < no transfer of data in per-vertex equations between frames */
	td->invalidate = 1;
	td->callback = callback;
	td->user = user;
}
