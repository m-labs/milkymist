/*  sincoshf.c: Computes sinh or cosh of a 32-bit float as outlined in [1]

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
** $Id: sincoshf.c 4776 2007-04-29 13:15:51Z borutr $
*/

#include <math.h>

#define P0 -0.713793159E+1
#define P1 -0.190333999E+0
#define Q0 -0.428277109E+2
#define Q1  0.100000000E+1

#define P(z) (P1*z+P0)
#define Q(z) (Q1*z+Q0)

#define K1 0.69316101074218750000E+0 /* ln(v)   */
#define K2 0.24999308500451499336E+0 /* v**(-2) */
#define K3 0.13830277879601902638E-4 /* v/2-1   */

//WMAX is defined as ln(XMAX)-ln(v)+0.69
#define WMAX 44.93535952E+0
//WBAR 0.35*(b+1)
#define WBAR 1.05
#define YBAR 9.0 /*Works for me*/

float sincoshf(const float x, const int iscosh)
{
    float y, w, z;
    char sign;

    if (x<0.0) { y=-x; sign=1; }
          else { y=x;  sign=0; }

    if ((y>1.0) || iscosh)
    {
        if(y>YBAR)
        {
            w=y-K1;
            if (w>WMAX)
            {
                //errno=ERANGE;
                z=XMAX;
            }
            else
            {
                z=expf(w);
                z+=K3*z;
            }
        }
        else
        {
            z=expf(y);
            w=1.0/z;
            if(!iscosh) w=-w;
            z=(z+w)*0.5;
        }
        if(sign) z=-z;
    }
    else
    {
        if (y<EPS)
            z=x;
        else
        {
            z=x*x;
            z=x+x*z*P(z)/Q(z);
        }
    }
    return z;
}
