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

#ifndef __FOCUS_H
#define __FOCUS_H

#include <vector>

using namespace std;

class CFocusable;

class CFocus {
	public:
		CFocus();
		
		/* Does not transfer ownership */
		void registerFocusable(CFocusable *focusable);
		void unregisterFocusable(CFocusable *focusable);
		
		int getFocusableCount() const { return m_Focusables.size(); }
		void setFocusOrder(CFocusable *focusable, int order);
		
		void setFocused(CFocusable *focusable);
		void switchFocused(bool next=true);
		CFocusable *getFocused() const { return m_Focusables[m_Focused]; }
		
		bool dispatchKeypress(int keycode);
	private:
		vector<CFocusable *> m_Focusables;
		int m_Focused;
};

#endif /* __FOCUS_H */
