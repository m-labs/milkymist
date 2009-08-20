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

#ifndef __RPIPE_H
#define __RPIPE_H

#include "tmu.h"

struct rpipe_frame;

typedef void (*rpipe_callback)(struct rpipe_frame *frame);

struct rpipe_frame {
	struct tmu_vertex vertices[TMU_MESH_MAXSIZE][TMU_MESH_MAXSIZE];
	unsigned int brightness;
	unsigned int wave_mode;
	float wave_scale;
	int wave_additive;
	int wave_usedots;
	int wave_maximize_color;
	int wave_thick;
	float wave_x, wave_y;
	float wave_r, wave_b, wave_g, wave_a;
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
