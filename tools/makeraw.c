/*
 * Milkymist SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <gd.h>

#define MAKERGB565(r, g, b) ((((r) & 0xf8) << 8) | (((g) & 0xfc) << 3) | (((b) & 0xf8) >> 3))

#define HTOBE(x) (((x & 0x00ff) << 8)|((x & 0xff00) >> 8))

int main(int argc, char *argv[])
{
	char *finname;
	char *foutname;
	char *c;
	FILE *fin, *fout;
	gdImagePtr im;
	int x, y;
	
	if(argc != 2) {
		fprintf(stderr, "Usage: %s <file.png>\n", argv[0]);
		return 1;
	}
	finname = argv[1];
	foutname = strdup(finname);
	if(!foutname) {
		perror("strdup");
		return 1;
	}
	c = strrchr(foutname, '.');
	if(!c || strcasecmp(c, ".png")) {
		fprintf(stderr, "Incorrect filename - must end with '.png'\n");
		free(foutname);
		return 1;
	}
	c[1] = 'r'; c[2] = 'a'; c[3] = 'w';
	
	fin = fopen(finname, "rb");
	if(!fin) {
		perror("Unable to open input file");
		free(foutname);
		return 1;
	}
	fout = fopen(foutname, "wb");
	if(!fout) {
		perror("Unable to open output file");
		free(foutname);
		return 1;
	}
	
	im = gdImageCreateFromPng(fin);
	if(!im) {
		fprintf(stderr, "Unable to read PNG format\n");
		return 1;
	}
	for(y=0;y<gdImageSY(im);y++)
		for(x=0;x<gdImageSX(im);x++) {
			int c;
			unsigned short int o;
			
			c = gdImageGetPixel(im, x, y);
			
			o = MAKERGB565(gdImageRed(im, c), gdImageGreen(im, c), gdImageBlue(im, c));
			o = HTOBE(o);
			fwrite(&o, 2, 1, fout);
		}
	
	fclose(fin);
	if(fclose(fout) != 0) {
		perror("fclose");
		gdImageDestroy(im);
		free(foutname);
		return 1;
	}
	gdImageDestroy(im);
	
	free(foutname);
	
	return 0;
}

