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

#ifndef __LABEL_H
#define __LABEL_H

#include <string>

#include "color.h"
#include "widget.h"
#include "fontrenderer.h"
#include "colormodel.h"

using namespace std;

class CDC;

class CLabel : public CWidget {
	public:
		CLabel(CContainer *parent, const string text, bool m_Center=false);
		
		void paint(CDC *dc);
		
		void setText(const string text);
		const string getText() const { return m_Text; }
		
		void setFont(fontHandle font);
		fontHandle getFont() const { return m_Font; }
		
		void setFontSize(int size);
		int getFontSize() const { return m_FontSize; }
		
		void setShadow(int shadowX, int shadowY);
		int getShadowX() const { return m_ShadowX; }
		int getShadowY() const { return m_ShadowY; }
		
		void setCenter(bool center);
		bool getCenter() const { return m_Center; }
		
		CColorModel backgroundColor;
		CColorModel foregroundColor;
		CColorModel shadowColor;
	private:
		fontHandle m_Font;
		int m_FontSize;
		int m_ShadowX, m_ShadowY;
		bool m_Center;
		string m_Text;
};

#endif /* __LABEL_H */
