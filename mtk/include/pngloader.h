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

#ifndef __PNGLOADER_H
#define __PNGLOADER_H

#include <string>

#include "color.h"
#include "imageloader.h"

using namespace std;

class CPNGLoader : public CImageLoader {
	public:
		CPNGLoader(string filename);
		~CPNGLoader();
		
		bool blit(CRegion *region, int x, int y, int w, int h, color background);
	private:
		int m_BitDepth;
		int m_ColorType;
		color_alpha *m_Image;
};

#endif /* __PNGLOADER_H */
