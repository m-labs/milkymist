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

#ifndef __REGION_H
#define __REGION_H

#include "color.h"

class CScreen;
class CWidget;

class CRegion {
	public:
		CRegion(CScreen *screen, int x, int y, int w, int h, bool visible, int z, int alpha, int blur);
		virtual ~CRegion();
		
		int getX() const { return m_X; }
		int getY() const { return m_Y; }
		int getW() const { return m_W; }
		int getH() const { return m_H; }
		
		void setPosition(int x, int y);
		
		bool getVisible() const { return m_Visible; }
		int getZ() const { return m_Z; }
		int getAlpha() const { return m_Alpha; }
		int getBlur() const { return m_Blur; }
		
		void setVisible(bool visible);
		void setZ(int z);
		void setAlpha(int alpha);
		void setBlur(int blur);
		
		virtual color *getFramebuffer() const=0;
		
		CWidget *getTopWidget() const { return m_TopWidget; }
		/* transfers ownership to the region.
		 * if NULL, the previous widget is not freed.
		 */
		void setTopWidget(CWidget *widget);
	protected:
		CScreen *m_Screen;
		int m_W, m_H;
	protected:
		friend class CScreen;
		int m_X, m_Y;
		bool m_Visible;
		int m_Z;
		int m_Alpha;
		int m_Blur;
	private:
		CWidget *m_TopWidget;
};

#endif /* __CREGION_H */
