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
#include <fpvm/gfpus.h>
#include <fpvm/pfpu.h>

#include "eval.h"
#include "renderer.h"

//#define EVAL_DEBUG

/****************************************************************/
/* GENERAL                                                      */
/****************************************************************/

static void load_defaults();
static int init_pfv();
static int finalize_pfv();
static int schedule_pfv();
static int init_pvv();
static int finalize_pvv();
static int schedule_pvv();

int eval_init()
{
	load_defaults();
	if(!init_pfv()) return 0;
	if(!init_pvv()) return 0;
	return 1;
}

int eval_schedule()
{
	if(!finalize_pfv()) return 0;
	if(!schedule_pfv()) return 0;
	
	if(!finalize_pvv()) return 0;
	if(!schedule_pvv()) return 0;
	
	return 1;
}

/****************************************************************/
/* PER-FRAME VARIABLES                                          */
/****************************************************************/

static struct fpvm_fragment pfv_fragment;
static float pfv_initial[EVAL_PFV_COUNT];		/* < preset initial conditions */
static int pfv_preallocation[EVAL_PFV_COUNT];		/* < where per-frame variables can be mapped in PFPU regf */
static int pfv_allocation[EVAL_PFV_COUNT];		/* < where per-frame variables are mapped in PFPU regf, -1 if unmapped */
static int perframe_prog_length;			/* < how many instructions in perframe_prog */
static unsigned int perframe_prog[PFPU_PROGSIZE];	/* < PFPU per-frame microcode */
static float perframe_regs[PFPU_REG_COUNT];		/* < PFPU regf local copy */

static const char pfv_names[EVAL_PFV_COUNT][FPVM_MAXSYMLEN] = {
	"sx",
	"sy",
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
	"wave_brighten",
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
	"treb_att",

	"warp",
	"fWarpAnimSpeed",
	"fWarpScale",

	"q1",
	"q2",
	"q3",
	"q4",
	"q5",
	"q6",
	"q7",
	"q8"
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
	if(strcmp(name, "bMaximizeWaveColor") == 0) return pfv_wave_brighten;
	if(strcmp(name, "bWaveThick") == 0) return pfv_wave_thick;
	if(strcmp(name, "fWaveAlpha") == 0) return pfv_wave_a;
	return -1;
}

static void load_defaults()
{
	int i;

	for(i=0;i<EVAL_PFV_COUNT;i++)
		pfv_initial[i] = 0.0;
	pfv_initial[pfv_sx] = 1.0;
	pfv_initial[pfv_sy] = 1.0;
	pfv_initial[pfv_cx] = 0.5;
	pfv_initial[pfv_cy] = 0.5;
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

	pfv_initial[pfv_warp_scale] = 1.0;
}

void eval_set_initial(int pfv, float x)
{
	pfv_initial[pfv] = x;
}

int eval_reinit_pfv(int pfv)
{
	int r;

	r = pfv_allocation[pfv];
	if(r < 0) return 0;
	perframe_regs[r] = pfv_initial[pfv];
	return 1;
}

void eval_reinit_all_pfv()
{
	int i;
	for(i=0;i<EVAL_PFV_COUNT;i++)
		eval_reinit_pfv(i);
}

float eval_read_pfv(int pfv)
{
	if(pfv_allocation[pfv] < 0)
		return pfv_initial[pfv];
	else
		return perframe_regs[pfv_allocation[pfv]];
}

void eval_write_pfv(int pfv, float x)
{
	if(pfv_allocation[pfv] >= 0)
		perframe_regs[pfv_allocation[pfv]] = x;
}

static int init_pfv()
{
	int i;
	
	fpvm_init(&pfv_fragment, 0);
	pfv_fragment.bind_mode = 1; /* < keep user-defined variables from frame to frame */
	for(i=0;i<EVAL_PFV_COUNT;i++) {
		pfv_preallocation[i] = fpvm_bind(&pfv_fragment, pfv_names[i]);
		if(pfv_preallocation[i] == FPVM_INVALID_REG) {
			printf("EVL: failed to bind per-frame variable %s: %s\n", pfv_names[i], pfv_fragment.last_error);
			return 0;
		}
	}
	return 1;
}

