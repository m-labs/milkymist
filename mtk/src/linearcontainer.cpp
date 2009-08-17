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
#include <cassert>

#include "color.h"
#include "dc.h"
#include "widget.h"
#include "linearcontainer.h"

CLinearContainer::CLinearContainer(CContainer *parent, int elements, bool vertical) :
	CContainer(parent),
	m_Vertical(vertical),
	m_Elements(elements),
	m_NextElement(0)
{
	int i;
	int defaultWidth;
	
	m_Widths = new int[m_Elements];
	m_Contents = new CWidget*[m_Elements];
	
	defaultWidth = -((1 << 10)/elements);
	for(i=0;i<m_Elements;i++) {
		m_Widths[i] = defaultWidth;
		m_Contents[i] = NULL;
	}
}

CLinearContainer::~CLinearContainer()
{
	int i;
	
	for(i=0;i<m_Elements;i++)
		if(m_Contents[i] != NULL)
			delete m_Contents[i];
	delete [] m_Contents;
	delete [] m_Widths;
}

void CLinearContainer::registerChild(CWidget *child)
{
	if(m_Contents[m_NextElement] != NULL)
		delete m_Contents[m_NextElement];
	m_Contents[m_NextElement] = child;
	m_NextElement++;
	if(m_NextElement == m_Elements) m_NextElement = 0;
	invalidateChildren();
}

void CLinearContainer::unregisterChild(CWidget *child)
{
	int i;
	
	for(i=0;i<m_Elements;i++)
		if(m_Contents[i] == child)
			m_Contents[i] = NULL;
	invalidateChildren();
}

void CLinearContainer::invalidateAll()
{
	int i;
	
	invalidate();
	invalidateChildren();
	for(i=0;i<m_Elements;i++)
		if(m_Contents[i]) m_Contents[i]->invalidateAll();
}

void CLinearContainer::paint(CDC *dc)
{
	m_ThisInvalid = false;
	if(m_ChildInvalid) {
		int i;
		int pos;
		int width;
		int proportional;
		int error;

		/* Compute the number of pixels used by all widgets
		 * whose width is specified in proportional units
		 * (1/1024ths of the width not used by fixed size widgets)
		 */
		proportional = m_Vertical ? dc->getH() : dc->getW();
		for(i=0;i<m_Elements;i++)
			if(m_Widths[i] > 0)
				proportional -= m_Widths[i];
		if(proportional < 0) proportional = 0;
		
		pos = 0;
		error = 0;
		for(i=0;i<m_Elements;i++) {
			if(i == m_Elements-1)
				width = (m_Vertical ? dc->getH() : dc->getW())-pos;
			else {
				if(m_Widths[i] < 0) {
					width =  (proportional*(-m_Widths[i])) >> 10;
					error += (proportional*(-m_Widths[i])) & (1024-1);
					if(error >= 512) {
						width++;
						error -= 1024;
					}
				}
				else
					width = m_Widths[i];
			}
			
			if(width > 0) {
				if(m_Vertical) {
					CDC childDC(dc, 0, pos, dc->getW(), width);
					
					if(m_Contents[i] != NULL)
						m_Contents[i]->paint(&childDC);
					else
						childDC.fillRect(0, 0, childDC.getW(), childDC.getH(), m_EmptyColor);
				} else {
					CDC childDC(dc, pos, 0, width, dc->getH());
			
					if(m_Contents[i] != NULL)
						m_Contents[i]->paint(&childDC);
					else
						childDC.fillRect(0, 0, childDC.getW(), childDC.getH(), m_EmptyColor);
				}
				
				pos += width;
			}
		}
		m_ChildInvalid = false;
	}
}

void CLinearContainer::setWidth(int element, int width)
{
	assert(element >= 0);
	assert(element < m_Elements);
	m_Widths[element] = width;
	invalidateAll();
}

void CLinearContainer::setVertical(bool vertical)
{
	m_Vertical = vertical;
	invalidateAll();
}

void CLinearContainer::setHighlighted(bool highlighted)
{
	int i;
	
	CContainer::setHighlighted(highlighted);
	for(i=0;i<m_Elements;i++)
		if(m_Contents[i])
			m_Contents[i]->setHighlighted(highlighted);
}

void CLinearContainer::setDisabled(bool disabled)
{
	int i;
	
	CContainer::setDisabled(disabled);
	for(i=0;i<m_Elements;i++)
		if(m_Contents[i])
			m_Contents[i]->setDisabled(disabled);
}
