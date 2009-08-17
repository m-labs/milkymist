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

#include "events.h"
#include "focus.h"
#include "focusable.h"

CFocusable::CFocusable(CFocus *focus, CEvents *events) :
	m_Focus(focus),
	m_Events(events),
	m_NotifyGainFocus(false),
	m_NotifyLoseFocus(false)
{
	m_Focus->registerFocusable(this);
}

CFocusable::~CFocusable()
{
	m_Focus->unregisterFocusable(this);
}

void CFocusable::onFocus(bool focused)
{
	if(focused && m_NotifyGainFocus)
		m_Events->postEvent(this, MSG_FOCUSGAINED);
	if(!focused && m_NotifyLoseFocus)
		m_Events->postEvent(this, MSG_FOCUSLOST);
}

void CFocusable::onKeyboard(int keycode)
{
}

bool CFocusable::isFocused() const
{
	return m_Focus->getFocused() == this;
}

void CFocusable::setNotifyFocus(bool notifyGainFocus, bool notifyLoseFocus, bool sendEvent)
{
	m_NotifyGainFocus = notifyGainFocus;
	m_NotifyLoseFocus = notifyLoseFocus;
	if(sendEvent) {
		if(isFocused() && m_NotifyGainFocus)
			m_Events->postEvent(this, MSG_FOCUSGAINED);
		if(!isFocused() && m_NotifyLoseFocus)
			m_Events->postEvent(this, MSG_FOCUSLOST);
	}
}