static int finalize_pfv()
{
	int i;
	int references[FPVM_MAXBINDINGS];

	/* assign dummy values for output */
	if(!fpvm_assign(&pfv_fragment, "_Xo", "_Xi")) goto fail_fpvm;
	if(!fpvm_assign(&pfv_fragment, "_Yo", "_Yi")) goto fail_fpvm;
	if(!fpvm_finalize(&pfv_fragment)) goto fail_fpvm;
	#ifdef EVAL_DEBUG
	printf("EVL: per-frame FPVM fragment:\n");
	fpvm_dump(&pfv_fragment);
	#endif

	/* Build variable allocation table */
	fpvm_get_references(&pfv_fragment, references);
	for(i=0;i<EVAL_PFV_COUNT;i++)
		if(references[pfv_preallocation[i]])
			pfv_allocation[i] = pfv_preallocation[i];
		else
			pfv_allocation[i] = -1;
	
	return 1;
fail_fpvm:
	printf("EVL: failed to finalize per-frame variables: %s\n", pfv_fragment.last_error);
	return 0;
}

static int schedule_pfv()
{
	perframe_prog_length = gfpus_schedule(&pfv_fragment, (unsigned int *)perframe_prog, (unsigned int *)perframe_regs);
	eval_reinit_all_pfv();
	if(perframe_prog_length < 0) {
		printf("EVL: per-frame VLIW scheduling failed\n");
		return 0;
	}
	#ifdef EVAL_DEBUG
	printf("EVL: per-frame PFPU fragment:\n");
	pfpu_dump(perframe_prog, perframe_prog_length);
	#endif
	
	return 1;
}

int eval_add_per_frame(int linenr, char *dest, char *val)
{
	if(!fpvm_assign(&pfv_fragment, dest, val)) {
		printf("EVL: failed to add per-frame equation l. %d: %s\n", linenr, pfv_fragment.last_error);
		return 0;
	}
	return 1;
}

static unsigned int dummy[2];

void eval_pfv_fill_td(struct pfpu_td *td, pfpu_callback callback, void *user)
{
	td->output = &dummy[0];
	td->hmeshlast = 0;
	td->vmeshlast = 0;
	td->program = (pfpu_instruction *)perframe_prog;
	td->progsize = perframe_prog_length;
	td->registers = perframe_regs;
	td->update = 1;
	td->invalidate = 0; /* < we don't care if our dummy variable has coherency problems */
	td->callback = callback;
	td->user = user;
}

/****************************************************************/
/* PER-VERTEX VARIABLES                                         */
/****************************************************************/

static struct fpvm_fragment pvv_fragment;
static int pvv_preallocation[EVAL_PVV_COUNT];		/* < where per-vertex variables can be mapped in PFPU regf */
static int pvv_allocation[EVAL_PVV_COUNT];		/* < where per-vertex variables are mapped in PFPU regf, -1 if unmapped */
static int pervertex_prog_length;			/* < how many instructions in pervertex_prog */
static unsigned int pervertex_prog[PFPU_PROGSIZE];	/* < PFPU per-vertex microcode */
static float pervertex_regs[PFPU_REG_COUNT];		/* < PFPU regf according to per-frame variables, initial conditions and constants */

static const char pvv_names[EVAL_PVV_COUNT][FPVM_MAXSYMLEN] = {
	/* System */
	"_texsize",
	"_hmeshsize",
	"_vmeshsize",

	/* MilkDrop */
	"sx",
	"sy",
	"cx",
	"cy",
	"rot",
	"dx",
	"dy",
	"zoom",

	"time",
	"bass",
	"mid",
	"treb",
	"bass_att",
	"mid_att",
	"treb_att",

	"warp",
	"fWarpAnimSpeed",
	"fWarpScale",

	"q1",
	"q2",
	"q3",
	"q4",
	"q5",
	"q6",
	"q7",
	"q8"
};

