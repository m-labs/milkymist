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

#include "color.h"
#include "colorschema.h"
#include "colormodel.h"
#include "environment.h"
#include "container.h"
#include "dc.h"
#include "imageloader.h"
#include "icon.h"

CIcon::CIcon(CContainer *parent, CImageLoader *image) :
	CWidget(parent),
	backgroundColor(this, m_Environment->getColorSchema(), COLORMODEL_BACKGROUND),
	
	m_Image(image),
	m_HAlignment(ICON_ALIGNMENT_CENTER),
	m_VAlignment(ICON_ALIGNMENT_CENTER)
{
}

void CIcon::paint(CDC *dc)
{
	if(m_ThisInvalid) {
		int x, y;
		color back;
		
		switch(m_HAlignment) {
			case ICON_ALIGNMENT_TOP_LEFT:
				x = 0;
				break;
			case ICON_ALIGNMENT_CENTER:
				x = (dc->getW()-m_Image->getW())/2;
				break;
			case ICON_ALIGNMENT_BOTTOM_RIGHT:
				x = dc->getW()-m_Image->getW();
				break;
		}
		switch(m_VAlignment) {
			case ICON_ALIGNMENT_TOP_LEFT:
				y = 0;
				break;
			case ICON_ALIGNMENT_CENTER:
				y = (dc->getH()-m_Image->getH())/2;
				break;
			case ICON_ALIGNMENT_BOTTOM_RIGHT:
				y = dc->getH()-m_Image->getH();
				break;
		}
		
		dc->fillRect(0, 0, dc->getW(), dc->getH(), backgroundColor.getCurrent());
		dc->blitImage(x, y, m_Image, backgroundColor.getCurrent());
		m_ThisInvalid = false;
	}
}

void CIcon::setImage(CImageLoader *image)
{
	m_Image = image;
	invalidate();
}

void CIcon::setHAlignment(int alignment)
{
	m_HAlignment = alignment;
	invalidate();
}

void CIcon::setVAlignment(int alignment)
{
	m_VAlignment = alignment;
	invalidate();
}
