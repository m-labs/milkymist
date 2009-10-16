/*  asincosf.c: Computes asin or acos of a 32-bit float as outlined in [1]

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
** $Id: asincosf.c 4776 2007-04-29 13:15:51Z borutr $
*/


#include <math.h>

#define P1  0.933935835E+0
#define P2 -0.504400557E+0
#define Q0  0.560363004E+1
#define Q1 -0.554846723E+1
#define Q2  0.100000000E+1

#define P(g) (P2*g+P1)
#define Q(g) ((Q2*g+Q1)*g+Q0)

float asincosf(const float x, const int isacos)
{
    float y, g, r;
    int i;

    static const float a[2]={ 0.0, QUART_PI };
    static const float b[2]={ HALF_PI, QUART_PI };

    y=fabsf(x);
    i=isacos;
    if (y < EPS) r=y;
    else
    {
        if (y > 0.5)
        {
            i=1-i;
            if (y > 1.0)
            {
                //errno=EDOM;
                return 0.0;
            }
            g=(0.5-y)+0.5;
            g=ldexpf(g,-1);
            y=sqrtf(g);
            y=-(y+y);
        }
        else
        {
            g=y*y;
        }
        r=y+y*((P(g)*g)/Q(g));
    }
    if (isacos)
    {
        if (x < 0.0)
            r=(b[i]+r)+b[i];
        else
            r=(a[i]-r)+a[i];
    }
    else
    {
        r=(a[i]+r)+a[i];
        if (x<0.0) r=-r;
    }
    return r;
}
