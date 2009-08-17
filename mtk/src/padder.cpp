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

#include <cassert>
#include <map>

#include "color.h"
#include "environment.h"
#include "colorschema.h"
#include "colormodel.h"
#include "dc.h"
#include "padder.h"

CPadder::CPadder(CContainer *parent, int borderR, int borderT, int borderL, int borderB) :
	CContainer(parent),
	
	borderColor(this, m_Environment->getColorSchema(), COLORMODEL_BORDER),

	m_BorderR(borderR),
	m_BorderT(borderT),
	m_BorderL(borderL),
	m_BorderB(borderB),
	
	m_Contents(NULL)
{
}

CPadder::~CPadder()
{
	if(m_Contents) delete m_Contents;
}

void CPadder::registerChild(CWidget *child)
{
	if(m_Contents) delete m_Contents;
	m_Contents = child;
	invalidateChildren();
}

void CPadder::unregisterChild(CWidget *child)
{
	assert(m_Contents == child);
	m_Contents = NULL;
	invalidateChildren();
}

void CPadder::invalidateAll()
{
	invalidate();
	invalidateChildren();
	if(m_Contents) m_Contents->invalidateAll();
}

void CPadder::paint(CDC *dc)
{
	int widthR;
	int widthT;
	int widthL;
	int widthB;
	color c;
	
	if(m_BorderR < 0)
		widthR = (dc->getW()*(-m_BorderR)) >> 10;
	else
		widthR = m_BorderR;

	if(m_BorderL < 0)
		widthL = (dc->getW()*(-m_BorderL)) >> 10;
	else
		widthL = m_BorderL;

	if(m_BorderT < 0)
		widthT = (dc->getH()*(-m_BorderT)) >> 10;
	else
		widthT = m_BorderT;

	if(m_BorderB < 0)
		widthB = (dc->getH()*(-m_BorderB)) >> 10;
	else
		widthB = m_BorderB;

	c = borderColor.getCurrent();
	if(m_ThisInvalid) {
		/* Draw the borders */
		m_ThisInvalid = false;
		dc->fillRect(0, 0, widthL, dc->getH(), c);
		dc->fillRect(dc->getW()-widthR, 0, widthR, dc->getH(), c);
		dc->fillRect(widthL, 0, dc->getW()-widthL, widthT, c);
		dc->fillRect(widthL, dc->getH()-widthB, dc->getW()-widthL, widthB, c);
	}
	
	if(m_ChildInvalid) {
		/* Draw the child */
		m_ChildInvalid = false;
		CDC childDC(
			dc,
			widthL,
			widthT,
			dc->getW()-widthL-widthR,
			dc->getH()-widthT-widthB
		);
		if(m_Contents)
			m_Contents->paint(&childDC);
		else
			childDC.fillRect(0, 0, childDC.getW(), childDC.getH(), m_EmptyColor);
	}
}

void CPadder::setBorders(int borderR, int borderT, int borderL, int borderB)
{
	m_BorderR = borderR;
	m_BorderT = borderT;
	m_BorderL = borderL;
	m_BorderB = borderB;
	invalidateAll();
}

void CPadder::setHighlighted(bool highlighted)
{
	CContainer::setHighlighted(highlighted);
	if(m_Contents) m_Contents->setHighlighted(highlighted);
}

void CPadder::setDisabled(bool disabled)
{
	CContainer::setDisabled(disabled);
	if(m_Contents) m_Contents->setDisabled(disabled);
}
