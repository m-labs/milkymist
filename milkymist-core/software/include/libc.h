/*
 * Milkymist VJ SoC (Software)
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 * Copyright (C) Linux kernel developers
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


#ifndef __LIBC_H
#define __LIBC_H

#if (__GNUC__ > 4) || ((__GNUC__ == 4) && (__GNUC_MINOR__ >= 4))
#define va_start(v,l) __builtin_va_start((v),l)
#else
#define va_start(v,l) __builtin_stdarg_start((v),l)
#endif

#define va_arg(ap, type) \
	__builtin_va_arg((ap), type)

#define va_end(ap) \
	__builtin_va_end(ap)

#define va_list \
	__builtin_va_list


#define NULL ((void *)0)

#define INT_MIN ((((unsigned long)-1) >> 1) + 1)
#define INT_MAX (((unsigned long)-1) >> 1)

#define likely(x) (x)
#define unlikely(x) (x)

#define PRINTF_ZEROPAD	1		/* pad with zero */
#define PRINTF_SIGN	2		/* unsigned/signed long */
#define PRINTF_PLUS	4		/* show plus */
#define PRINTF_SPACE	8		/* space if plus */
#define PRINTF_LEFT	16		/* left justified */
#define PRINTF_SPECIAL	32		/* 0x */
#define PRINTF_LARGE	64		/* use 'ABCDEF' instead of 'abcdef' */

typedef int size_t;
typedef int ptrdiff_t;

static inline int isdigit(char c)
{
	return (c >= '0') && (c <= '9');
}

static inline int isxdigit(char c)
{
	return isdigit(c) || ((c >= 'a') && (c <= 'f')) || ((c >= 'A') && (c <= 'F'));
}

static inline int isupper(char c)
{
	return (c >= 'A') && (c <= 'Z');
}

static inline int islower(char c)
{
	return (c >= 'a') && (c <= 'z');
}

static inline unsigned char tolower(unsigned char c)
{
	if (isupper(c))
		c -= 'A'-'a';
	return c;
}

static inline unsigned char toupper(unsigned char c)
{
	if (islower(c))
		c -= 'a'-'A';
	return c;
}

static inline char isspace(unsigned char c)
{
	if(c == ' '
		|| c == '\f'
		|| c == '\n'
		|| c == '\r'
		|| c == '\t'
		|| c == '\v')
		return 1;
	
	return 0;
}


char *strchr(const char *s, int c);
char *strrchr(const char *s, int c);
char *strnchr(const char *s, size_t count, int c);
char *strcpy(char *dest, const char *src);
char *strncpy(char *dest, const char *src, size_t count);
int strcmp(const char *cs, const char *ct);
int strncmp(const char *cs, const char *ct, size_t count);
size_t strlen(const char *s);
size_t strnlen(const char *s, size_t count);
int memcmp(const void *cs, const void *ct, size_t count);
void *memset(void *s, int c, size_t count);
void *memcpy(void *dest, const void *src, size_t n);
void *memmove(void *dest, const void *src, size_t count);

unsigned long strtoul(const char *nptr, char **endptr, int base);
int skip_atoi(const char **s);
static inline int atoi(const char *nptr) {
	return strtoul(nptr, NULL, 0);
}
static inline long atol(const char *nptr) {
	return (long)atoi(nptr);
}
char *number(char *buf, char *end, unsigned long num, int base, int size, int precision, int type);
long strtol(const char *nptr, char **endptr, int base);

#define abs(x) ((x) > 0 ? (x) : -(x))

int vsnprintf(char *buf, size_t size, const char *fmt, va_list args);
int vscnprintf(char *buf, size_t size, const char *fmt, va_list args);
int snprintf(char *buf, size_t size, const char *fmt, ...);
int scnprintf(char *buf, size_t size, const char *fmt, ...);
int vsprintf(char *buf, const char *fmt, va_list args);
int sprintf(char *buf, const char *fmt, ...);

unsigned int rand();

#define assert(x)

float atof(const char *s);

#endif
