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

#include <libintl.h>
#include <mtk.h>

#include "menuapp.h"

#define _(STRING) gettext(STRING)

CMenuApp::CMenuApp(CEnvironment *environment, int param) :
	CApplication(environment, param)
{
	CScreen *screen = m_Environment->getScreen();
	CIconRegistry *iconRegistry = m_Environment->getIconRegistry();
	
	m_RegionBackground = screen->createRegion(0, 0, screen->getW(), screen->getH(), 1);
	CWindow *windowBackground = new CWindow(m_Environment, m_RegionBackground);
	new CLabel(windowBackground, "");
	
	m_RegionTV = createElement(screen->getW()/4-74, screen->getH()/5-64, "television", _("Watch TV"), new CEventCallback(this, onWatchTV), true);
	m_RegionApps = createElement(2*screen->getW()/4-74, screen->getH()/5-64, "applications", _("Applications"), new CEventCallback(this, onApplications));
	m_RegionPVR = createElement(3*screen->getW()/4-74, screen->getH()/5-64, "film", _("PVR"), new CEventCallback(this, onPVR));
	
	m_RegionChannels = createElement(screen->getW()/3-74, 3*screen->getH()/5-64, "magnify", _("Channel list"), new CEventCallback(this, onChannels));
	m_RegionConfigure = createElement(2*screen->getW()/3-74, 3*screen->getH()/5-64, "configure", _("Settings"), new CEventCallback(this, onConfigure));
	
	m_RegionPaths.start(20);
	m_Timer = m_Environment->createTimer(40);
	m_Environment->connectSender(m_Timer, new CEventCallback(this, onTimer));
}

CRegion *CMenuApp::createElement(int x, int y, const string icon, const string label, CEventCallback *callback, bool focus)
{
	CScreen *screen = m_Environment->getScreen();
	CIconRegistry *iconRegistry = m_Environment->getIconRegistry();
	CRegion *ret;
	
	ret = screen->createRegion(x, y, 148, 158, true, 1);
	CWindow *window = new CWindow(m_Environment, ret);
		
	CColumn *col = new CColumn(window, 2);
	col->setNextWidth(128);
	new CIcon(col, iconRegistry->getIcon(icon));
	
	CSelContainer *selContainer = new CSelContainer(col, m_Environment->getFocus());
	m_Environment->connectSender(selContainer, callback);
	new CLabel(selContainer, label, true);
	if(focus)
		m_Environment->getFocus()->setFocused(selContainer);
	
	new CParabolicPath(ret,
		(screen->getW() - ret->getW())/2, screen->getH() - ret->getH(),
		x, y,
		&m_RegionPaths);
	
	return ret;
}

void CMenuApp::onTimer(void *instance, int message, int param0, int param1, int param2)
{
	CMenuApp *app = (CMenuApp *)instance;
	
	if(app->m_RegionPaths.step())
		app->m_Environment->getEvents()->postEvent(app, MSG_PAINT);
}

void CMenuApp::onWatchTV(void *instance, int message, int param0, int param1, int param2)
{
	printf("Watch TV\n");
}

void CMenuApp::onApplications(void *instance, int message, int param0, int param1, int param2)
{
	printf("Applications\n");
}

void CMenuApp::onPVR(void *instance, int message, int param0, int param1, int param2)
{
	printf("PVR\n");
}

void CMenuApp::onChannels(void *instance, int message, int param0, int param1, int param2)
{
	printf("Channels\n");
}

void CMenuApp::onConfigure(void *instance, int message, int param0, int param1, int param2)
{
	printf("Configuration\n");
}

CMenuApp::~CMenuApp()
{
	delete m_Timer;
	delete m_RegionBackground;
	delete m_RegionTV;
	delete m_RegionApps;
	delete m_RegionPVR;
	delete m_RegionChannels;
	delete m_RegionConfigure;
}
