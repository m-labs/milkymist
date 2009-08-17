/*
  Copyright (C) 2005, 2006, 2009 Sebastien Bourdeauducq

  This file is part of Madrigal.

  Madrigal is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  Madrigal is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Madrigal ; if not, write to the Free Software Foundation,
  Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*/

#include <SDL/SDL.h>
#include <GL/gl.h>
#include <GL/glu.h>
#include <alsa/asoundlib.h>

#include "projectM.h"

static int width = 640;
static int height = 480;
static int bpp = 0;

static SDL_Surface *screen;
projectM_t *globalPM;

static unsigned int sample_rate;
static snd_pcm_t *playback_handle;
static snd_pcm_hw_params_t *hw_params;

int init_video()
{
	const SDL_VideoInfo* info;

	if(SDL_Init(SDL_INIT_VIDEO) < 0) {
		fprintf(stderr, "Video initialization failed: %s\n", SDL_GetError());
		return 0;
	}

	info = SDL_GetVideoInfo();
	if(!info) {
		fprintf(stderr, "Video query failed: %s\n", SDL_GetError());
		return 0;
	}

	bpp = info->vfmt->BitsPerPixel;

	SDL_GL_SetAttribute(SDL_GL_ALPHA_SIZE, 8);
	SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 16);
	SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

	screen = SDL_SetVideoMode(width, height, bpp, SDL_OPENGL|SDL_HWSURFACE|SDL_HWACCEL);

	if(!screen) {
		fprintf(stderr, "Video mode set failed: %s\n", SDL_GetError());
		return 0;
	}

	printf("==== Video ====\n");
	printf("Screen BPP : %d\n", SDL_GetVideoSurface()->format->BitsPerPixel);
	printf("Vendor     : %s\n", glGetString(GL_VENDOR));
	printf("Renderer   : %s\n", glGetString(GL_RENDERER));
	printf("Version    : %s\n", glGetString(GL_VERSION));
	printf("\n");

	SDL_WM_SetCaption("projectM test", NULL);

	return 1;
}

int init_sound()
{
	int err;
	
	if((err = snd_pcm_open(&playback_handle, "default", SND_PCM_STREAM_CAPTURE, 0)) < 0) {
		fprintf(stderr, "cannot open audio device (%s)\n", snd_strerror(err));
		return 0;
	}

	if((err = snd_pcm_hw_params_malloc(&hw_params)) < 0) {
		fprintf(stderr, "cannot allocate hardware parameter structure (%s)\n", snd_strerror(err));
		return 0;
	}

	if((err = snd_pcm_hw_params_any(playback_handle, hw_params)) < 0) {
		fprintf(stderr, "broken configuration for playback: no configuration available: (%s)", snd_strerror(err));
		return 0;
	}

	if((err = snd_pcm_hw_params_set_access(playback_handle, hw_params, SND_PCM_ACCESS_RW_INTERLEAVED)) < 0) {
		fprintf(stderr, "cannot set access type (%s)\n", snd_strerror(err));
		return 0;
	}

	if((err = snd_pcm_hw_params_set_format (playback_handle, hw_params, SND_PCM_FORMAT_S16_LE)) < 0) {
		fprintf(stderr, "cannot set sample format (%s)\n", snd_strerror(err));
		return 0;
	}

	sample_rate = 8000;
	if((err = snd_pcm_hw_params_set_rate_near(playback_handle, hw_params, &sample_rate, 0)) < 0) {
		fprintf(stderr, "cannot set sample rate (%s)\n", snd_strerror(err));
		return 0;
	}

	if((err = snd_pcm_hw_params_set_channels(playback_handle, hw_params, 2)) < 0) {
		fprintf(stderr, "cannot set channel count (%s)\n", snd_strerror(err));
		return 0;
	}

	if((err = snd_pcm_hw_params(playback_handle, hw_params)) < 0) {
		fprintf(stderr, "cannot set parameters (%s)\n", snd_strerror(err));
		return 0;
	}

	printf("==== Audio ====\n");
	printf("Rate       : %d\n", sample_rate);

	snd_pcm_hw_params_free(hw_params);

	return 1;
}

#define PROJECTM_BUFSIZ 512

int main(int argc, char *argv[])
{
	short pcm_data[2][PROJECTM_BUFSIZ];
	int read_frames = 0;
	snd_pcm_sframes_t pcmreturn;
	int running;
	SDL_Event event;

	if(argc != 2) {
		fprintf(stderr, "Missing preset file\n");
		return 1;
	}

	if(!init_video()) {
		SDL_Quit();
		return 1;
	}

	if(!init_sound()) {
		SDL_Quit();
		return 1;
	}

	globalPM = malloc(sizeof(projectM_t));
	projectM_reset(globalPM);

	globalPM->fps = 30;

	globalPM->fullscreen = 0;
	globalPM->renderTarget->texsize = 512;
	globalPM->gx = 32;
	globalPM->gy = 24;

	projectM_init(globalPM);
	projectM_resetGL(globalPM, width, height);

	loadPresetByFile(argv[1]);

	running = 1;
	while(running) {
		while(SDL_PollEvent(&event)) {
			switch(event.type){
				case SDL_QUIT:
					running = 0;
					break;
			}
		}
	
		if((pcmreturn = snd_pcm_readi(playback_handle, &pcm_data[0][read_frames], PROJECTM_BUFSIZ-read_frames)) < 0) {
			snd_pcm_prepare(playback_handle);
			read_frames = 0;
			fprintf(stderr, "\r\n<<<<<<<<<<<<<<< Buffer Underrun >>>>>>>>>>>>>>>\r\n");
		} else read_frames += pcmreturn;

		if(read_frames == PROJECTM_BUFSIZ) {
			/* Add the waveform data */
			addPCM16(pcm_data);
			read_frames = 0;
		}

		renderFrame(globalPM);
		SDL_GL_SwapBuffers();
	}
	
	snd_pcm_close(playback_handle);
	free(globalPM);

	SDL_Quit();

	return 0;
}

