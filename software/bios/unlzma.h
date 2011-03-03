#ifndef __UNLZMA_H
#define __UNLZMA_H

int unlzma(unsigned char *buf, int in_len,
			      int(*fill)(void*, unsigned int),
			      int(*flush)(void*, unsigned int),
			      unsigned char *output,
			      int *posp,
			      void(*error)(char *x)
	);

#endif
