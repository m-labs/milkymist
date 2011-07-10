/*
 * Milkymist SoC (Software)
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

#ifndef __WAVE_H
#define __WAVE_H

struct wave_vertex {
	int x;
	int y;
};

struct wave_params {
	unsigned int wave_mode;
	int wave_additive;
	int wave_dots;
	int wave_brighten;
	int wave_thick;
	float wave_r;
	float wave_g;
	float wave_b;
	float wave_a;
	float treb;
};

void wave_draw(unsigned short *framebuffer, unsigned int hres, unsigned int vres,
	struct wave_params *params,
	struct wave_vertex *vertices, unsigned int nvertices);

#endif /* __WAVE_H */
