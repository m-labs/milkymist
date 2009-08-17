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

#ifndef __ICON_H
#define __ICON_H

#include "color.h"
#include "widget.h"
#include "colormodel.h"

class CContainer;
class CDC;
class CImageLoader;

enum {
	ICON_ALIGNMENT_TOP_LEFT,
	ICON_ALIGNMENT_CENTER,
	ICON_ALIGNMENT_BOTTOM_RIGHT
};

class CIcon : public CWidget {
	public:
		CIcon(CContainer *parent, CImageLoader *image);

		void paint(CDC *dc);
		
		void setImage(CImageLoader *image);
		
		void setHAlignment(int alignment);
		int getHAlignment() const { return m_HAlignment; }
		void setVAlignment(int alignment);
		int getVAlignment() const { return m_VAlignment; }
		
		CColorModel backgroundColor;
	private:
		CImageLoader *m_Image;
		int m_HAlignment;
		int m_VAlignment;
};

#endif /* __ICON_H */