static void write_pvv(int pvv, float x)
{
	if(pvv_allocation[pvv] >= 0)
		pervertex_regs[pvv_allocation[pvv]] = x;
}


void eval_transfer_pvv_regs()
{
	write_pvv(pvv_texsize, renderer_texsize << TMU_FIXEDPOINT_SHIFT);
	write_pvv(pvv_hmeshsize, 1.0/(float)renderer_hmeshlast);
	write_pvv(pvv_vmeshsize, 1.0/(float)renderer_vmeshlast);

	write_pvv(pvv_sx, eval_read_pfv(pfv_sx));
	write_pvv(pvv_sy, eval_read_pfv(pfv_sy));
	write_pvv(pvv_cx, eval_read_pfv(pfv_cx));
	write_pvv(pvv_cy, eval_read_pfv(pfv_cy));
	write_pvv(pvv_rot, eval_read_pfv(pfv_rot));
	write_pvv(pvv_dx, eval_read_pfv(pfv_dx));
	write_pvv(pvv_dy, eval_read_pfv(pfv_dy));
	write_pvv(pvv_zoom, eval_read_pfv(pfv_zoom));
	
	write_pvv(pvv_time, eval_read_pfv(pfv_time));
	write_pvv(pvv_bass, eval_read_pfv(pfv_bass));
	write_pvv(pvv_mid, eval_read_pfv(pfv_mid));
	write_pvv(pvv_treb, eval_read_pfv(pfv_treb));
	write_pvv(pvv_bass_att, eval_read_pfv(pfv_bass_att));
	write_pvv(pvv_mid_att, eval_read_pfv(pfv_mid_att));
	write_pvv(pvv_treb_att, eval_read_pfv(pfv_treb_att));

	write_pvv(pvv_warp, eval_read_pfv(pfv_warp));
	write_pvv(pvv_warp_anim_speed, eval_read_pfv(pfv_warp_anim_speed));
	write_pvv(pvv_warp_scale, eval_read_pfv(pfv_warp_scale));
}

static int init_pvv()
{
	int i;
	
	fpvm_init(&pvv_fragment, 1);
	
	for(i=0;i<EVAL_PVV_COUNT;i++) {
		pvv_preallocation[i] = fpvm_bind(&pvv_fragment, pvv_names[i]);
		if(pvv_preallocation[i] == FPVM_INVALID_REG) {
			printf("EVL: failed to bind per-vertex variable %s: %s\n", pvv_names[i], pvv_fragment.last_error);
			return 0;
		}
	}

	#define A(dest, val) if(!fpvm_assign(&pvv_fragment, dest, val)) goto fail_assign
	A("x", "i2f(_Xi)*_hmeshsize");
	A("y", "i2f(_Yi)*_vmeshsize");
	A("rad", "sqrt(sqr(x-0.5)+sqr(y-0.5))");
	/* TODO: generate ang */
	#undef A
	
	return 1;

fail_assign:
	printf("EVL: failed to add equation to per-vertex header: %s\n", pvv_fragment.last_error);
	return 0;
}

