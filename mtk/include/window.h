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

#ifndef __WINDOW_H
#define __WINDOW_H

#include "widget.h"
#include "container.h"

class CRegion;
class CEvents;
class CDC;

class CWindow : public CContainer {
	public:
		CWindow(CEnvironment *environment, CRegion *region);
		~CWindow();
	
		void invalidateAll();
	
		void registerChild(CWidget *child);
		void unregisterChild(CWidget *child);
		void paint(CDC *dc);
		
		void setHighlighted(bool highlighted);
		void setDisabled(bool disabled);
	private:
		CRegion *m_Region;
		CWidget *m_Contents;
};

#endif /* __WINDOW_H */

