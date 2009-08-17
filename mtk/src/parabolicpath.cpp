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

#include "region.h"
#include "regionpath.h"
#include "regionpathgroup.h"
#include "parabolicpath.h"

CParabolicPath::CParabolicPath(CRegion *region, int x0, int y0, int x1, int y1, CRegionPathGroup *regionPathGroup) :
	m_Region(region),
	m_X0(x0),
	m_Y0(y0),
	m_X1(x1),
	m_Y1(y1),
	
	m_StepCount(0),
	m_Step(0)
{
	if(regionPathGroup != NULL) regionPathGroup->registerPath(this);
}

void CParabolicPath::start(int stepCount)
{
	m_StepCount = stepCount;
	m_Step = 0;
	
	/* Compute factors and initialize the evaluation algorithm
	 *
	 * If you do the math, you get :
	 * Linear interpolation x = ds + h
	 * d = (x1 - x0)/T
	 *
	 * Polynomial interpolation y = as^2 + bs + c
	 * a = 2*(y0-y1)/T^2
	 * b = -3*(y0-y1)/T
	 *
	 * from which we get
	 * u = 4*(y0-y1)/T^2
	 * v = (2 - 3*T)*(y0-y1)/T^2
	 *
	 * T^2 is a suitable scaling factor for the fractional parts.
	 */
	
	int T = m_StepCount-1;
	
	m_Scale = T*T;
	
	int temp;
	
	/* d = T*(x1 - x0)/T^2 */
	temp = T*(m_X1 - m_X0);
	m_Di = temp / m_Scale;
	m_Df = temp % m_Scale;
	
	/* u = 4*y1/T^2 */
	temp = 4*(m_Y0 - m_Y1);
	m_Ui = temp / m_Scale;
	m_Uf = temp % m_Scale;
	
	/* v = (2 - 3*T)*y1/T^2 */
	temp = (2 - 3*T)*(m_Y0 - m_Y1);
	m_Vi = temp / m_Scale;
	m_Vf = temp % m_Scale;
	
	/* Initial position is (X0, Y0)
	 * with no fractional part.
	 */
	m_Xi = m_X0;
	m_Xf = 0;
	m_Yi = m_Y0;
	m_Yf = 0;
	
	m_Region->setPosition(m_Xi, m_Yi);
}

bool CParabolicPath::step()
{
	if(m_Step < m_StepCount) {
		if(m_Step == (m_StepCount-1)) {
			m_Region->setPosition(m_X1, m_Y1);
			m_Step++;
			return false;
		} else {
			/* Linear interpolation */
			m_Xi += m_Di;
			m_Xf += m_Df;
			if(m_Xf > m_Scale/2) {
				m_Xi++;
				m_Xf -= m_Scale;
			}
			if(m_Xf < -m_Scale/2) {
				m_Xi--;
				m_Xf += m_Scale;
			}
			
			/* Polynomial interpolation */
			m_Yi += m_Ui*m_Step + m_Vi;
			m_Yf += m_Uf*m_Step + m_Vf;
			while(m_Yf > m_Scale/2) {
				m_Yi++;
				m_Yf -= m_Scale;
			}
			while(m_Yf < -m_Scale/2) {
				m_Yi--;
				m_Yf += m_Scale;
			}
			
			m_Region->setPosition(m_Xi, m_Yi);
			
			m_Step++;
			return true;
		}
	} else
		return false;
}
