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

#include "events.h"
#include "widget.h"
#include "environment.h"
#include "color.h"
#include "colorschema.h"
#include "container.h"

CContainer::CContainer(CContainer *parent) :
	CWidget(parent),

	m_ChildInvalid(true)
{
	m_EmptyColor = m_Environment->getColorSchema()->getBackground();
}

CContainer::CContainer(CEnvironment *environment) :
	CWidget(environment),
	
	m_ChildInvalid(true)
{
	m_EmptyColor = m_Environment->getColorSchema()->getBackground();
}

void CContainer::invalidate()
{
	if(!m_ThisInvalid && !m_ChildInvalid) {
		m_Environment->getEvents()->postEvent(this, MSG_PAINT, 0, 0);
		if(m_Parent) m_Parent->invalidateChildren();
	}
	m_ThisInvalid = true;
}

void CContainer::invalidateChildren()
{
	if(!m_ThisInvalid && !m_ChildInvalid) {
		m_Environment->getEvents()->postEvent(this, MSG_PAINT, 0, 0);
		if(m_Parent) m_Parent->invalidateChildren();
	}
	m_ChildInvalid = true;
}

void CContainer::setEmptyColor(color c)
{
	m_EmptyColor = c;
	invalidateChildren();
}
