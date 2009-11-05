/*  expf.c: Computes e**x of a 32-bit float as outlined in [1]

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
** $Id: expf.c 4776 2007-04-29 13:15:51Z borutr $
*/

#include <math.h>

#define P0      0.2499999995E+0
#define P1      0.4160288626E-2
#define Q0      0.5000000000E+0
#define Q1      0.4998717877E-1

#define P(z) ((P1*z)+P0)
#define Q(z) ((Q1*z)+Q0)

#define C1       0.693359375
#define C2      -2.1219444005469058277e-4

#define BIGX    88.72283911  /* ln(XMAX) */
#define EXPEPS  1.0E-7       /* exp(1.0E-7)=0.0000001 */
#define K1      1.4426950409 /* 1/ln(2) */

float expf(const float x)
{
    int n;
    float xn, g, r, z, y;
    char sign;

    if(x>=0.0)
        { y=x;  sign=0; }
    else
        { y=-x; sign=1; }

    if(y<EXPEPS) return 1.0;

    if(y>BIGX)
    {
        if(sign)
        {
            //errno=ERANGE;
            return XMAX;
        }
        else
        {
            return 0.0;
        }
    }

    z=y*K1;
    n=z;

    if(n<0) --n;
    if(z-n>=0.5) ++n;
    xn=n;
    g=((y-xn*C1))-xn*C2;
    z=g*g;
    r=P(z)*g;
    r=0.5+(r/(Q(z)-r));

    n++;
    z=ldexpf(r, n);
    if(sign)
        return 1.0/z;
    else
        return z;
}

