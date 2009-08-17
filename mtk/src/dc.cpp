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

#include "color.h"
#include "region.h"
#include "dc.h"
#include "imageloader.h"

using namespace std;

CDC::CDC(CRegion *region, CFontRenderer *fontRenderer, int x, int y, int w, int h) :
	m_Region(region),
	m_FontRenderer(fontRenderer)
{
	/* Make all coordinate fields safe */
	if(x >= m_Region->getW()) m_X = m_Region->getW()-1;
	else if(x < 0) m_X = 0;
	else m_X = x;
	
	if(y >= m_Region->getH()) m_Y = m_Region->getH()-1;
	else if(y < 0) m_Y = 0;
	else m_Y = y;
	
	if(w < 0) m_W = 0;
	else if(m_X + w >= m_Region->getW()) m_W = m_Region->getW() - m_X;
	else m_W = w;
	
	if(h < 0) m_H = 0;
	else if(m_Y + h >= m_Region->getH()) m_H = m_Region->getH() - m_Y;
	else m_H = h;
}

CDC::CDC(CDC *parentDC, int x, int y, int w, int h)
{
	/* Make sure the clipping area is entirely contained inside its parent */
	if(x < 0) x = 0;
	if(y < 0) y = 0;
	
	if(w > parentDC->getW()) w = parentDC->getW();
	if(h > parentDC->getH()) h = parentDC->getH();
	
	if(x + w > parentDC->getW()) x = parentDC->getW()-w;
	if(y + h > parentDC->getH()) y = parentDC->getH()-h;
	
	m_X = parentDC->getX() + x;
	m_Y = parentDC->getY() + y;
	m_W = w;
	m_H = h;
	
	m_Region = parentDC->getRegion();
	m_FontRenderer = parentDC->getFontRenderer();
}

void CDC::setPixel(int x, int y, color c)
{
	if((x >= m_W)|(y >= m_H)) return;
	
	int rx = x + m_X;
	int ry = y + m_Y;
	color *regionFB = m_Region->getFramebuffer();
	regionFB[m_Region->getW()*ry+rx] = c;
}

void CDC::fillRect(int x, int y, int w, int h, color c)
{
	if(x < 0) x = 0;
	if(y < 0) y = 0;
	if(x >= m_W) x = m_W - 1;
	if(y >= m_H) y = m_H - 1;
	if(x + w > m_W) w = m_W - x;
	if(y + h > m_H) h = m_H - y;

	int xmin = x + m_X;
	int xmax = x + m_X + w - 1;
	int ymin = y + m_Y;
	int ymax = y + m_Y + h - 1;
	
	int rx, ry;
	int rw = m_Region->getW();
	color *regionFB = m_Region->getFramebuffer();

	for(ry=ymin;ry<=ymax;ry++)
		for(rx=xmin;rx<=xmax;rx++)
			regionFB[rw*ry+rx] = c;
}

int CDC::renderString(const string s, fontHandle font, int size, int x, int y, int w, int h, color foreground, color background, int shadowX, int shadowY, color shadowColor, bool center)
{
	if(x < 0) x = 0;
	if(y < 0) y = 0;
	if(x >= m_W) x = m_W - 1;
	if(y >= m_H) y = m_H - 1;
	if(x + w > m_W) w = m_W - x;
	if(y + h > m_H) h = m_H - y;
	
	return m_FontRenderer->renderString(m_Region, s, font, size, m_X+x, m_Y+y, w, h, foreground, background, shadowX, shadowY, shadowColor, center);
}

void CDC::blendHLine(int x, int y, int blendLength, int totalLength, color foreground, color background)
{
	int i;
	color *regionFB = m_Region->getFramebuffer();
	int rw = m_Region->getW();
	
	if(x >= m_W) x = m_W-1;
	if(totalLength+x > m_W) totalLength = m_W-x;
	if(blendLength > totalLength/2)
		blendLength = totalLength/2;
	x += m_X;
	y += m_Y;
	totalLength = totalLength-2*blendLength;
	
	for(i=0;i<blendLength;i++) {
		regionFB[rw*y+x] = COLOR_BLEND(background, foreground, i, blendLength);
		x++;
	}
	for(i=0;i<totalLength;i++) {
		regionFB[rw*y+x] = foreground;
		x++;
	}
	for(i=0;i<blendLength;i++) {
		regionFB[rw*y+x] = COLOR_BLEND(foreground, background, i, blendLength);
		x++;
	}
}

void CDC::blendVLine(int x, int y, int blendLength, int totalLength, color foreground, color background)
{
	int i;
	color *regionFB = m_Region->getFramebuffer();
	int rw = m_Region->getW();
	
	if(y >= m_H) y = m_H-1;
	if(totalLength+y > m_H) totalLength = m_H-y;
	if(blendLength > totalLength/2)
		blendLength = totalLength/2;
	x += m_X;
	y += m_Y;
	totalLength = totalLength-2*blendLength;
	
	for(i=0;i<blendLength;i++) {
		regionFB[rw*y+x] = COLOR_BLEND(background, foreground, i, blendLength);
		y++;
	}
	for(i=0;i<totalLength;i++) {
		regionFB[rw*y+x] = foreground;
		y++;
	}
	for(i=0;i<blendLength;i++) {
		regionFB[rw*y+x] = COLOR_BLEND(foreground, background, i, blendLength);
		y++;
	}
}

void CDC::renderArrow(int x, int y, int size, color c, bool left)
{
	int i;
	int cx;
	color *regionFB = m_Region->getFramebuffer();
	int rw = m_Region->getW();
	
	if(x < 0) x = 0;
	if(y < 0) y = 0;
	if(x >= m_W) x = m_W - 1;
	if(y >= m_H) y = m_H - 1;
	if(x + size/2 > m_W) size = 2*(m_W - x);
	if(y + size > m_H) size = m_H - y;
	
	x += m_X;
	y += m_Y;
	
	size /= 2;
	
	if(left) {
		for(i=1;i<size;i++) {
			for(cx=x+size-i;cx<x+size;cx++)
				regionFB[rw*y+cx] = c;
			y++;
		}
		for(i=size;i>0;i--) {
			for(cx=x+size-i;cx<x+size;cx++)
				regionFB[rw*y+cx] = c;
			y++;
		}
	} else {
		for(i=0;i<size;i++) {
			for(cx=x;cx<x+i;cx++)
				regionFB[rw*y+cx] = c;
			y++;
		}
		for(i=size;i>0;i--) {
			for(cx=x;cx<x+i;cx++)
				regionFB[rw*y+cx] = c;
			y++;
		}
	}
}

bool CDC::blitImage(int x, int y, CImageLoader *image, color background)
{
	int w, h;
	
	if(x < 0) x = 0;
	if(y < 0) y = 0;
	
	w = image->getW();
	if(w > m_W) w = m_W;
	h = image->getH();
	if(w > m_H) w = m_H;
	
	if(x + w > m_W) w = m_W - x;
	if(y + h > m_H) h = m_H - y;
	
	x += m_X;
	y += m_Y;
	
	return image->blit(m_Region, x, y, w, h, background);
}


