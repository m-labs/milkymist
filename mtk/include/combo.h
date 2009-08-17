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

#ifndef __COMBO_H
#define __COMBO_H

#include <vector>
#include <string>

using namespace std;

#include "widget.h"
#include "container.h"
#include "focusable.h"
#include "fontrenderer.h"
#include "colormodel.h"

class CCombo: public CWidget, public CFocusable {
	public:
		CCombo(CContainer *parent);
		
		void paint(CDC *dc);
		
		void onFocus(bool focused);
		void onKeyboard(int keycode);
		
		void setFont(fontHandle font);
		fontHandle getFont() const { return m_Font; }
		
		void setFontSize(int size);
		int getFontSize() const { return m_FontSize; }
		
		void setShadow(int shadowX, int shadowY);
		int getShadowX() const { return m_ShadowX; }
		int getShadowY() const { return m_ShadowY; }
		
		CColorModel backgroundColor;
		CColorModel foregroundColor;
		CColorModel shadowColor;
		
		void setNotify(bool notifyChanged=false, bool notifySelected=true) {
			m_NotifyChanged = notifyChanged;
			m_NotifySelected = notifySelected;
		}
		bool getNotifyChanged() const { return m_NotifyChanged; }
		bool getNotifySelected() const { return m_NotifySelected; }
		
		void setHighlighted(bool highlighted);
		void setDisabled(bool disabled);
		
		void setSelection(int selection);
		int getSelection() const { return m_Selection; }
		
		void addElement(const string text);
	private:
		fontHandle m_Font;
		int m_FontSize;
		int m_ShadowX, m_ShadowY;
		
		int m_Selection;
		vector<string> m_Elements;
		
		bool m_NotifyChanged;
		bool m_NotifySelected;
};

#endif /* __COMBO_H */
