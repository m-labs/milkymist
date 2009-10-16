/*  atanf.c: Computes arctan of a 32-bit float as outlined in [1]

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
** $Id: atanf.c 4776 2007-04-29 13:15:51Z borutr $
*/

#include <math.h>

#define P0 -0.4708325141E+0
#define P1 -0.5090958253E-1
#define Q0  0.1412500740E+1
#define Q1  0.1000000000E+1

#define P(g,f) ((P1*g+P0)*g*f)
#define Q(g) (Q1*g+Q0)

#define K1  0.2679491924 /* 2-sqrt(3) */
#define K2  0.7320508076 /* sqrt(3)-1 */
#define K3  1.7320508076 /* sqrt(3)   */

float atanf(const float x)
{
    float f, r, g;
    int n=0;
    static float a[]={  0.0, 0.5235987756, 1.5707963268, 1.0471975512 };

    f=fabsf(x);
    if(f>1.0)
    {
        f=1.0/f;
        n=2;
    }
    if(f>K1)
    {
        f=((K2*f-1.0)+f)/(K3+f);
        // What it is actually wanted is this more accurate formula,
        // but SDCC optimizes it and then it does not work:
        // f=(((K2*f-0.5)-0.5)+f)/(K3+f);
        n++;
    }
    if(fabsf(f)<EPS) r=f;
    else
    {
        g=f*f;
        r=f+P(g,f)/Q(g);
    }
    if(n>1) r=-r;
    r+=a[n];
    if(x<0.0) r=-r;
    return r;
}

