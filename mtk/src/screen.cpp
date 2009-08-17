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

#include "region.h"
#include "screen.h"

void CScreen::setPosition(CRegion *region, int x, int y)
{
	region->m_X = x;
	region->m_Y = y;
}

void CScreen::setVisible(CRegion *region, bool visible)
{
	region->m_Visible = visible;
}

void CScreen::setZ(CRegion *region, int z)
{
	region->m_Z = z;
}

void CScreen::setAlpha(CRegion *region, int alpha)
{
	region->m_Alpha = alpha;
}

void CScreen::setBlur(CRegion *region, int blur)
{
	region->m_Blur = blur;
}
