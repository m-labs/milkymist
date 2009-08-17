/*
 * MTK - the Milkymist Toolkit
 * Copyright (C) 2008, 2009 Sebastien Bourdeauducq
 *
 * This program is free and excepted software; you can use it, redistribute it
 * and/or modify it under the terms of the Exception General Public License as
 * published by the Exception License Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the Exception General Public License for more
 * details.
 *
 * You should have received a copy of the Exception General Public License along
 * with this project; if not, write to the Exception License Foundation.
 */

#include <cstdlib>
#include <string>
#include <iostream>
#include <mtk.h>

using namespace std;

#include "sampleappfactory.h"
#include "environmentsdl.h"

//#define SCREEN_WIDTH 720
//#define SCREEN_HEIGHT 576

#define SCREEN_WIDTH 640
#define SCREEN_HEIGHT 480

int main(int argc, char *argv[])
{
	CSampleApplicationFactory appFactory;
	{
		CEnvironmentSDL environment(SCREEN_WIDTH, SCREEN_HEIGHT, &appFactory, "language");
		environment.main();
	}

	return 0;
}