static int finalize_pvv()
{
	int i;
	int references[FPVM_MAXBINDINGS];

	#define A(dest, val) if(!fpvm_assign(&pvv_fragment, dest, val)) goto fail_assign

	/* Zoom */
	A("_invzoom", "1/zoom");
	A("_xz", "_invzoom*(x-0.5)+0.5");
	A("_yz", "_invzoom*(y-0.5)+0.5");

	/* Scale */
	A("_xs", "(_xz-cx)/sx+cx");
	A("_ys", "(_yz-cy)/sy+cy");

	/* Warp */
	A("_warptime", "time*fWarpAnimSpeed");
	A("_invwarpscale", "1/fWarpScale");
	A("_f0", "11.68 + 4.0*cos(_warptime*1.413 + 10)");
	A("_f1", "8.77 + 3.0*cos(_warptime*1.113 + 7)");
	A("_f2", "10.54 + 3.0*cos(_warptime*1.233 + 3)");
	A("_f3", "11.49 + 4.0*cos(_warptime*0.933 + 5)");
	A("_ox2", "2*x-1");
	A("_oy2", "2*y-1");
	A("_xw", "_xs+warp*0.0035*("
		"sin(_warptime*0.333+_invwarpscale*(_ox2*_f0-_oy2*_f3))"
		"+cos(_warptime*0.753-_invwarpscale*(_ox2*_f1-_oy2*_f2)))");
	A("_yw", "_ys+warp*0.0035*("
		"cos(_warptime*0.375-_invwarpscale*(_ox2*_f2+_oy2*_f1))"
		"+sin(_warptime*0.825+_invwarpscale*(_ox2*_f0+_oy2*_f3)))");

	/* Rotate */
	A("_cosr", "cos(rot)");
	A("_sinr", "sin(0-rot)");
	A("_u", "_xw-cx");
	A("_v", "_yw-cy");
	A("_xr", "_u*_cosr-_v*_sinr+cx");
	A("_yr", "_u*_sinr+_v*_cosr+cy");

	/* Translate */
	A("_xd", "_xr-dx");
	A("_yd", "_yr-dy");

	/* Convert to framebuffer coordinates */
	A("_Xo", "f2i(_xd*_texsize)");
	A("_Yo", "f2i(_yd*_texsize)");

	#undef A
	
	if(!fpvm_finalize(&pvv_fragment)) goto fail_finalize;
	#ifdef EVAL_DEBUG
	printf("EVL: per-vertex FPVM fragment:\n");
	fpvm_dump(&pvv_fragment);
	#endif

	/* Build variable allocation table */
	fpvm_get_references(&pvv_fragment, references);
	for(i=0;i<EVAL_PVV_COUNT;i++)
		if(references[pvv_preallocation[i]])
			pvv_allocation[i] = pvv_preallocation[i];
		else
			pvv_allocation[i] = -1;

	
	return 1;
fail_assign:
	printf("EVL: failed to add equation to per-vertex footer: %s\n", pvv_fragment.last_error);
	return 0;
fail_finalize:
	printf("EVL: failed to finalize per-vertex variables: %s\n", pvv_fragment.last_error);
	return 0;
}

static int schedule_pvv()
{
	pervertex_prog_length = gfpus_schedule(&pvv_fragment, (unsigned int *)pervertex_prog, (unsigned int *)pervertex_regs);
	if(pervertex_prog_length < 0) {
		printf("EVL: per-vertex VLIW scheduling failed\n");
		return 0;
	}
	#ifdef EVAL_DEBUG
	printf("EVL: per-vertex PFPU fragment:\n");
	pfpu_dump(pervertex_prog, pervertex_prog_length);
	#endif

	return 1;
}

int eval_add_per_vertex(int linenr, char *dest, char *val)
{
	if(!fpvm_assign(&pvv_fragment, dest, val)) {
		printf("EVL: failed to add per-vertex equation l. %d: %s\n", linenr, pvv_fragment.last_error);
		return 0;
	}
	return 1;
}

void eval_pvv_fill_td(struct pfpu_td *td, struct tmu_vertex *vertices, pfpu_callback callback, void *user)
{
	td->output = (unsigned int *)vertices;
	td->hmeshlast = renderer_hmeshlast;
	td->vmeshlast = renderer_vmeshlast;
	td->program = (pfpu_instruction *)pervertex_prog;
	td->progsize = pervertex_prog_length;
	td->registers = pervertex_regs;
	td->update = 0; /* < no transfer of data in per-vertex equations between frames */
	td->invalidate = 1;
	td->callback = callback;
	td->user = user;
}
