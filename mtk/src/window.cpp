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

#include <cstddef>
#include <cassert>

#include "region.h"
#include "colorschema.h"
#include "events.h"
#include "dc.h"
#include "window.h"

CWindow::CWindow(CEnvironment *environment, CRegion *region) : 
	CContainer(environment),
	
	m_Region(region),
	m_Contents(NULL)
{
	m_Region->setTopWidget(this);
}

CWindow::~CWindow()
{
	if(m_Contents) delete m_Contents;
	m_Region->setTopWidget(NULL);
}

void CWindow::registerChild(CWidget *child)
{
	if(m_Contents) delete m_Contents;
	m_Contents = child;
	invalidateChildren();
}

void CWindow::unregisterChild(CWidget *child)
{
	assert(child == m_Contents);
	m_Contents = NULL;
	invalidateChildren();
}

void CWindow::invalidateAll()
{
	invalidate();
	invalidateChildren();
	if(m_Contents) m_Contents->invalidateAll();
}

void CWindow::paint(CDC *dc)
{
	/*
	 * Paint is always made up of two steps :
	 * 1. redraw this widget if it's invalid
	 * 2. if this widget has an invalid child, call paint for it
	 */
	
	/* 1. nothing to do, CWindow is just a wrapper for CRegion,
	 * which does not draw anything by itself.
	 */
	m_ThisInvalid = false;
	
	/* 2. only one child */
	if(m_ChildInvalid) {
		m_ChildInvalid = false;
		if(m_Contents)
			/* we keep the same DC as the window does not have borders
			 * or other elements.
			 */
			m_Contents->paint(dc);
		else
			dc->fillRect(0, 0, dc->getW(), dc->getH(), m_EmptyColor);
	}
}

void CWindow::setHighlighted(bool highlighted)
{
	CContainer::setHighlighted(highlighted);
	if(m_Contents) m_Contents->setHighlighted(highlighted);
}

void CWindow::setDisabled(bool disabled)
{
	CContainer::setDisabled(disabled);
	if(m_Contents) m_Contents->setDisabled(disabled);
}
