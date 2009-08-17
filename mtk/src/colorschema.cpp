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

#ifdef RGB565

CColorSchema::CColorSchema() :
	m_Background(MAKERGB565(0, 0, 0)),
	
	m_Border(MAKERGB565(0, 48, 156)),
	m_BorderH(MAKERGB565(30, 78, 186)),
	m_BorderD(MAKERGB565(100, 100, 100)),
	
	m_WidgetForeground(MAKERGB565(255, 255, 255)),
	m_WidgetForegroundShadow(MAKERGB565(64, 64, 92)),
	m_WidgetBackground(MAKERGB565(90, 126, 220)),
	
	m_WidgetForegroundH(MAKERGB565(90, 126, 220)),
	m_WidgetForegroundShadowH(MAKERGB565(64, 64, 92)),
	m_WidgetBackgroundH(MAKERGB565(255, 255, 255)),
	
	m_WidgetForegroundD(MAKERGB565(170, 170, 170)),
	m_WidgetForegroundShadowD(MAKERGB565(64, 64, 92)),
	m_WidgetBackgroundD(MAKERGB565(70, 106, 200))
{
}

#endif
