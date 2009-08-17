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

#ifndef __EVENTS_H
#define __EVENTS_H

class CEnvironment;

enum {
	/*
	 * Positive message codes are reserved for MTK.
	 * Negative message codes are user defined.
	 */
	MSG_PAINT = 0,
	
	MSG_FOCUSGAINED,
	MSG_FOCUSLOST,
	
	MSG_SELECTED,
	
	MSG_TIMER
};

struct event {
	void *sender;
	int message;
	int param1;
	int param2;
};

class CEvents {
	public:
		CEvents(CEnvironment *environment, int length=128);
		~CEvents();
		
		void postEvent(void *sender, int message, int param1=0, int param2=0);
		bool getEvent(void *&sender, int &message, int &param1, int &param2);
		void purge(void *sender);
	private:
		CEnvironment *m_Environment;
		bool m_HasPaintEvent;
		
		int m_Length;
		bool m_Full;
		int m_Produce;
		int m_Consume;
		struct event *m_Queue;
};

#endif /* __EVENTS_H */
