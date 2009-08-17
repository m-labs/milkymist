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

#ifndef __SCREEN_H
#define __SCREEN_H

#include "color.h"

class CRegion;

using namespace std;

enum {
	CAP_COMPOSE_ALPHA	= 0x01,
	CAP_COMPOSE_BLUR	= 0x02,
};

class CScreen {
	public:
		virtual CRegion *createRegion(int x, int y, int w, int h, bool visible=true, int z=0, int alpha=255, int blur=0)=0;
		
		virtual void registerRegion(CRegion *region)=0;
		virtual void unregisterRegion(CRegion *region)=0;
		
		virtual void paint()=0;
		virtual void compose()=0;
		
		virtual int getW() const=0;
		virtual int getH() const=0;
		
		virtual void setPosition(CRegion *region, int x, int y);
		virtual void setVisible(CRegion *region, bool visible);
		virtual void setZ(CRegion *region, int z);
		
		/* Composition effects */
		virtual int getComposeCapabilities() const { return 0; }
		virtual void setAlpha(CRegion *region, int alpha);
		virtual void setBlur(CRegion *region, int blur);
};

#endif /* __SCREEN_H */
