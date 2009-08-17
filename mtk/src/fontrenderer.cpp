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

#include <cassert>
#include <string>

#include <ft2build.h>
#include FT_FREETYPE_H

#include "color.h"
#include "region.h"
#include "fontrenderer.h"

using namespace std;

CFontRenderer::CFontRenderer()
{
	FT_Init_FreeType(&m_FreetypeHandle);
}

CFontRenderer::~CFontRenderer()
{
	FT_Done_FreeType(m_FreetypeHandle);
}

fontHandle CFontRenderer::loadFont(const char *filename)
{
	fontHandle ret;
	
	if(FT_New_Face(m_FreetypeHandle, filename, 0, &ret) != 0) return INVALID_FONT_HANDLE;
	return ret;
}

void CFontRenderer::unloadFont(fontHandle font)
{
	FT_Done_Face(font);
}

int CFontRenderer::renderString(CRegion *region, const string s, fontHandle font, int size, int x, int y, int w, int h, color foreground, color background, int shadowX, int shadowY, color shadowColor, bool center)
{
	assert(shadowX >= 0);
	assert(shadowY >= 0);

	FT_GlyphSlot slot = font->glyph;
	FT_UInt glyph_index;
	FT_Error error;
	int pen_x, pen_y, n, len, remaining;
	color *regionFB = region->getFramebuffer();
	int regionW = region->getW();
	const unsigned char *sb;
	bool shadowEn = (shadowX > 0)||(shadowY > 0);

	FT_Set_Pixel_Sizes(font, 0, size);
	
	pen_x = x;
	pen_y = y+(h-size)/2;
	
	remaining = len = s.length();
	n = 0;
	sb = (const unsigned char *)s.c_str();
	while(remaining > 0) {
		int next_pen_x;
		int dxi, dyi;
		int sx, sy;
		int dx, dy;
		unsigned int ucs;
		
		/* Perform UTF-8 to UCS conversion */
		if(sb[n] < 0x80) {
			ucs = sb[n];
			n++;
			remaining--;
		} else if(sb[n] < 0xc0) {
			/* middle part of a character - should not happen */
			ucs = '?';
			n++;
			remaining--;
		} else if((sb[n] < 0xe0) && (remaining >= 2)) {
			ucs =
				 ((sb[n  ] & 0x1f) << 6)
				| (sb[n+1] & 0x3f);
			n += 2;
			remaining -= 2;
		} else if((sb[n] < 0xf0) && (remaining >= 3)) {
			ucs =
				 ((sb[n  ] & 0x0f) << 12)
				|((sb[n+1] & 0x3f) << 6)
				| (sb[n+2] & 0x3f);
			n += 3;
			remaining -= 3;
		}  else if((sb[n] < 0xf8) && (remaining >= 4)) {
			ucs =
				 ((sb[n  ] & 0x07) << 18)
				|((sb[n+1] & 0x3f) << 12)
				|((sb[n+2] & 0x3f) << 6)
				| (sb[n+3] & 0x3f);
			n += 4;
			remaining -= 4;
		} else if((sb[n] < 0xfc) && (remaining >= 5)) {
			ucs =
				 ((sb[n  ] & 0x03) << 24)
				|((sb[n+1] & 0x3f) << 18)
				|((sb[n+2] & 0x3f) << 12)
				|((sb[n+3] & 0x3f) << 6)
				| (sb[n+4] & 0x3f);
			n += 5;
			remaining -= 5;
		} else if(remaining >= 6) {
			ucs =
				 ((sb[n  ] & 0x01) << 30)
				|((sb[n+1] & 0x3f) << 24)
				|((sb[n+2] & 0x3f) << 18)
				|((sb[n+3] & 0x3f) << 12)
				|((sb[n+4] & 0x3f) << 6)
				| (sb[n+5] & 0x3f);
			n += 6;
			remaining -= 6;
		} else {
			ucs = '?';
			n++;
			remaining--;
		}
		
		error = FT_Load_Char(font, ucs, FT_LOAD_RENDER);
		if(error) continue;
		
		dyi = pen_y+size-slot->bitmap_top;
		dxi = pen_x+slot->bitmap_left;
		
		if((dxi+shadowX+(slot->advance.x >> 6)) >= (x+w))
			break;
		
		for(sy=0, dy=dyi;sy<slot->bitmap.rows;sy++, dy++)
			for(sx=0, dx=dxi;sx<slot->bitmap.width;sx++, dx++) {
				unsigned char intensity;
				intensity = slot->bitmap.buffer[slot->bitmap.width*sy+sx];
				
				if(intensity != 0) {
					if(intensity == slot->bitmap.num_grays-1) {
						if(shadowEn)
							regionFB[regionW*(dy+shadowY)+dx+shadowX] = shadowColor;
						regionFB[regionW*dy+dx] = foreground;
					} else {
						if(shadowEn)
							regionFB[regionW*(dy+shadowY)+dx+shadowX] = COLOR_BLEND(background, shadowColor, intensity, slot->bitmap.num_grays-1);
						regionFB[regionW*dy+dx] = COLOR_BLEND(regionFB[regionW*dy+dx], foreground, intensity, slot->bitmap.num_grays-1);
					}
				}
			}
		
		pen_x += slot->advance.x >> 6;
	}
	
	/* Center the text */
	if(center) {
		int textw;
		int texth;
		int shift;
		int sx, sy;
		
		textw = pen_x-x+shadowX;
		//texth = size+shadowY;
		shift = (w-textw)/2;
		
		for(sy=y;sy<y+h;sy++) {
			for(sx=x+shift+textw-1;sx>=x+shift;sx--)
				regionFB[regionW*sy+sx] = regionFB[regionW*sy+sx-shift];
			for(sx=x;sx<x+shift;sx++)
				regionFB[regionW*sy+sx] = background;
		}
	}
	
	return n;
}

