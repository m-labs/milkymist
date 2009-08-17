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
#include "container.h"

CWidget::CWidget(CContainer *parent) :
	m_Parent(parent),

	m_ThisInvalid(true)
{
	m_Environment = m_Parent->getEnvironment();
	
	m_Highlighted = m_Parent->getHighlighted();
	m_Disabled = m_Parent->getDisabled();

	/* this will send the invalidate message */
	m_Parent->registerChild(this);
}

CWidget::CWidget(CEnvironment *environment) :
	m_Parent(NULL),
	
	m_ThisInvalid(true),
	
	m_Environment(environment),
	
	m_Highlighted(false),
	m_Disabled(false)
{
	/* a parent-less widget must ask to be drawn by itself */
	m_Environment->getEvents()->postEvent(this, MSG_PAINT, 0, 0);
}

CWidget::~CWidget()
{
	if(m_Parent) m_Parent->unregisterChild(this);
	m_Environment->getEvents()->purge(this);
}

void CWidget::invalidate()
{
	/* Do not post an event and traverse the widget tree for nothing */
	if(!m_ThisInvalid) {
		m_Environment->getEvents()->postEvent(this, MSG_PAINT, 0, 0);
		if(m_Parent) m_Parent->invalidateChildren();
	}
	m_ThisInvalid = true;
}

void CWidget::setHighlighted(bool highlighted)
{
	m_Highlighted = highlighted;
	invalidate();
}

void CWidget::setDisabled(bool disabled)
{
	m_Disabled = disabled;
	invalidate();
}
