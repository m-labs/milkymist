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
#include "colorschema.h"
#include "colormodel.h"
#include "environment.h"
#include "dc.h"
#include "widget.h"
#include "container.h"
#include "fontschema.h"
#include "label.h"

using namespace std;

CLabel::CLabel(CContainer *parent, const string text, bool center) :
	CWidget(parent),
	backgroundColor(this, m_Environment->getColorSchema(), COLORMODEL_BACKGROUND),
	foregroundColor(this, m_Environment->getColorSchema(), COLORMODEL_FOREGROUND),
	shadowColor(this, m_Environment->getColorSchema(), COLORMODEL_SHADOW)
{
	m_Font = m_Environment->getFontSchema()->getGeneralFont();
	m_FontSize = m_Environment->getFontSchema()->getGeneralFontSize();
	m_ShadowX = 0;
	m_ShadowY = 0;
	m_Center = center;
	m_Text = text;
}

void CLabel::setText(const string text)
{
	m_Text = text;
	invalidate();
}

void CLabel::paint(CDC *dc)
{
	if(m_ThisInvalid) {
		dc->fillRect(0, 0, dc->getW(), dc->getH(), backgroundColor.getCurrent());
		dc->renderString(m_Text, m_Font, m_FontSize,
			0, 0, dc->getW(), dc->getH(), foregroundColor.getCurrent(), backgroundColor.getCurrent(), m_ShadowX, m_ShadowY, shadowColor.getCurrent(), m_Center);
		m_ThisInvalid = false;
	}
}

void CLabel::setFont(fontHandle font)
{
	m_Font = font;
	invalidate();
}

void CLabel::setFontSize(int size)
{
	m_FontSize = size;
	invalidate();
}

void CLabel::setShadow(int shadowX, int shadowY)
{
	m_ShadowX = shadowX;
	m_ShadowY = shadowY;
	invalidate();
}

void CLabel::setCenter(bool center)
{
	m_Center = center;
	invalidate();
}
