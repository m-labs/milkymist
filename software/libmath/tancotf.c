/*  tancotf.c: Computes tan or cot of a 32-bit float as outlined in [1]

    Copyright (C) 2001, 2002  Jesus Calvino-Fraga, jesusc@ieee.org 

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA */

/* [1] William James Cody and W.  M.  Waite.  _Software manual for the
   elementary functions_, Englewood Cliffs, N.J.:Prentice-Hall, 1980. */

/* Version 1.0 - Initial release */

/*
** $Id: tancotf.c 4776 2007-04-29 13:15:51Z borutr $
*/

#include <math.h>

#define P0  0.100000000E+1
#define P1 -0.958017723E-1
#define Q0  0.100000000E+1
#define Q1 -0.429135777E+0
#define Q2  0.971685835E-2

#define C1  1.5703125
#define C2  4.83826794897E-4

#define P(f,g) (P1*g*f+f)
#define Q(g) ((Q2*g+Q1)*g+Q0)

//A reasonable choice for YMAX is the integer part of B**(t/2)*PI/2:
#define YMAX 6433.0

float tancotf(const float x, const int iscotan)
{
    float f, g, xn, xnum, xden;
    int n;

    if (fabsf(x) > YMAX)
    {
        //errno = ERANGE;
        return 0.0;
    }

    /*Round x*2*PI to the nearest integer*/
    n=(x*TWO_O_PI+(x>0.0?0.5:-0.5)); /*works for +-x*/
    xn=n;

    xnum=(int)x;
    xden=x-xnum;
    f=((xnum-xn*C1)+xden)-xn*C2;

    if (fabsf(f) < EPS)
    {
        xnum = f;
        xden = 1.0;
    }
    else
    {
        g = f*f;
        xnum = P(f,g);
        xden = Q(g);
    }

    if(n&1)
    //xn is odd
    {
        if(iscotan) return (-xnum/xden);
               else return (-xden/xnum);
    }
    else
    {
        if(iscotan) return (xden/xnum);
               else return (xnum/xden);
    }
}

