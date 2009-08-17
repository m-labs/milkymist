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

#ifndef __LINEARCONTAINER_H
#define __LINEARCONTAINER_H

#include <cassert>

#include "color.h"
#include "widget.h"
#include "container.h"

class CDC;

class CLinearContainer : public CContainer {
	public:
		CLinearContainer(CContainer *parent, int elements, bool vertical);
		virtual ~CLinearContainer();
		
		int getElementCount() const { return m_Elements; }
		
		void setNextPosition(int element) { m_NextElement = element; }
		CWidget *getElement(int element) const {
			assert(element >= 0);
			assert(element < m_Elements);
			return m_Contents[element];
		}
		void registerChild(CWidget *child);
		void unregisterChild(CWidget *child);
		
		void invalidateAll();
		
		void paint(CDC *dc);
		
		void setWidth(int element, int width);
		void setNextWidth(int width) { setWidth(m_NextElement, width); }
		int getWidth(int element) const {
			assert(element >= 0);
			assert(element < m_Elements);
			return m_Widths[element];
		}
		
		void setVertical(bool vertical);
		bool getVertical() const { return m_Vertical; }
		
		virtual void setHighlighted(bool highlighted);
		virtual void setDisabled(bool disabled);
	protected:
		bool m_Vertical;
		int m_Elements;
		int m_NextElement;
		int *m_Widths;
		CWidget **m_Contents;
};

class CRow : public CLinearContainer {
	public:
		CRow(CContainer *parent, int elements) : CLinearContainer(parent, elements, false) {}
};

class CColumn : public CLinearContainer {
	public:
		CColumn(CContainer *parent, int elements) : CLinearContainer(parent, elements, true) {}
};

#endif /* __LINEARCONTAINER_H */
