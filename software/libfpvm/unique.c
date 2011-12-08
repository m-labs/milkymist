/*
 * unique.c - Unique string store
 *
 * Copyright 2011 by Werner Almesberger
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 */


#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "unique.h"


#define	INITIAL_ALLOC	64


struct key_n {
	const char *s;
	int n;
};

const char *well_known[] = {
#include "fnp.inc"
};

static const char **vars = NULL;
static int num_vars = 0, allocated = 0;


/*
 * "a" is not NUL-terminated and its length "a" is determined by "n".
 * "b" is NUL-terminated.
 */

static int strcmp_n(const char *a, const char *b, int n)
{
	int diff;

	diff = strncmp(a, b, n);
	if (diff)
		return diff;
	/* handle implicit NUL in string "a" */
	return -b[n];
}


static char *strdup_n(const char *s, int n)
{
	char *new;

	new = malloc(n+1);
	memcpy(new, s, n);
	new[n] = 0;
	return new;
}


static void grow_table(void)
{
	if(num_vars != allocated)
		return;

	allocated = allocated ? allocated*2 : INITIAL_ALLOC;
	vars = realloc(vars, allocated*sizeof(*vars));
}


static int cmp(const void *a, const void *b)
{
	return strcmp(a, *(const char **) b);
}


static int cmp_n(const void *a, const void *b)
{
	const struct key_n *key = a;

	return strcmp_n(key->s, *(const char **) b, key->n);
}


const char *unique(const char *s)
{
	const char **res;
	const char **walk;

	if(!isalnum(*s) && *s != '_')
		return s;
	res = bsearch(s, well_known, sizeof(well_known)/sizeof(*well_known),
	    sizeof(s), cmp);
	if(res)
		return *res;
	for(walk = vars; walk != vars+num_vars; walk++)
		if(!strcmp(*walk, s))
			return *walk;
	grow_table();
	return vars[num_vars++] = strdup(s);
}


const char *unique_n(const char *s, int n)
{
	struct key_n key = {
		.s = s,
		.n = n,
	};
	const char **res;
	const char **walk;

	if(!isalnum(*s) && *s != '_')
		return s;
	res = bsearch(&key, well_known, sizeof(well_known)/sizeof(*well_known),
	    sizeof(s), cmp_n);
	if(res)
		return *res;
	for(walk = vars; walk != vars+num_vars; walk++)
		if(!strcmp_n(s, *walk, n))
			return *walk;
	grow_table();
	return vars[num_vars++] = strdup_n(s, n);
}


void unique_free(void)
{
	int i;

	for(i = 0; i != num_vars; i++)
		free((void *) vars[i]);
	free(vars);
	num_vars = allocated = 0;
}
