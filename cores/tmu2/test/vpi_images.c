/*
 * Milkymist SoC
 * Copyright (C) 2007, 2008, 2009, 2010 Sebastien Bourdeauducq
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

#include <vpi_user.h>
#include <stdio.h>
#include <stdlib.h>
#include <gd.h>

static gdImagePtr src;
static gdImagePtr dst;

/*
 * Open both input and output images.
 *
 * Use from Verilog:
 * call $image_open at the beginning of the testbench.
 */
static int open_calltf(char *user_data)
{
	FILE *fd;

	fd = fopen("lena.png", "rb");
	if(fd == NULL) {
		perror("Unable to open input picture");
		exit(1);
	}
	src = gdImageCreateFromPng(fd);
	if(src == NULL) {
		fprintf(stderr, "Unable to read input picture\n");
		exit(1);
	}
	fclose(fd);
	
	dst = gdImageCreateTrueColor(src->sx, src->sy);
	if(dst == NULL) {
		fprintf(stderr, "Unable to create output picture\n");
		exit(1);
	}
	return 0;
}

/*
 * Get a RGB565 pixel.
 *
 * Use from Verilog:
 * $image_get(img, x, y, color);
 * img = 0/1 (source/dest)
 * color will be modified to reflect the
 * pixel's color ; x and y are unmodified.
 */
static int get_calltf(char *user_data)
{
	vpiHandle sys;
	vpiHandle argv;
	vpiHandle item;
	s_vpi_value value;
	s_vpi_vecval vec;
	unsigned int img, x, y;
	unsigned int c;
	unsigned int red, green, blue;
	unsigned int r;
	
	sys = vpi_handle(vpiSysTfCall, 0);
	argv = vpi_iterate(vpiArgument, sys);

	/* get img */
	item = vpi_scan(argv);
	value.format = vpiIntVal;
	vpi_get_value(item, &value);
	img = value.value.integer;
	
	/* get x */
	item = vpi_scan(argv);
	value.format = vpiIntVal;
	vpi_get_value(item, &value);
	x = value.value.integer;

	/* get y */
	item = vpi_scan(argv);
	value.format = vpiIntVal;
	vpi_get_value(item, &value);
	y = value.value.integer;

	/* do the job */
	c = gdImageGetTrueColorPixel(img ? dst : src, x, y);
	red = gdTrueColorGetRed(c);
	green = gdTrueColorGetGreen(c);
	blue = gdTrueColorGetBlue(c);
	r = ((red & 0xf8) << 8) | ((green & 0xfc) << 3) | ((blue & 0xf8) >> 3);
	
	/* write to the destination */
	item = vpi_scan(argv);
	value.format = vpiVectorVal;
	vec.aval = r;
	vec.bval = 0;
	value.value.vector = &vec;
	vpi_put_value(item, &value, 0, vpiNoDelay);
	
	vpi_free_object(argv);
	return 0;
}

/*
 * Set a RGB565 pixel.
 *
 * Use from Verilog:
 * $image_set(img, x, y, color);
 * img = 0/1 (source/dest)
 * Parameters are not modified.
 */
static int set_calltf(char *user_data)
{
	vpiHandle sys;
	vpiHandle argv;
	vpiHandle item;
	s_vpi_value value;
	unsigned int img, x, y;
	unsigned int c;
	unsigned int red, green, blue;
	
	sys = vpi_handle(vpiSysTfCall, 0);
	argv = vpi_iterate(vpiArgument, sys);

	/* get img */
	item = vpi_scan(argv);
	value.format = vpiIntVal;
	vpi_get_value(item, &value);
	img = value.value.integer;
	
	/* get x */
	item = vpi_scan(argv);
	value.format = vpiIntVal;
	vpi_get_value(item, &value);
	x = value.value.integer;

	/* get y */
	item = vpi_scan(argv);
	value.format = vpiIntVal;
	vpi_get_value(item, &value);
	y = value.value.integer;

	/* get color */
	item = vpi_scan(argv);
	value.format = vpiIntVal;
	vpi_get_value(item, &value);
	c = value.value.integer;

	vpi_free_object(argv);

	/* do the job */
	/* extract raw 5, 6 and 5-bit components */
	red = (c & 0xf800) >> 11;
	green = (c & 0x07e0) >> 5;
	blue = c & 0x001f;
	
	/* shift right and complete with MSBs */
	red = (red << 3) | ((red & 0x1c) >> 2);
	green = (green << 2) | ((green & 0x30) >> 4);
	blue = (blue << 3) | ((blue & 0x1c) >> 2);
	
	//printf("Set Pixel (%d,%d), %02x%02x%02x\n", x, y, red, green, blue);
	
	gdImageSetPixel(img ? dst : src, x, y,
		gdImageColorAllocate(img ? dst : src, red, green, blue));
	
	return 0;
}

/*
 * Close both input and output images.
 *
 * Use from Verilog:
 * call $image_close at the end of the testbench.
 * Don't forget it, or the destination file will
 * not be written !
 */
static int close_calltf(char *user_data)
{
	FILE *fd;
	
	gdImageDestroy(src);
	
	fd = fopen("out.png", "wb");
	gdImagePng(dst, fd);
	fclose(fd);
	gdImageDestroy(dst);
	return 0;
}

void vpi_register()
{
	s_vpi_systf_data tf_data;
	
	tf_data.type      = vpiSysTask;
	tf_data.tfname    = "$image_open";
	tf_data.calltf    = open_calltf;
	tf_data.compiletf = 0;
	tf_data.sizetf    = 0;
	tf_data.user_data = 0;
	vpi_register_systf(&tf_data);
	
	tf_data.type      = vpiSysTask;
	tf_data.tfname    = "$image_get";
	tf_data.calltf    = get_calltf;
	tf_data.compiletf = 0;
	tf_data.sizetf    = 0;
	tf_data.user_data = 0;
	vpi_register_systf(&tf_data);
	
	tf_data.type      = vpiSysTask;
	tf_data.tfname    = "$image_set";
	tf_data.calltf    = set_calltf;
	tf_data.compiletf = 0;
	tf_data.sizetf    = 0;
	tf_data.user_data = 0;
	vpi_register_systf(&tf_data);
	
	tf_data.type      = vpiSysTask;
	tf_data.tfname    = "$image_close";
	tf_data.calltf    = close_calltf;
	tf_data.compiletf = 0;
	tf_data.sizetf    = 0;
	tf_data.user_data = 0;
	vpi_register_systf(&tf_data);
	
	printf("PLI Image I/O functions registered\n");
}

void (*vlog_startup_routines[])() = {
	vpi_register,
	0
};
