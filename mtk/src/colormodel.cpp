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

#include "color.h"
#include "colorschema.h"
#include "colormodel.h"
#include "widget.h"

CColorModel::CColorModel(CWidget *widget, CColorSchema *colorSchema, int model) :
	m_Widget(widget)
{
	switch(model) {
		case COLORMODEL_BACKGROUND:
			m_Color = colorSchema->getWidgetBackground();
			m_ColorH = colorSchema->getWidgetBackgroundH();
			m_ColorD = colorSchema->getWidgetBackgroundD();
			break;
		case COLORMODEL_FOREGROUND:
			m_Color = colorSchema->getWidgetForeground();
			m_ColorH = colorSchema->getWidgetForegroundH();
			m_ColorD = colorSchema->getWidgetForegroundD();
			break;
		case COLORMODEL_SHADOW:
			m_Color = colorSchema->getWidgetForegroundShadow();
			m_ColorH = colorSchema->getWidgetForegroundShadowH();
			m_ColorD = colorSchema->getWidgetForegroundShadowD();
			break;
		case COLORMODEL_BORDER:
			m_Color = colorSchema->getBorder();
			m_ColorH = colorSchema->getBorderH();
			m_ColorD = colorSchema->getBorderD();
			break;
	}
}

color CColorModel::getCurrent() const
{
	if(m_Widget->getHighlighted()) return m_ColorH;
	if(m_Widget->getDisabled()) return m_ColorD;
	return m_Color;
}

void CColorModel::set(color c)
{
	m_Color = c;
	m_Widget->invalidate();
}

void CColorModel::setH(color c)
{
	m_ColorH = c;
	m_Widget->invalidate();
}

void CColorModel::setD(color c)
{
	m_ColorD = c;
	m_Widget->invalidate();
}
