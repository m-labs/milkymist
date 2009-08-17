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

#include <cassert>
#include <cstddef>

#include "events.h"
#include "environment.h"

CEvents::CEvents(CEnvironment *environment, int length) :
	m_Environment(environment),
	m_HasPaintEvent(false),

	m_Length(length),
	m_Full(false),
	m_Produce(0),
	m_Consume(0)
{
	m_Queue = new struct event[m_Length];
}

CEvents::~CEvents()
{
	delete [] m_Queue;
}

void CEvents::postEvent(void *sender, int message, int param1, int param2)
{
	if(message == MSG_PAINT) {
		m_HasPaintEvent = true;
		return;
	}
	
	assert(!m_Full);
	m_Queue[m_Produce].sender = sender;
	m_Queue[m_Produce].message = message;
	m_Queue[m_Produce].param1 = param1;
	m_Queue[m_Produce].param2 = param2;
	m_Produce++;
	if(m_Produce == m_Length)
		m_Produce = 0;
	if(m_Produce == m_Consume)
		m_Full = true;
}

bool CEvents::getEvent(void *&sender, int &message, int &param1, int &param2)
{
	if((!m_Full) && (m_Produce == m_Consume)) {
		if(m_HasPaintEvent) {
			sender = NULL;
			message = MSG_PAINT;
			m_HasPaintEvent = false;
			return true;
		}
		return false;
	}
	
	sender = m_Queue[m_Consume].sender;
	message = m_Queue[m_Consume].message;
	param1 = m_Queue[m_Consume].param1;
	param2 = m_Queue[m_Consume].param2;
	m_Consume++;
	if(m_Consume == m_Length)
		m_Consume = 0;
	m_Full = false;
	
	return true;
}

void CEvents::purge(void *sender)
{
	bool first;
	int i;
	
	m_Environment->disconnectSender(sender);
	
	first = m_Full;
	i = m_Consume;
	while((i != m_Produce) || first) {
		if(m_Queue[i].sender == sender) {
			int source, destination;
			
			source = i;
			while(source != m_Produce) {
				destination = source;
				
				source++;
				if(source == m_Length)
					source = 0;
				
				m_Queue[destination] = m_Queue[source];
			}
			
			if(m_Produce > 0)
				m_Produce--;
			else
				m_Produce = m_Length-1;
		} else {
			i++;
			if(i == m_Length) i = 0;
		}
		first = false;
	}
}
