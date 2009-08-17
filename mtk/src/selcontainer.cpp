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

#include "environment.h"
#include "dc.h"
#include "container.h"
#include "events.h"
#include "focus.h"
#include "keycodes.h"
#include "selcontainer.h"

CSelContainer::CSelContainer(CContainer *parent, CFocus *focus) :
	CContainer(parent),
	CFocusable(focus, parent->getEnvironment()->getEvents()),
	
	m_Contents(NULL),
	m_NotifySelected(true)
{
}

CSelContainer::~CSelContainer()
{
	if(m_Contents) delete m_Contents;
}

void CSelContainer::registerChild(CWidget *child)
{
	if(m_Contents) delete m_Contents;
	m_Contents = child;
	invalidateChildren();
}

void CSelContainer::unregisterChild(CWidget *child)
{
	assert(child == m_Contents);
	m_Contents = NULL;
	invalidateChildren();
}

void CSelContainer::invalidateAll()
{
	invalidate();
	invalidateChildren();
	if(m_Contents) m_Contents->invalidateAll();
}

void CSelContainer::paint(CDC *dc)
{
	m_ThisInvalid = false;
	
	if(m_ChildInvalid) {
		m_ChildInvalid = false;
		if(m_Contents)
			m_Contents->paint(dc);
		else
			dc->fillRect(0, 0, dc->getW(), dc->getH(), m_EmptyColor);
	}
}

void CSelContainer::onFocus(bool focused)
{
	CFocusable::onFocus(focused);
	if(m_Contents)
		m_Contents->setHighlighted(focused);
}

void CSelContainer::onKeyboard(int keycode)
{
	switch(keycode) {
		case KEY_OK:
			if(m_NotifySelected)
				m_Environment->getEvents()->postEvent(this, MSG_SELECTED);
			break;
		case KEY_LEFT:
		case KEY_UP:
			m_Focus->switchFocused(false);
			break;
		case KEY_RIGHT:
		case KEY_DOWN:
			m_Focus->switchFocused(true);
			break;
	}
}

void CSelContainer::setHighlighted(bool highlighted)
{
	/* highlighting disabled */
}

void CSelContainer::setDisabled(bool disabled)
{
	CContainer::setDisabled(disabled);
	if(m_Contents) m_Contents->setDisabled(disabled);
	if(m_Disabled)
		m_Focus->unregisterFocusable(this);
	else
		m_Focus->registerFocusable(this);
}
