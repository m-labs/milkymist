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

#include <iostream>

using namespace std;

#include "screen.h"
#include "region.h"
#include "widget.h"

CRegion::CRegion(CScreen *screen, int x, int y, int w, int h, bool visible, int z, int alpha, int blur) :
	m_Screen(screen),
	m_W(w),
	m_H(h),
	m_X(x),
	m_Y(y),
	m_Visible(visible),
	m_Z(z),
	m_Alpha(alpha),
	m_Blur(blur),
	m_TopWidget(NULL)
{
	m_Screen->registerRegion(this);
}

CRegion::~CRegion()
{
	if(m_TopWidget) delete m_TopWidget;
	m_Screen->unregisterRegion(this);
}

void CRegion::setPosition(int x, int y)
{
	m_Screen->setPosition(this, x, y);
}

void CRegion::setVisible(bool visible)
{
	m_Screen->setVisible(this, visible);
}

void CRegion::setZ(int z)
{
	m_Screen->setZ(this, z);
}

void CRegion::setAlpha(int alpha)
{
	m_Screen->setAlpha(this, alpha);
}

void CRegion::setBlur(int blur)
{
	m_Screen->setBlur(this, blur);
}

void CRegion::setTopWidget(CWidget *widget)
{
	if(widget != NULL) delete m_TopWidget;
	m_TopWidget = widget;
}
