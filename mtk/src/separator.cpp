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
#include "separator.h"
#include "dc.h"

CSeparator::CSeparator(CContainer *parent, bool vertical) :
	CWidget(parent),
	
	backgroundColor(this, m_Environment->getColorSchema(), COLORMODEL_BACKGROUND),
	foregroundColor(this, m_Environment->getColorSchema(), COLORMODEL_FOREGROUND),
	
	m_Vertical(vertical),
	m_BlendLength(-100)
{
}

void CSeparator::paint(CDC *dc)
{
	if(m_ThisInvalid) {
		color back, fore;
		int blendLength;
		
		back = backgroundColor.getCurrent();
		fore = foregroundColor.getCurrent();
		
		dc->fillRect(0, 0, dc->getW(), dc->getH(), back);
		
		if(m_Vertical) {
			if(m_BlendLength < 0)
				blendLength = (dc->getH()*(-m_BlendLength)) >> 10;
			else
				blendLength = m_BlendLength;
		
			dc->blendVLine(dc->getW()/2, 0, blendLength, dc->getH(), fore, back);
		} else {
			if(m_BlendLength < 0)
				blendLength = (dc->getW()*(-m_BlendLength)) >> 10;
			else
				blendLength = m_BlendLength;
	
			dc->blendHLine(0, dc->getH()/2, blendLength, dc->getW(), fore, back);
		}
		m_ThisInvalid = false;
	}
}

void CSeparator::setVertical(bool vertical)
{
	m_Vertical = vertical;
	invalidate();
}

void CSeparator::setBlendLength(int blendLength)
{
	m_BlendLength = blendLength;
	invalidate();
}
