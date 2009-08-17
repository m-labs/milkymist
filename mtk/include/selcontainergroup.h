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

#ifndef __SELCONTAINERGROUP_H
#define __SELCONTAINERGROUP_H

#include "eventcallback.h"

class CContainer;
class CEnvironment;
class CSelContainer;

class CSelContainerGroup {
	public:
		CSelContainerGroup(CEnvironment *environment, CContainer *container);
		
		CSelContainer *create(CEventCallback *eventCallback);
		void focusFirst();
	private:
		CEnvironment *m_Environment;
		CContainer *m_Container;
		CSelContainer *m_First;
};

#endif /* __SELCONTAINERGROUP_H */
