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

#include "eventcallback.h"

CEventCallback::CEventCallback(void *instance, callbackType callback, int param0) :
	m_Instance(instance),
	m_Callback(callback),
	m_Param0(param0)
{
}

void CEventCallback::exec(int message, int param1, int param2)
{
	m_Callback(m_Instance, message, m_Param0, param1, param2);
}
