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

#ifndef __LANGUAGEAPP_H
#define __LANGUAGEAPP_H

#include <mtk.h>

class CLanguageApp : public CApplication {
	public:
		CLanguageApp(CEnvironment *environment, int param=0);
		~CLanguageApp();
		
		static void onLanguageSelected(void *_app, int message, int param0, int param1, int param2);
	private:
		CRegion *m_Region;
};

#endif /* __LANGUAGEAPP_H */
