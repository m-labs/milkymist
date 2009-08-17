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

#ifndef __WIDGET_H
#define __WIDGET_H

#include <cstddef>

class CRegion;
class CEnvironment;
class CDC;
class CContainer;

class CWidget {
	public:
		CWidget(CContainer *parent);
		CWidget(CEnvironment *environment);
		virtual ~CWidget();
		
		virtual void paint(CDC *dc)=0;
		
		virtual void invalidate();
		virtual void invalidateAll() { invalidate(); }
		
		CEnvironment *getEnvironment() const { return m_Environment; }
		
		/* Attributes */
		virtual void setHighlighted(bool highlighted);
		virtual bool getHighlighted() const { return m_Highlighted; }
		
		virtual void setDisabled(bool disabled);
		virtual bool getDisabled() const { return m_Disabled; }
	protected:
		CContainer *m_Parent;
		CEnvironment *m_Environment;
		bool m_ThisInvalid; /* this widget has invalid areas that are not in a child widget */
		
		bool m_Highlighted;
		bool m_Disabled;
};

#endif
