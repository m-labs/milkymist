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

#include <string>

#include "color.h"
#include "colorschema.h"
#include "colormodel.h"
#include "keycodes.h"
#include "events.h"
#include "focus.h"
#include "environment.h"
#include "dc.h"
#include "widget.h"
#include "container.h"
#include "fontschema.h"
#include "combo.h"

using namespace std;

CCombo::CCombo(CContainer *parent) :
	CWidget(parent),
	CFocusable(m_Environment->getFocus(), m_Environment->getEvents()),
	backgroundColor(this, m_Environment->getColorSchema(), COLORMODEL_BACKGROUND),
	foregroundColor(this, m_Environment->getColorSchema(), COLORMODEL_FOREGROUND),
	shadowColor(this, m_Environment->getColorSchema(), COLORMODEL_SHADOW),
	m_ShadowX(0),
	m_ShadowY(0)
{
	m_Font = m_Environment->getFontSchema()->getGeneralFont();
	m_FontSize = m_Environment->getFontSchema()->getGeneralFontSize();
}

void CCombo::paint(CDC *dc)
{
	if(m_ThisInvalid) {
		dc->fillRect(0, 0, dc->getW(), dc->getH(), backgroundColor.getCurrent());
		if(m_Elements.size() > 0) {
			dc->renderString(m_Elements[m_Selection], m_Font, m_FontSize,
				0, 0, dc->getW(), dc->getH(), foregroundColor.getCurrent(), backgroundColor.getCurrent(), m_ShadowX, m_ShadowY, shadowColor.getCurrent(), true);
			
			int arrowSize = dc->getH()*3/4;
			if(m_Selection > 0)
				dc->renderArrow(0, (dc->getH()-arrowSize)/2, arrowSize, foregroundColor.getCurrent(), true);
			if(m_Selection < (m_Elements.size()-1))
				dc->renderArrow(dc->getW()-arrowSize/2, (dc->getH()-arrowSize)/2, arrowSize, foregroundColor.getCurrent(), false);
		}
		m_ThisInvalid = false;
	}
}

void CCombo::onFocus(bool focused)
{
	CFocusable::onFocus(focused);
	m_Highlighted = focused;
	invalidate();
}

void CCombo::onKeyboard(int keycode)
{
	switch(keycode) {
		case KEY_OK:
			if(m_NotifySelected)
				m_Environment->getEvents()->postEvent(this, MSG_SELECTED, m_Selection);
			break;
		case KEY_LEFT:
			setSelection(m_Selection-1);
			break;
		case KEY_RIGHT:
			setSelection(m_Selection+1);
			break;
		case KEY_UP:
			m_Focus->switchFocused(false);
			break;
		case KEY_DOWN:
			m_Focus->switchFocused(true);
			break;
	}
}

void CCombo::setFont(fontHandle font)
{
	m_Font = font;
	invalidate();
}

void CCombo::setFontSize(int size)
{
	m_FontSize = size;
	invalidate();
}

void CCombo::setShadow(int shadowX, int shadowY)
{
	m_ShadowX = shadowX;
	m_ShadowY = shadowY;
	invalidate();
}

void CCombo::setHighlighted(bool highlighted)
{
	/* highlighting disabled (driven by focus) */
}

void CCombo::setDisabled(bool disabled)
{
	CWidget::setDisabled(disabled);
	if(m_Disabled)
		m_Focus->unregisterFocusable(this);
	else
		m_Focus->registerFocusable(this);
}

void CCombo::setSelection(int selection)
{
	if(m_Elements.size() == 0) return;
	if(selection < 0) return;
	if(selection >= m_Elements.size()) return;
	m_Selection = selection;
	invalidate();
}

void CCombo::addElement(const string text)
{
	m_Elements.push_back(text);
	if(m_Elements.size() == 1)
		setSelection(0);
}
