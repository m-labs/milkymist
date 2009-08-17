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

#ifndef __SELCONTAINER_H
#define __SELCONTAINER_H

#include "widget.h"
#include "container.h"
#include "focusable.h"

class CSelContainer : public CContainer, public CFocusable {
	public:
		CSelContainer(CContainer *parent, CFocus *focus);
		~CSelContainer();
		
		void registerChild(CWidget *child);
		void unregisterChild(CWidget *child);
		
		void invalidateAll();
		
		void paint(CDC *dc);
		
		void onFocus(bool focused);
		void onKeyboard(int keycode);
		
		void setNotify(bool notifySelected) { m_NotifySelected = notifySelected; }
		bool getNotifySelected() const { return m_NotifySelected; }
		
		void setHighlighted(bool highlighted);
		void setDisabled(bool disabled);
	private:
		CWidget *m_Contents;
		bool m_NotifySelected;
};

#endif /* __SELCONTAINER_H */
