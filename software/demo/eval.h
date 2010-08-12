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

#ifndef __EVAL_H
#define __EVAL_H

#include <hw/tmu.h> /* for tmu_vertex */
#include <hw/pfpu.h>

#include <hal/pfpu.h>

/****************************************************************/
/* GENERAL                                                      */
/****************************************************************/

int eval_init();

/* generate all PFPU microcodes, must be called once before *_fill_td */
int eval_schedule();

/****************************************************************/
/* PER-FRAME VARIABLES                                          */
/****************************************************************/

enum {
	pfv_sx = 0,
	pfv_sy,
	pfv_cx,
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
	pfv_wave_brighten,
	pfv_wave_thick,
	pfv_wave_x,
	pfv_wave_y,
	pfv_wave_r,
	pfv_wave_g,
	pfv_wave_b,
	pfv_wave_a,

	pfv_ob_size,
	pfv_ob_r,
	pfv_ob_g,
	pfv_ob_b,
	pfv_ob_a,
	pfv_ib_size,
	pfv_ib_r,
	pfv_ib_g,
	pfv_ib_b,
	pfv_ib_a,

	pfv_mv_x,
	pfv_mv_y,
	pfv_mv_dx,
	pfv_mv_dy,
	pfv_mv_l,
	pfv_mv_r,
	pfv_mv_g,
	pfv_mv_b,
	pfv_mv_a,

	pfv_tex_wrap,

	pfv_time,
	pfv_bass,
	pfv_mid,
	pfv_treb,
	pfv_bass_att,
	pfv_mid_att,
	pfv_treb_att,

	pfv_warp,
	pfv_warp_anim_speed,
	pfv_warp_scale,

	pfv_q1,
	pfv_q2,
	pfv_q3,
	pfv_q4,
	pfv_q5,
	pfv_q6,
	pfv_q7,
	pfv_q8,

	pfv_video_echo_alpha,
	pfv_video_echo_zoom,
	pfv_video_echo_orientation,

	pfv_dmx1,
	pfv_dmx2,
	pfv_dmx3,
	pfv_dmx4,

	EVAL_PFV_COUNT /* must be last */
};

/* convert a variable name to its pfv_xxx number, -1 in case of failure */
int eval_pfv_from_name(const char *name);

/* set an initial value for a per frame variable or parameter */
void eval_set_initial(int pfv, float x);

/* restore a variable's initial condition */
int eval_reinit_pfv(int pfv);

/* restore all variable's initial conditions */
void eval_reinit_all_pfv();

/* reads the value of a per-frame variable
 * (from perframe_regs_current or initial conditions)
 * always returns a correct value; if the variable is not
 * in the patch, a default value is returned.
 */
float eval_read_pfv(int pfv);

/* writes the value of a per-frame variable (to perframe_regs_current)
 * does nothing if the variable is not handled by the PFPU.
 * typically used for patch inputs (treb, bass, etc.)
 */
void eval_write_pfv(int pfv, float x);

/* add a per frame equation in textual form */
int eval_add_per_frame(int linenr, char *dest, char *val);

/* fills in a task descriptor to evaluate per-frame equations */
void eval_pfv_fill_td(struct pfpu_td *td, pfpu_callback callback, void *user);


/****************************************************************/
/* PER-VERTEX VARIABLES                                         */
/****************************************************************/

enum {
	/* System */
	pvv_texsize,
	pvv_hmeshsize,
	pvv_vmeshsize,
	
	/* MilkDrop */
	pvv_sx,
	pvv_sy,
	pvv_cx,
	pvv_cy,
	pvv_rot,
	pvv_dx,
	pvv_dy,
	pvv_zoom,

	pvv_time,
	pvv_bass,
	pvv_mid,
	pvv_treb,
	pvv_bass_att,
	pvv_mid_att,
	pvv_treb_att,

	pvv_warp,
	pvv_warp_anim_speed,
	pvv_warp_scale,

	pvv_q1,
	pvv_q2,
	pvv_q3,
	pvv_q4,
	pvv_q5,
	pvv_q6,
	pvv_q7,
	pvv_q8,
	
	EVAL_PVV_COUNT /* must be last */
};

/* initialize per-vertex registers (some from the previously computed per-frame values) */
void eval_transfer_pvv_regs();

/* add a per vertex equation in textual form */
int eval_add_per_vertex(int linenr, char *dest, char *val);

/* fills in a task descriptor to evaluate per-vertex equations */
void eval_pvv_fill_td(struct pfpu_td *td, struct tmu_vertex *vertices, pfpu_callback callback, void *user);

#endif /* __EVAL_H */
