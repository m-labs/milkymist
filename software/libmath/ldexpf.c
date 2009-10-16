/*  ldexpf.c: Build a float from a mantisa and exponent.

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
** $Id: ldexpf.c 4776 2007-04-29 13:15:51Z borutr $
*/

#include <math.h>

float ldexpf(const float x, const int pw2)
{
    union float_long fl;
    long e;

    fl.f = x;

    e=(fl.l >> 23) & 0x000000ff;
    e+=pw2;
    fl.l= ((e & 0xff) << 23) | (fl.l & 0x807fffff);

    return(fl.f);
}
