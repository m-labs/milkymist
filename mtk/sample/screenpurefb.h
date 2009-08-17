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

#ifndef __SCREENPUREFB_H
#define __SCREENPUREFB_H

#include <set>

#include "color.h"
#include "region.h"
#include "screen.h"

class CFontRenderer;

struct ltregion {
	bool operator()(const CRegion *a, const CRegion *b) const {
		return a->getZ() < b->getZ();
	}
};

class CScreenPureFB : public CScreen {
	public:
		CScreenPureFB(color *framebuffer, int w, int h, CFontRenderer *fontRenderer);
		~CScreenPureFB();
		
		CRegion *createRegion(int x, int y, int w, int h, bool visible=true, int z=0, int alpha=255, int blur=0);
		
		void registerRegion(CRegion *region);
		void unregisterRegion(CRegion *region);
	
		void paint();
		void compose();
		
		int getW() const { return m_W; }
		int getH() const { return m_H; }
		
		void setZ(CRegion *region, int z);
	private:
		color *m_Framebuffer;
		int m_W, m_H;
		CFontRenderer *m_FontRenderer;
		multiset<CRegion *, ltregion> m_Regions;
};

#endif /* __SCREENPUREFB_H */
