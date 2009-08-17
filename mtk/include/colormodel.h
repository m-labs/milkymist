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

#ifndef __COLORMODEL_H
#define __COLORMODEL_H

#include "color.h"

class CColorSchema;
class CWidget;

enum {
	COLORMODEL_BACKGROUND,
	COLORMODEL_FOREGROUND,
	COLORMODEL_SHADOW,
	COLORMODEL_BORDER,
};

class CColorModel {
	public:
		CColorModel(CWidget *widget, CColorSchema *colorSchema, int model);
		
		color getCurrent() const;
		
		void set(color c);
		color get() const { return m_Color; }
		void setH(color c);
		color getH() const { return m_ColorH; }
		void setD(color c);
		color getD() const { return m_ColorD; }
	private:
		int m_Model;
		CWidget *m_Widget;
		color m_Color;
		color m_ColorH;
		color m_ColorD;
};

#endif /* __BACKGROUNDCOLOR_H */
