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

#ifndef __IMAGELOADER_H
#define __IMAGELOADER_H

#include "color.h"

class CRegion;

class CImageLoader {
	public:
		virtual bool blit(CRegion *region, int x, int y, int w, int h, color background=DEFAULT_COLOR)=0;
		
		int getW() const { return m_W; }
		int getH() const { return m_H; }
	protected:
		int m_W;
		int m_H;
};

#endif /* __IMAGELOADER_H */
