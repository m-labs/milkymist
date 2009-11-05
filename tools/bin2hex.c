/*
 * Milkymist VJ SoC
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

int main(int argc, char *argv[])
{
	int i;
	int pad;
	FILE *fdi, *fdo;
	unsigned char w[4];
	
	if(argc != 4) {
		fprintf(stderr, "Usage: bin2hex <infile> <outfile> <size>");
		return 1;
	}
	pad = atoi(argv[3]);
	if(pad <= 0) {
		fprintf(stderr, "Incorrect size");
		return 1;
	}
	fdi = fopen(argv[1], "rb");
	if(!fdi) {
		perror("Unable to open input file");
		return 1;
	}
	fdo = fopen(argv[2], "w");
	if(!fdo) {
		perror("Unable to open output file");
		fclose(fdi);
		return 1;
	}
	while(1) {
		if(fread(w, 4, 1, fdi) <= 0) break;
		fprintf(fdo, "%02hhx%02hhx%02hhx%02hhx\n", w[0], w[1], w[2], w[3]);
		pad--;
	}
	fclose(fdi);
	if(pad<0)
		fprintf(stderr, "Warning: Input binary is larger than specified size");
	for(i=0;i<pad;i++)
		fprintf(fdo, "00000000\n");
	if(fclose(fdo) != 0) {
		perror("Unable to close output file");
		return 1;
	}
	return 0;
}
