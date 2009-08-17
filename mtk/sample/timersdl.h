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

#ifndef __TIMERSDL_H
#define __TIMERSDL_H

#include <SDL.h>
#include <mtk.h>

#define SDL_USER_EVENT_TIMER 1

class CTimerSDL: public CTimer {
	public:
		CTimerSDL(CEvents *events, int interval);
		~CTimerSDL();
	private:
		static Uint32 callback(Uint32 interval, void *param);
		SDL_TimerID m_ID;
};

#endif /* __TIMERSDL_H */
