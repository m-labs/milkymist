/**
 * projectM -- Milkdrop-esque visualisation SDK
 * Copyright (C)2003-2004 projectM Team
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 * See 'LICENSE.txt' included within this release
 *
 */
/* Wrappers for all the builtin functions 
   The arg_list pointer is a list of doubles. Its
   size is equal to the number of arguments the parameter
   takes */

#ifndef _BUILTIN_FUNCS_H
#define _BUILTIN_FUNCS_H
 
inline double below_wrapper(double * arg_list);
inline double above_wrapper(double * arg_list);
inline double equal_wrapper(double * arg_list);
inline double if_wrapper(double * arg_list);
inline double bnot_wrapper(double * arg_list);
inline double rand_wrapper(double * arg_list);
inline double bor_wrapper(double * arg_list);
inline double band_wrapper(double * arg_list);
inline double sigmoid_wrapper(double * arg_list);
inline double max_wrapper(double * arg_list);
inline double min_wrapper(double * arg_list);
inline double sign_wrapper(double * arg_list);
inline double sqr_wrapper(double * arg_list);
inline double int_wrapper(double * arg_list);
inline double nchoosek_wrapper(double * arg_list);
inline double sin_wrapper(double * arg_list);
inline double cos_wrapper(double * arg_list);
inline double tan_wrapper(double * arg_list);
inline double fact_wrapper(double * arg_list);
inline double asin_wrapper(double * arg_list);
inline double acos_wrapper(double * arg_list);
inline double atan_wrapper(double * arg_list);
inline double atan2_wrapper(double * arg_list);

inline double pow_wrapper(double * arg_list);
inline double exp_wrapper(double * arg_list);
inline double abs_wrapper(double * arg_list);
inline double log_wrapper(double *arg_list);
inline double log10_wrapper(double * arg_list);
inline double sqrt_wrapper(double * arg_list);

#endif /** !_BUILTIN_FUNCS_H */
