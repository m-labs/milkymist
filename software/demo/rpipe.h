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

#ifndef __RPIPE_H
#define __RPIPE_H

#include <hal/tmu.h>

struct rpipe_frame;

typedef void (*rpipe_callback)(struct rpipe_frame *frame);

/* Align this structure to a 64-bit boundary so that HW is able to read/write vertices correctly */
struct rpipe_frame {
	struct tmu_vertex vertices[TMU_MESH_MAXSIZE][TMU_MESH_MAXSIZE];
	unsigned int brightness;
	unsigned int wave_mode;
	float wave_scale;
	int wave_additive;
	int wave_usedots;
	int wave_brighten;
	int wave_thick;
	float wave_x, wave_y;
	float wave_r, wave_g, wave_b, wave_a;
	float ob_size;
	float ob_r, ob_g, ob_b, ob_a;
	float ib_size;
	float ib_r, ib_g, ib_b, ib_a;
	float mv_x, mv_y;
	float mv_dx, mv_dy;
	float mv_l;
	float mv_r, mv_g, mv_b, mv_a;
	int tex_wrap;
	float vecho_alpha;
	float vecho_zoom;
	int vecho_orientation;
	float treb;
	float time;
	unsigned int nsamples; /* < audio samples */
	short *samples;
	rpipe_callback callback;
	void *user; /* < for application use */
};

extern int spam_enabled;

void rpipe_init();
int rpipe_input(struct rpipe_frame *frame);
void rpipe_service();

void rpipe_tick();
int rpipe_fps();

#endif /* __RPIPE_H */
