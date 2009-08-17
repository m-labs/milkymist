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

#include "container.h"
#include "environment.h"
#include "events.h"
#include "focus.h"
#include "eventcallback.h"
#include "selcontainer.h"
#include "selcontainergroup.h"

CSelContainerGroup::CSelContainerGroup(CEnvironment *environment, CContainer *container) :
	m_Environment(environment),
	m_Container(container),
	m_First(NULL)
{
}

CSelContainer *CSelContainerGroup::create(CEventCallback *eventCallback)
{
	CSelContainer *ret = new CSelContainer(m_Container, m_Environment->getFocus());
	m_Environment->connectSender(ret, eventCallback);
	if(m_First == NULL) m_First = ret;
	return ret;
}

void CSelContainerGroup::focusFirst()
{
	if(m_First != NULL)
		m_Environment->getFocus()->setFocused(m_First);
}
