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

#ifndef __ENVIRONMENT_H
#define __ENVIRONMENT_H

#include <map>
#include <list>
#include <string>

using namespace std;

#include "applicationfactory.h"
#include "eventcallback.h"

class CFontRenderer;
class CColorSchema;
class CFontSchema;
class CEvents;
class CFocus;
class CTimer;
class CIconRegistry;
class CScreen;

class CEnvironment {
	public:
		CEnvironment(CApplicationFactory *applicationFactory, const string startupName, int startupParam=0);
		virtual ~CEnvironment();
		
		/* called by processEvents() when a paint event is received */
		virtual void onPaint()=0;
		/* implement here the main loop of the GUI thread */
		virtual void main()=0;
		
		void connectSender(void *sender, CEventCallback *eventCallback);
		/* Called by the event manager when a sender is destroyed, and also available to applications.
		 * When it is destroyed, the application is responsible for disconnecting from all
		 * senders it is connected to. In most cases, this is implemented implicitly as the
		 * application automatically destroys all its senders.
		 */
		void disconnectSender(void *sender);
		
		CApplication *createApplication(const string name, int param=0) { return m_ApplicationFactory->createApplication(this, name, param); }
		
		virtual CTimer *createTimer(int interval)=0;
		
		/* Called by the application object */
		void registerApplication(CApplication *application);
		void unregisterApplication(CApplication *application);
		
		CFontRenderer *getFontRenderer() const { return m_FontRenderer; }
		CColorSchema *getColorSchema() const { return m_ColorSchema; }
		CFontSchema *getFontSchema() const { return m_FontSchema; }
		CEvents *getEvents() const { return m_Events; }
		CIconRegistry *getIconRegistry() const { return m_IconRegistry; }
		CFocus *getFocus() const { return m_Focus; }
		CScreen *getScreen() const { return m_Screen; }
	protected:
		/* should be called by main() after GUI operations */
		void processEvents();
	
		CFontRenderer *m_FontRenderer;
		CColorSchema *m_ColorSchema;
		/* fonts are loaded using the font renderer,
		 * and entered into m_FontSchema by platform-specific derived classes */
		CFontSchema *m_FontSchema;
		CEvents *m_Events;
		CIconRegistry *m_IconRegistry;
		CFocus *m_Focus;
		/* m_Screen is initialized by platform-specific derived classes */
		CScreen *m_Screen;
		/* The derived class must have access to the application factory
		 * to create the startup application once it has initialized the screen.
		 */
		CApplicationFactory *m_ApplicationFactory;
	private:
		map<void *, CEventCallback *> m_ConnectedSenders;
		list<CApplication *> m_RunningApplications;
		bool m_Destroying;
};

#endif /* __ENVIRONMENT_H */
