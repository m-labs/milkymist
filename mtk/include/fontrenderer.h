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

#ifndef __FONTRENDERER_H
#define __FONTRENDERER_H

#include <string>

#include <ft2build.h>
#include FT_FREETYPE_H

#include "color.h"

typedef FT_Face fontHandle;
#define INVALID_FONT_HANDLE NULL

using namespace std;

class CRegion;

class CFontRenderer {
	public:
		CFontRenderer();
		~CFontRenderer();
		
		fontHandle loadFont(const char *filename);
		void unloadFont(fontHandle font);
		
		int renderString(CRegion *region, const string s, fontHandle font, int size, int x, int y, int w, int h, color foreground, color background, int shadowX=0, int shadowY=0, color shadowColor=DEFAULT_COLOR, bool center=false);
	private:
		 FT_Library m_FreetypeHandle;
};

#endif /* __FONTRENDERER_H */
