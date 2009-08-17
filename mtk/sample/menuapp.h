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

#ifndef __MENUAPP_H
#define __MENUAPP_H

#include <string>
#include <mtk.h>
#include "timer.h"

using namespace std;

class CMenuApp : public CApplication {
	public:
		CMenuApp(CEnvironment *environment, int param);
		~CMenuApp();
	private:
		CRegion *m_RegionBackground;
		
		CRegion *createElement(int x, int y, const string icon, const string label, CEventCallback *callback, bool focus=false);
		
		CRegion *m_RegionTV;
		CRegion *m_RegionApps;
		CRegion *m_RegionPVR;
		CRegion *m_RegionChannels;
		CRegion *m_RegionConfigure;
		
		CRegionPathGroup m_RegionPaths;
		CTimer *m_Timer;
		
		static void onTimer(void *instance, int message, int param0, int param1, int param2);
		
		static void onWatchTV(void *instance, int message, int param0, int param1, int param2);
		static void onApplications(void *instance, int message, int param0, int param1, int param2);
		static void onPVR(void *instance, int message, int param0, int param1, int param2);
		static void onChannels(void *instance, int message, int param0, int param1, int param2);
		static void onConfigure(void *instance, int message, int param0, int param1, int param2);
};

#endif /* __MENUAPP_H */
