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

#ifndef __PARABOLICPATH_H
#define __PARABOLICPATH_H

#include "regionpath.h"

class CRegion;
class CRegionPathGroup;

class CParabolicPath : public CRegionPath {
	public:
		CParabolicPath(CRegion *region, int x0, int y0, int x1, int y1, CRegionPathGroup *regionPathGroup=NULL);
		
		void start(int stepCount);
		bool step();
	private:
		CRegion *m_Region;
		
		int m_X0, m_Y0;
		int m_X1, m_Y1;
		
		/* We use a Bresenham-like algorithm to compute the positions.
		 * There are two interpolations, for each coordinate :
		 *
		 * Linear interpolation :
		 * m_Step(s): 0    -> m_StepCount-1(T)
		 * x        : m_X0 -> m_X1
		 *
		 * Polynomial interpolation of degree 2 :
		 * m_Step(s): 0    -> m_StepCount-1(T)
		 * y        : m_Y0 -> m_Y1
		 * with an extremum at -b/2a = 3*T/4
		 */
		
		/* line x = ds + h
		 * when step increments, we add d to x
		 */
		int m_Di; /* integer part */
		int m_Df; /* fractional part, scaled */
		
		/* conic section y = as^2 + bs + c
		 * when step increments, we add
		 * 2as + a + b to y
		 * let u = 2a and v = a+b
		 * we get y + us + v -> y
		 */
		int m_Ui, m_Vi; /* integer parts */
		int m_Uf, m_Vf; /* fractional parts, scaled */
		
		/* current position */
		int m_Xi, m_Yi; /* integer part */
		int m_Xf, m_Yf; /* fractional part, scaled */
		
		int m_Scale; /* used on all fractional parts */
		
		int m_StepCount, m_Step;
};

#endif /* __PARABOLICPATH_H */
