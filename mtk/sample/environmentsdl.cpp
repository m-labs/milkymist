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
#include <string>
#include <SDL.h>
#include <libintl.h>
#include <locale.h>
#include <mtk.h>

using namespace std;

#include "timersdl.h"
#include "environmentsdl.h"
#include "regionpurefb.h"
#include "screenpurefb.h"

CEnvironmentSDL::CEnvironmentSDL(int screenW, int screenH, CApplicationFactory *applicationFactory, const string startupName, int startupParam) :
	CEnvironment(applicationFactory, startupName, startupParam)
{
	/* Initialize gettext */
	bindtextdomain("sample", RESOURCEDIR"/locale");
	textdomain("sample");
	
	/* Initialize SDL */
	m_SDLScreen = NULL;
	
	if(SDL_Init(SDL_INIT_VIDEO|SDL_INIT_TIMER) != 0) {
		fprintf(stderr, "Unable to initialize SDL: %s\n", SDL_GetError());
		return;
	}
	
	m_SDLScreen = SDL_SetVideoMode(screenW, screenH, 16, SDL_DOUBLEBUF);
	if(m_SDLScreen == NULL) {
		fprintf(stderr, "Unable to set video mode: %s\n", SDL_GetError());
		return;
	}
	
	char buffer[64];
	sprintf(buffer, "MTK Test Window (SDL) - %dx%d", screenW, screenH);
	SDL_WM_SetCaption(buffer, "");
	
	/* Load resources */
	m_MyFont = m_FontRenderer->loadFont(RESOURCEDIR"/FreeSans.ttf");
	m_ChineseFont = m_FontRenderer->loadFont(RESOURCEDIR"/gkai00mp.ttf");
	m_FontSchema->setGeneralFont(m_MyFont, 20);
	m_FontSchema->setFixedFont(m_MyFont);
	m_FontSchema->setIconFont(m_MyFont, 28);
	m_FontSchema->setTitleFont(m_MyFont, 30);
	m_FontSchema->setChineseFont(m_ChineseFont);
	
	m_IconRegistry->registerIcon("question", new CPNGLoader(RESOURCEDIR"/system-help.png"));
	
	m_IconRegistry->registerIcon("television", new CPNGLoader(RESOURCEDIR"/television.png"));
	m_IconRegistry->registerIcon("applications", new CPNGLoader(RESOURCEDIR"/applications.png"));
	m_IconRegistry->registerIcon("film", new CPNGLoader(RESOURCEDIR"/film.png"));
	m_IconRegistry->registerIcon("magnify", new CPNGLoader(RESOURCEDIR"/magnify.png"));
	m_IconRegistry->registerIcon("configure", new CPNGLoader(RESOURCEDIR"/configure.png"));
	
	/* Create screen and run the application */
	m_Screen = new CScreenPureFB((color *)m_SDLScreen->pixels, screenW, screenH, m_FontRenderer);
	m_ApplicationFactory->createApplication(this, startupName, startupParam);
}

CEnvironmentSDL::~CEnvironmentSDL()
{
	m_FontRenderer->unloadFont(m_MyFont);
	m_FontRenderer->unloadFont(m_ChineseFont);
	
	if(m_SDLScreen != NULL)
		SDL_Quit();
}

void CEnvironmentSDL::onPaint()
{
	SDL_LockSurface(m_SDLScreen);
	m_Screen->paint();
	m_Screen->compose();
	SDL_UnlockSurface(m_SDLScreen);
	SDL_Flip(m_SDLScreen);
}

void CEnvironmentSDL::main()
{
	SDL_Event sdlEvent;
	
	while(1) {
		SDL_WaitEvent(&sdlEvent);
		
		do {
			if(sdlEvent.type == SDL_QUIT) return; /* FIXME: free application */
			if(sdlEvent.type == SDL_KEYDOWN) {
				switch(sdlEvent.key.keysym.sym) {
					case SDLK_RETURN:
						m_Focus->dispatchKeypress(KEY_OK);
						break;
					case SDLK_LEFT:
						m_Focus->dispatchKeypress(KEY_LEFT);
						break;
					case SDLK_RIGHT:
						m_Focus->dispatchKeypress(KEY_RIGHT);
						break;
					case SDLK_UP:
						m_Focus->dispatchKeypress(KEY_UP);
						break;
					case SDLK_DOWN:
						m_Focus->dispatchKeypress(KEY_DOWN);
						break;
					case SDLK_ESCAPE:
						m_Focus->dispatchKeypress(KEY_EXIT);
						break;
				}
			}
			if(sdlEvent.type == SDL_USEREVENT) {
				if(sdlEvent.user.code == SDL_USER_EVENT_TIMER)
					m_Events->postEvent(sdlEvent.user.data1, MSG_TIMER);
			}
		} while(SDL_PollEvent(&sdlEvent));
		
		processEvents();
	}
}

CTimer *CEnvironmentSDL::createTimer(int interval)
{
	return new CTimerSDL(m_Events, interval);
}
