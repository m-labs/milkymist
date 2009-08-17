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

#ifndef __PADDER_H
#define __PADDER_H

#include "color.h"
#include "colormodel.h"
#include "widget.h"
#include "container.h"

class CPadder : public CContainer {
	public:
		CPadder(CContainer *parent, int borderR=1, int borderT=1, int borderL=1, int borderB=1);
		~CPadder();
		
		void registerChild(CWidget *child);
		void unregisterChild(CWidget *child);
		
		void invalidateAll();
		
		void paint(CDC *dc);
	
		void setBorders(int borderR, int borderT, int borderL, int borderB);
		int getBorderR() const { return m_BorderR; }
		int getBorderT() const { return m_BorderT; }
		int getBorderL() const { return m_BorderL; }
		int getBorderB() const { return m_BorderB; }
		
		void setHighlighted(bool highlighted);
		void setDisabled(bool disabled);
		
		CColorModel borderColor;
	private:
		int m_BorderR;
		int m_BorderT;
		int m_BorderL;
		int m_BorderB;
		CWidget *m_Contents;
};

#endif /* __PADDER_H */
