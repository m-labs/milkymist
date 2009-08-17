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

#ifndef __FOCUSABLE_H
#define __FOCUSABLE_H

#include <cstddef>

class CFocus;
class CEvents;

class CFocusable {
	public:
		CFocusable(CFocus *focus, CEvents *events);
		virtual ~CFocusable();

		virtual void onFocus(bool focused);
		virtual void onKeyboard(int keycode);
		
		bool isFocused() const;
		
		void setNotifyFocus(bool notifyGainFocus, bool notifyLoseFocus, bool sendEvent=false);
		bool getNotifyGainFocus() const { return m_NotifyGainFocus; }
		bool getNotifyLoseFocus() const { return m_NotifyLoseFocus; }
	protected:
		CFocus *m_Focus;
		bool m_NotifyGainFocus;
		bool m_NotifyLoseFocus;
	private:
		CEvents *m_Events;
};

#endif /* __FOCUSABLE_H */
