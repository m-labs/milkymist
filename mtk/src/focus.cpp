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
#include <cstdio>
#include <cassert>
#include <vector>

#include "focusable.h"
#include "focus.h"

CFocus::CFocus() :
	m_Focused(-1)
{
}

void CFocus::registerFocusable(CFocusable *focusable)
{
	m_Focusables.push_back(focusable);
	/* We cannot focus the first registered focusable,
	 * as registerFocusable is called from its constructor
	 * and its onFocus method is virtual.
	 * The application must call setFocused once the
	 * focusable to be focused has been created.
	 */
}

void CFocus::unregisterFocusable(CFocusable *focusable)
{
	CFocusable *prev = m_Focusables[m_Focused];
	
	vector<CFocusable *>::iterator i;
	for(i=m_Focusables.begin();i!=m_Focusables.end();i++) {
		if(*i == focusable) {
			m_Focusables.erase(i);
			break;
		}
	}
	
	int j;
	m_Focused = -1;
	for(j=0;j<m_Focusables.size();j++)
		if(m_Focusables[j] == prev) {
			m_Focused = j;
			break;
		}
}

void CFocus::setFocusOrder(CFocusable *focusable, int order)
{
	int i;
	for(i=0;i<m_Focusables.size();i++) {
		if(m_Focusables[i] == focusable) {
			m_Focusables[i] = m_Focusables[order];
			m_Focusables[order] = focusable;
			break;
		}
	}
}

void CFocus::setFocused(CFocusable *focusable)
{
	int i;
	
	if(m_Focused >= 0)
		m_Focusables[m_Focused]->onFocus(false);
	for(i=0;i<m_Focusables.size();i++) {
		if(m_Focusables[i] == focusable) {
			m_Focused = i;
			break;
		}
	}
	assert(i < m_Focusables.size());
	focusable->onFocus(true);
}

void CFocus::switchFocused(bool next)
{
	if(m_Focusables.size() == 0) return;
	if(m_Focused >= 0) {
		m_Focusables[m_Focused]->onFocus(false);
		if(next) {
			if(m_Focused == (m_Focusables.size()-1))
				m_Focused = 0;
			else
				m_Focused++;
		} else {
			if(m_Focused == 0)
				m_Focused = m_Focusables.size()-1;
			else
				m_Focused--;
		}
	} else
		m_Focused = 0;
	m_Focusables[m_Focused]->onFocus(true);
}

bool CFocus::dispatchKeypress(int keycode)
{
	if(m_Focused >= 0)
		m_Focusables[m_Focused]->onKeyboard(keycode);
}
