/*-------------------------------------------------------------------------
   math.h: Floating point math function declarations

    Ported to PIC16 port by Vangelis Rokas, 2004 (vrokas@otenet.gr)
    Adopted for the PIC14 port 2006 by Raphael Neider <rneider AT web.de>
    
    Copyright (C) 2001  Jesus Calvino-Fraga, jesusc@ieee.org 

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
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
-------------------------------------------------------------------------*/

/*
** $Id: math.h 4776 2007-04-29 13:15:51Z borutr $
*/

#ifndef __MATH_H
#define __MATH_H

#define PI          3.1415926536
#define TWO_PI      6.2831853071
#define HALF_PI     1.5707963268
#define QUART_PI    0.7853981634
#define iPI         0.3183098862
#define iTWO_PI     0.1591549431
#define TWO_O_PI    0.6366197724

// EPS=B**(-t/2), where B is the radix of the floating-point representation
// and there are t base-B digits in the significand.  Therefore, for floats
// EPS=2**(-12).  Also define EPS2=EPS*EPS.
#define EPS 244.14062E-6
#define EPS2 59.6046E-9
#define XMAX 3.402823466E+38

union float_long
{
    float f;
    long l;
};

/**********************************************
 * Prototypes for float ANSI C math functions *
 **********************************************/

/* Trigonometric functions */
float sinf(const float x);
float cosf(const float x);
float tanf(const float x);
float cotf(const float x);
float asinf(const float x);
float acosf(const float x);
float atanf(const float x);
float atan2f(const float x, const float y);

/* Hyperbolic functions */
float sinhf(const float x);
float coshf(const float x);
float tanhf(const float x);

/* Exponential, logarithmic and power functions */
float expf(const float x);
float logf(const float x);
float log10f(const float x);
float powf(const float x, const float y);
float sqrtf(const float a);

/* Nearest integer, absolute value, and remainder functions */
float fabsf(const float x);
float frexpf(const float x, int *pw2);
float ldexpf(const float x, const int pw2);
float ceilf(float x);
float floorf(float x);
float modff(float x, float *y);

#endif  /* __MATH_H */
