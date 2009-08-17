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
#include <list>
#include <map>
#include <string>

using namespace std;

#include "fontrenderer.h"
#include "colorschema.h"
#include "fontschema.h"
#include "events.h"
#include "iconregistry.h"
#include "focus.h"
#include "screen.h"
#include "application.h"
#include "eventcallback.h"
#include "environment.h"

CEnvironment::CEnvironment(CApplicationFactory *applicationFactory, const string startupName, int param) :
	m_ApplicationFactory(applicationFactory),
	m_Destroying(false)
{
	m_FontRenderer = new CFontRenderer();
	m_ColorSchema = new CColorSchema();
	m_FontSchema = new CFontSchema();
	m_Events = new CEvents(this);
	m_IconRegistry = new CIconRegistry();
	m_Focus = new CFocus();
	m_Screen = NULL; /* Platform-dependent, must be initialized by the derived class ! */
	
	/* Starting the application must be done by the derived class as a valid screen is needed. */
}

CEnvironment::~CEnvironment()
{
	list<CApplication *>::const_iterator i;
	
	m_Destroying = true;
	for(i=m_RunningApplications.begin();i!=m_RunningApplications.end();i++)
		delete *i;

	delete m_Screen;
	delete m_Focus;
	delete m_IconRegistry;
	delete m_Events;
	delete m_FontSchema;
	delete m_ColorSchema;
	delete m_FontRenderer;
}

void CEnvironment::connectSender(void *sender, CEventCallback *eventCallback)
{
	m_ConnectedSenders[sender] = eventCallback;
}

void CEnvironment::disconnectSender(void *sender)
{
	map<void *, CEventCallback *>::iterator it;
	it = m_ConnectedSenders.find(sender);
	if(it != m_ConnectedSenders.end()) {
		delete it->second;
		m_ConnectedSenders.erase(it);
	}
}

void CEnvironment::processEvents()
{
	void *sender;
	int message, param1, param2;
	
	while(m_Events->getEvent(sender, message, param1, param2)) {
		if(message == MSG_PAINT)
			onPaint();
		else {
			CEventCallback *eventCallback;
			
			map<void *, CEventCallback *>::const_iterator it;
			it = m_ConnectedSenders.find(sender);
			if(it == m_ConnectedSenders.end())
				continue; /* no handler */
			eventCallback = it->second;
			
 			eventCallback->exec(message, param1, param2);
		}
	}
}

void CEnvironment::registerApplication(CApplication *application)
{
	m_RunningApplications.push_front(application);
}

void CEnvironment::unregisterApplication(CApplication *application)
{
	if(!m_Destroying)
		m_RunningApplications.remove(application);
}
