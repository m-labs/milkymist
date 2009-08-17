/*
 * MTK - the Milkymist Toolkit
 * Copyright (C) 2008, 2009 Sebastien Bourdeauducq
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

#ifndef __COLOR_H
#define __COLOR_H

#define RGB565

#ifdef WEBPALETTE

typedef unsigned char color;

typedef struct {
	color color;
	unsigned char alpha;
} color_alpha;

#define DEFAULT_COLOR 0x00

#endif


#ifdef RGB565

typedef short unsigned int color;

typedef struct {
	color c;
	unsigned char alpha;
} color_alpha;

#define MAKERGB565(r, g, b) ((((r) & 0xf8) << 8) | (((g) & 0xfc) << 3) | (((b) & 0xf8) >> 3))

#define MAKERGB565NN(r, g, b) ((((r) & 0x1f) << 11) | (((g) & 0x3f) << 5) | ((b) & 0x1f))

#define GETR(c) (((c) & 0xf800) >> 11)
#define GETG(c) (((c) & 0x07e0) >> 5)
#define GETB(c) ((c) & 0x001f)

#define COLOR_BLEND(c1, c2, i, max) MAKERGB565NN(((((max)-(i))*GETR(c1)+(i)*GETR(c2))/(max)), ((((max)-(i))*GETG(c1)+(i)*GETG(c2))/(max)), ((((max)-(i))*GETB(c1)+(i)*GETB(c2))/(max)))

#define DEFAULT_COLOR 0x0000

#endif


#ifdef RGBA8888

typedef unsigned int color;

typedef unsigned int color_alpha;

#define DEFAULT_COLOR 0x00000000

#endif

#endif /* __COLOR_H */
