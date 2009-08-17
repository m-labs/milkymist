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

#include <list>

using namespace std;

#include "regionpath.h"
#include "regionpathgroup.h"

CRegionPathGroup::~CRegionPathGroup()
{
	list<CRegionPath *>::const_iterator i;
	
	for(i=m_RegionPaths.begin();i!=m_RegionPaths.end();i++)
		delete *i;
}

void CRegionPathGroup::registerPath(CRegionPath *regionPath)
{
	m_RegionPaths.insert(m_RegionPaths.begin(), regionPath);
}

void CRegionPathGroup::start(int stepCount)
{
	list<CRegionPath *>::const_iterator i;
	
	for(i=m_RegionPaths.begin();i!=m_RegionPaths.end();i++)
		(*i)->start(stepCount);
}

bool CRegionPathGroup::step()
{
	list<CRegionPath *>::const_iterator i;
	bool r;
	
	for(i=m_RegionPaths.begin();i!=m_RegionPaths.end();i++)
		r = (*i)->step();

	return r;
}
