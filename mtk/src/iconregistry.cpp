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

using namespace std;

#include "imageloader.h"
#include "iconregistry.h"

CIconRegistry::CIconRegistry()
{
}

CIconRegistry::~CIconRegistry()
{
	map<string, CImageLoader *>::const_iterator it;
	for(it=m_Icons.begin();it!=m_Icons.end();it++)
		delete it->second;
}

void CIconRegistry::registerIcon(string name, CImageLoader *icon)
{
	map<string, CImageLoader *>::iterator it;
	it = m_Icons.find(name);
	if(it != m_Icons.end()) {
		delete it->second;
		if(icon == NULL) m_Icons.erase(it);
	}
	if(icon != NULL)
		m_Icons[name] = icon;
}

void CIconRegistry::unregisterIcon(string name)
{
	m_Icons.erase(m_Icons.find(name));
}

CImageLoader *CIconRegistry::getIcon(string name)
{
	map<string, CImageLoader *>::const_iterator it;
	it = m_Icons.find(name);
	if(it == m_Icons.end()) return NULL;
	return it->second;
}
