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

#include <string.h>
#include <set>
#include <iostream>

#include "color.h"
#include "region.h"
#include "regionpurefb.h"
#include "screen.h"
#include "screenpurefb.h"
#include "dc.h"
#include "widget.h"

CScreenPureFB::CScreenPureFB(color *framebuffer, int w, int h, CFontRenderer *fontRenderer) :
	m_Framebuffer(framebuffer),
	m_W(w),
	m_H(h),
	m_FontRenderer(fontRenderer)
{
}

CScreenPureFB::~CScreenPureFB()
{
}

CRegion *CScreenPureFB::createRegion(int x, int y, int w, int h, bool visible, int z, int alpha, int blur)
{
	return new CRegionPureFB(this, x, y, w, h, visible, z, alpha, blur);
}

void CScreenPureFB::registerRegion(CRegion *region)
{
	m_Regions.insert(m_Regions.begin(), region);
}

void CScreenPureFB::unregisterRegion(CRegion *region)
{
	m_Regions.erase(m_Regions.find(region));
}

void CScreenPureFB::paint()
{
	multiset<CRegion *>::const_iterator i;
	for(i=m_Regions.begin();i!=m_Regions.end();i++) {
		CWidget *topWidget;
		
		topWidget = (*i)->getTopWidget();
		if(topWidget == NULL) continue;
		
		CDC paintDC(*i, m_FontRenderer, 0, 0, (*i)->getW(), (*i)->getH());
		topWidget->paint(&paintDC);
	}
}

void CScreenPureFB::compose()
{
	memset(m_Framebuffer, 0, m_W*m_H*sizeof(color));
	int dx, dy;
	multiset<CRegion *>::const_iterator i;
	for(i=m_Regions.begin();i!=m_Regions.end();i++) {
		if((*i)->getVisible()) {
			int sx, sy;
			int dx, dy;
			int dx_max, dy_max;
			int s_W, s_H;
			color *source;
			
			sx = 0;
			sy = 0;
			dx = (*i)->getX();
			dy = (*i)->getY();
			s_W = (*i)->getW();
			s_H = (*i)->getH();
			dx_max = dx + s_W - 1;
			dy_max = dy + s_H - 1;
			if(dx_max >= m_W) dx_max = m_W - 1;
			if(dy_max >= m_H) dy_max = m_H - 1;
			
			/* TODO: clip */
			if(dx < 0) dx = 0;
			if(dy < 0) dy = 0;
			
			source = (*i)->getFramebuffer();
			
			int sx2, sy2;
			int dx2, dy2;
			
			for(dy2=dy, sy2=sy;dy2<=dy_max;dy2++, sy2++)
				for(dx2=dx, sx2=sx;dx2<=dx_max;dx2++, sx2++)
					m_Framebuffer[m_W*dy2+dx2] = source[s_W*sy2+sx2];
		}
	}
}

void CScreenPureFB::setZ(CRegion *region, int z)
{
	unregisterRegion(region);
	CScreen::setZ(region, z);
	registerRegion(region);
}

