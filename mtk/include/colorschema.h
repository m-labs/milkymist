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

#ifndef __COLORSCHEMA_H
#define __COLORSCHEMA_H

#include "color.h"

class CColorSchema {
	public:
		CColorSchema();
		
		virtual color getBackground() const { return m_Background; }
		
		virtual color getBorder() const { return m_Border; }
		virtual color getBorderH() const { return m_BorderH; }
		virtual color getBorderD() const { return m_BorderD; }
		
		virtual color getWidgetForeground() const { return m_WidgetForeground; }
		virtual color getWidgetForegroundShadow() const { return m_WidgetForegroundShadow; }
		virtual color getWidgetBackground() const { return m_WidgetBackground; }
				
		virtual color getWidgetForegroundH() const { return m_WidgetForegroundH; }
		virtual color getWidgetForegroundShadowH() const { return m_WidgetForegroundShadowH; }
		virtual color getWidgetBackgroundH() const { return m_WidgetBackgroundH; }
		
		virtual color getWidgetForegroundD() const { return m_WidgetForegroundD; }
		virtual color getWidgetForegroundShadowD() const { return m_WidgetForegroundShadowD; }
		virtual color getWidgetBackgroundD() const { return m_WidgetBackgroundD; }
	protected:
		color m_Background;
		
		color m_Border;
		color m_BorderH;
		color m_BorderD;
		
		color m_WidgetForeground;
		color m_WidgetForegroundShadow;
		color m_WidgetBackground;
		
		color m_WidgetForegroundH;
		color m_WidgetForegroundShadowH;
		color m_WidgetBackgroundH;
		
		color m_WidgetForegroundD;
		color m_WidgetForegroundShadowD;
		color m_WidgetBackgroundD;
};

#endif /* __COLORSCHEMA_H */
