/*
 * unique.h - Unique string store
 *
 * Copyright 2011 by Werner Almesberger
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 */

#ifndef UNIQUE_H
#define	UNIQUE_H

const char *unique(const char *s);
const char *unique_n(const char *s, int n);
void unique_free(void);

#endif /* !UNIQUE_H */
