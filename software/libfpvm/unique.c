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

#include "unique.h"


#define	INITIAL_ALLOC	64


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
	return b[n];
}


/* We don't have bsearch, so here's our own version. */

static const char *search(const char *s)
{
	int low = 0;
	int high = sizeof(well_known)/sizeof(*well_known)-1;
	int mid, res;

	while(low <= high) {
		mid = (low+high)/2;
		res = strcmp(s, well_known[mid]);
		if(!res)
			return well_known[mid];
		if(res < 0)
			high = mid-1;
		else
			low = mid+1;
	}
	return NULL;
}


static const char *search_n(const char *s, int n)
{
	int low = 0;
	int high = sizeof(well_known)/sizeof(*well_known)-1;
	int mid, res;

	while(low <= high) {
		mid = (low+high)/2;
		res = strcmp_n(s, well_known[mid], n);
		if(!res)
			return well_known[mid];
		if(res < 0)
			high = mid-1;
		else
			low = mid+1;
	}
	return NULL;
}


/* We don't have strdup either. */

static char *my_strdup(const char *s)
{
	size_t len;
	char *new;

	len = strlen(s)+1;
	new = malloc(len);
	memcpy(new, s, len);
	return new;
}


static char *my_strdup_n(const char *s, int n)
{
	char *new;

	new = malloc(n+1);
	memcpy(new, s, n);
	new[n] = 0;
	return new;
}


static void grow_table(void)
{
	int allocate;
	const char **new;

	if(num_vars != allocated)
		return;

	/* There's no realloc, so we roll our own.  */
	allocate = allocated ? allocated*2 : INITIAL_ALLOC;
	new = malloc(allocate*sizeof(*vars));
	memcpy(new, vars, allocated*sizeof(*vars));
	vars = new;
}


const char *unique(const char *s)
{
	const char *res;
	const char **walk;

	res = search(s);
	if(res)
		return res;
	for(walk = vars; walk != vars+num_vars; walk++)
		if(!strcmp(*walk, s))
			return *walk;
	grow_table();
	return vars[num_vars++] = my_strdup(s);
}


const char *unique_n(const char *s, int n)
{
	const char *res;
	const char **walk;

	res = search_n(s, n);
	if(res)
		return res;
	for(walk = vars; walk != vars+num_vars; walk++)
		if(!strcmp_n(s, *walk, n))
			return *walk;
	grow_table();
	return vars[num_vars++] = my_strdup_n(s, n);
}


void unique_free(void)
{
	int i;

	for(i = 0; i != num_vars; i++)
		free((void *) vars[i]);
	free(vars);
	num_vars = allocated = 0;
}
