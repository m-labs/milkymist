/*  atan2f.c: Computes atan2(x) where x is a 32-bit float.

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

/* Version 1.0 - Initial release */

/*
** $Id: atan2f.c 4776 2007-04-29 13:15:51Z borutr $
*/

#include <math.h>

float atan2f(const float x, const float y)
{
    float r;

    if ((x==0.0) && (y==0.0))
    {
        //errno=EDOM;
        return 0.0;
    }

    if(fabsf(y)>=fabsf(x))
    {
        r=atanf(x/y);
        if(y<0.0) r+=(x>=0?PI:-PI);
    }
    else
    {
        r=-atanf(y/x);
        r+=(x<0.0?-HALF_PI:HALF_PI);
    }
    return r;
}
