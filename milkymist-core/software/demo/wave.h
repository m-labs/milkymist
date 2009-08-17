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

#ifndef __WAVE_H
#define __WAVE_H

struct wave_vertex {
	unsigned int x;
	unsigned int y;
};

struct wave_params {
	unsigned int wave_mode;
	float wave_r;
	float wave_g;
	float wave_b;
	float wave_alpha;
	int maximize_wave_color;
	int wave_dots;
	int wave_thick;
	int additive_waves;
	int wave_loop;
	float treb;
};

void wave_draw(unsigned short *framebuffer, unsigned int hres, unsigned int vres,
	struct wave_params *params,
	struct wave_vertex *vertices, unsigned int nvertices);

#endif /* __WAVE_H */
