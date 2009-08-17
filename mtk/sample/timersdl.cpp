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

#include <SDL.h>
#include <mtk.h>

#include "timersdl.h"

CTimerSDL::CTimerSDL(CEvents *events, int interval) :
	CTimer(events, interval)
{
	m_ID = SDL_AddTimer(interval, callback, this);
}

CTimerSDL::~CTimerSDL()
{
	SDL_RemoveTimer(m_ID);
}

Uint32 CTimerSDL::callback(Uint32 interval, void *param)
{
	SDL_Event event;
	
	event.type = SDL_USEREVENT;
	event.user.code = SDL_USER_EVENT_TIMER;
	event.user.data1 = param;
	SDL_PushEvent(&event);
	
	return interval;
}
