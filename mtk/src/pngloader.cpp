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

#include <string>
#include <cstdio>
#include <cstdlib>

#include <png.h>

#include "color.h"
#include "region.h"
#include "pngloader.h"

using namespace std;

CPNGLoader::CPNGLoader(string filename)
{
	FILE *fd;
	png_byte header[8];
	png_structp png_ptr;
	png_infop info_ptr;
	png_bytep *row_pointers;
	int x, y;
	
	m_Image = NULL;
	
	fd = fopen(filename.c_str(), "rb");
	if(!fd) return;
	fread(header, 1, 8, fd);
	if(png_sig_cmp(header, 0, 8)) {
		fclose(fd);
		return;
	}
	png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
	if(!png_ptr) {
		fclose(fd);
		return;
	}
	info_ptr = png_create_info_struct(png_ptr);
	if(!info_ptr) {
		png_destroy_read_struct(&png_ptr, NULL, NULL);
		fclose(fd);
		return;
	}
	if(setjmp(png_jmpbuf(png_ptr))) {
		png_destroy_read_struct(&png_ptr, NULL, NULL);
		fclose(fd);
		return;
	}
	png_init_io(png_ptr, fd);
	png_set_sig_bytes(png_ptr, 8);
	png_read_info(png_ptr, info_ptr);
	png_get_IHDR(png_ptr, info_ptr, (png_uint_32 *)&m_W, (png_uint_32 *)&m_H, &m_BitDepth, &m_ColorType, NULL, NULL, NULL);
	png_set_add_alpha(png_ptr, 0, PNG_FILLER_AFTER);
	
	row_pointers = (png_bytep *)malloc(sizeof(png_bytep)*m_H);
	for(y=0;y<m_H;y++)
		row_pointers[y] = (png_byte *)malloc(info_ptr->rowbytes);

        png_read_image(png_ptr, row_pointers);

	png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
	fclose(fd);
	
	m_Image = new color_alpha[m_W*m_H];
	for(y=0;y<m_H;y++) {
		for(x=0;x<m_W;x++) {
			m_Image[m_W*y+x].c = MAKERGB565(row_pointers[y][4*x], row_pointers[y][4*x+1], row_pointers[y][4*x+2]);
			m_Image[m_W*y+x].alpha = row_pointers[y][4*x+3];
		}
		free(row_pointers[y]);
	}
	
	free(row_pointers);
}

CPNGLoader::~CPNGLoader()
{
	if(m_Image != NULL) delete m_Image;
}

bool CPNGLoader::blit(CRegion *region, int x, int y, int w, int h, color background)
{
	color *regionFB = region->getFramebuffer();
	int regionW = region->getW();
	int dx, dy;
	
	for(dy=0;dy<h;dy++)
		for(dx=0;dx<w;dx++) {
			if(m_Image[m_W*dy+dx].alpha == 255)
				regionFB[regionW*(y+dy)+x+dx] = m_Image[m_W*dy+dx].c;
			else
				regionFB[regionW*(y+dy)+x+dx] = COLOR_BLEND(background, m_Image[m_W*dy+dx].c, m_Image[m_W*dy+dx].alpha, 255);
		}
	
	return true;
}
