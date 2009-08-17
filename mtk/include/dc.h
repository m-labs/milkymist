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

#ifndef __DC_H
#define __DC_H

#include <string>

#include "color.h"
#include "fontrenderer.h"

using namespace std;

class CRegion;
class CImageLoader;

class CDC {
	public:
		/* X, Y position inside the region */
		CDC(CRegion *region, CFontRenderer *fontRenderer, int x, int y, int w, int h);
		/* X, Y position relative to the upper left corner of the parent DC */
		CDC(CDC *parentDC, int x, int y, int w, int h);
		
		CRegion *getRegion() const { return m_Region; }
		CFontRenderer *getFontRenderer() const { return m_FontRenderer; }
		
		/* X, Y position inside the region */
		int getX() const { return m_X; }
		int getY() const { return m_Y; }
		
		/* Width and Height of the clipping area */
		int getW() const { return m_W; }
		int getH() const { return m_H; }
		
		/* X, Y position relative to the upper left corner of the DC */
		void setPixel(int x, int y, color c);
		void fillRect(int x, int y, int w, int h, color c);
		int renderString(const string s, fontHandle font, int size, int x, int y, int w, int h, color foreground, color background, int shadowX=0, int shadowY=0, color shadowColor=DEFAULT_COLOR, bool center=false);
		void blendHLine(int x, int y, int blendLength, int totalLength, color foreground, color background);
		void blendVLine(int x, int y, int blendLength, int totalLength, color foreground, color background);
		void renderArrow(int x, int y, int size, color c, bool left);
		bool blitImage(int x, int y, CImageLoader *image, color background=DEFAULT_COLOR);
	private:
		CRegion *m_Region;
		CFontRenderer *m_FontRenderer;
		int m_X, m_Y, m_W, m_H;
};

#endif /* __DC_H */
