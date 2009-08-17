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

#ifndef __FONTSCHEMA_H
#define __FONTSCHEMA_H

#include "fontrenderer.h"

#define DEDICATED_CHINESE_FONT

class CFontSchema {
	public:
		CFontSchema();
		
		void setGeneralFont(fontHandle font, int size) { m_GeneralFont = font; m_GeneralFontSize = size; }
		fontHandle getGeneralFont() const { return m_GeneralFont; }
		int getGeneralFontSize() const { return m_GeneralFontSize; }
		
		void setIconFont(fontHandle font, int size) { m_IconFont = font; m_IconFontSize = size; }
		fontHandle getIconFont() const { return m_IconFont; }
		int getIconFontSize() const { return m_IconFontSize; }
		
		void setTitleFont(fontHandle font, int size) { m_TitleFont = font; m_TitleFontSize = size; }
		fontHandle getTitleFont() const { return m_TitleFont; }
		int getTitleFontSize() const { return m_TitleFontSize; }
		
		void setFixedFont(fontHandle font) { m_FixedFont = font; }
		fontHandle getFixedFont() const { return m_FixedFont; }
		
#ifdef DEDICATED_CHINESE_FONT
		void setChineseFont(fontHandle font) { m_ChineseFont = font; }
		fontHandle getChineseFont() const { return m_ChineseFont; }
#endif
	private:
		fontHandle m_GeneralFont;
		int m_GeneralFontSize;
		
		fontHandle m_IconFont;
		int m_IconFontSize;
		
		fontHandle m_TitleFont;
		int m_TitleFontSize;
		
		fontHandle m_FixedFont;
#ifdef DEDICATED_CHINESE_FONT
		fontHandle m_ChineseFont;
#endif
};

#endif /* __FONTSCHEMA_H */
