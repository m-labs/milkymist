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

#ifndef __CONTAINER_H
#define __CONTAINER_H

#include "color.h"
#include "widget.h"

class CContainer : public CWidget {
	public:
		CContainer(CContainer *parent);
		CContainer(CEnvironment *environment);
		
		/* transfers ownership to the container */
		virtual void registerChild(CWidget *child)=0;
		/* takes back ownership from the container */
		virtual void unregisterChild(CWidget *child)=0;
		
		/* areas of this container itself must be redrawn */
		virtual void invalidate();
		/* areas of a child of this container must be redrawn */
		virtual void invalidateChildren();
		/* this container and all its children (recursively) must be redrawn */
		virtual void invalidateAll()=0;
		
		/* the color to display where there are missing children */
		void setEmptyColor(color c);
		color getEmptyColor() const { return m_EmptyColor; }
	protected:
		bool m_ChildInvalid; /* one or more children have invalid areas (but not necessarily this widget) */
		color m_EmptyColor;
};

#endif /* __CONTAINER_H */
