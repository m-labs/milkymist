/*
 * Milkymist VJ SoC (Software)
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

#ifndef __EVAL_H
#define __EVAL_H

#include <hw/pfpu.h>
#include <hw/tmu.h>

#include "pfpu.h"
#include "ast.h"

/****************************************************************/
/* PER-FRAME VARIABLES                                          */
/****************************************************************/

enum {
	pfv_cx = 0,
	pfv_cy,
	pfv_rot,
	pfv_dx,
	pfv_dy,
	pfv_zoom,
	pfv_decay,
	pfv_wave_mode,
	pfv_wave_scale,
	pfv_wave_additive,
	pfv_wave_usedots,
	pfv_wave_maximize_color,
	pfv_wave_thick,
	pfv_wave_x,
	pfv_wave_y,
	pfv_wave_r,
	pfv_wave_g,
	pfv_wave_b,
	pfv_wave_a,

	pfv_time,
	pfv_bass,
	pfv_mid,
	pfv_treb,
	pfv_bass_att,
	pfv_mid_att,
	pfv_treb_att,
	
	EVAL_PFV_COUNT /* must be last */
};

struct eval_state;

/* fills in a task descriptor to evaluate per-frame equations */
void eval_pfv_fill_td(struct eval_state *sc, struct pfpu_td *td, pfpu_callback callback, void *user);

/* restores preset's initial conditions */
void eval_reset_pfv(struct eval_state *sc);

/* reads the value of a per-frame variable
 * (from perframe_regs_current or initial conditions)
 * always returns a correct value; if the variable is not
 * in the preset, a default value is returned.
 */
float eval_read_pfv(struct eval_state *sc, int pfv);

/* writes the value of a per-frame variable (to perframe_regs_current)
 * does nothing if the variable is not handled by the PFPU.
 * typically used for preset inputs (treb, bass, etc.)
 */
void eval_write_pfv(struct eval_state *sc, int pfv, float x);

/****************************************************************/
/* PER-VERTEX VARIABLES                                         */
/****************************************************************/

/* TODO: use texsize */

enum {
	/* System */
	pvv_hmeshsize = 0,
	pvv_vmeshsize,
	pvv_hres,
	pvv_vres,

	/* MilkDrop */
	pvv_cx,
	pvv_cy,
	pvv_rot,
	pvv_dx,
	pvv_dy,
	pvv_zoom,
	
	EVAL_PVV_COUNT /* must be last */
};

/* transfer relevant per-frame variables to the per-vertex variable pool */
void eval_pfv_to_pvv(struct eval_state *sc);

/* fills in a task descriptor to evaluate per-vertex equations */
void eval_pvv_fill_td(struct eval_state *sc, struct pfpu_td *td, struct tmu_vertex *vertices, pfpu_callback callback, void *user);

/****************************************************************/
/* GENERAL                                                      */
/****************************************************************/

struct eval_state {
	float pfv_initial[EVAL_PFV_COUNT];		/* < preset initial conditions */
	int pfv_allocation[EVAL_PFV_COUNT];		/* < where per-frame variables are mapped in PFPU regf, -1 if unmapped */
	int perframe_prog_length;			/* < how many instructions in perframe_prog */
	pfpu_instruction perframe_prog[PFPU_PROGSIZE];	/* < PFPU per-frame microcode */
	float perframe_regs_init[PFPU_REG_COUNT];	/* < PFPU regf according to initial conditions and constants */
	float perframe_regs_current[PFPU_REG_COUNT];	/* < PFPU regf local copy (keeps data when PFPU is reloaded) */

	int pvv_allocation[EVAL_PVV_COUNT];		/* < where per-vertex variables are mapped in PFPU regf, -1 if unmapped */
	int pervertex_prog_length;			/* < how many instructions in pervertex_prog */
	pfpu_instruction pervertex_prog[PFPU_PROGSIZE];	/* < PFPU per-vertex microcode */
	float pervertex_regs[PFPU_REG_COUNT];		/* < PFPU regf according to per-frame variables, initial conditions and constants */
	int hmeshlast;					/* < index of last mesh point, X direction */
	int vmeshlast;					/* < index of last mesh point, Y direction */
	int hres;					/* < horizontal screen resolution */
	int vres;					/* < vertical screen resolution */
};

void eval_init(struct eval_state *sc,
	unsigned int hmeshlast, unsigned int vmeshlast,
	unsigned int hres, unsigned int vres);
int eval_load_preset(struct eval_state *sc, struct preset *ast);

#endif /* __EVAL_H */
