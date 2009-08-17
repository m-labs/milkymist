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

#ifndef __ICONREGISTRY_H
#define __ICONREGISTRY_H

#include <string>
#include <map>

using namespace std;

class CImageLoader;

class CIconRegistry {
	public:
		CIconRegistry();
		~CIconRegistry();
		
		/* transfers ownership of the image loader to the icon registry */
		void registerIcon(string name, CImageLoader *icon);
		/* takes ownership of the image loader from the icon registry */
		void unregisterIcon(string name);
		
		CImageLoader *getIcon(string name);
	private:
		map<string, CImageLoader *> m_Icons;
};

#endif /* __ICONREGISTRY_H */
