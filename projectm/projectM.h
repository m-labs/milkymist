/**
 * projectM -- Milkdrop-esque visualisation SDK
 * Copyright (C)2003-2004 projectM Team
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 * See 'LICENSE.txt' included within this release
 *
 */
/**
 * $Id: projectM.h,v 1.6 2004/11/07 17:29:45 cvs Exp $
 *
 * Encapsulation of ProjectM engine
 *
 */

#ifndef _PROJECTM_H
#define _PROJECTM_H

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#ifdef MACOS
#include <MacWindows.h>
#include <gl.h>
#include <glu.h>
#else
#ifdef WIN32
#include <windows.h>
#endif /** WIN32 */
#include <GL/gl.h>
#include <GL/glu.h>
#endif /** MACOS */
#ifdef WIN32
#define inline
#endif /** WIN32 */
#ifndef WIN32
#include <sys/time.h>
#else
#endif /** !WIN32 */
#include "wipemalloc.h"
#include "fatal.h"
#include "common.h"
#include "preset_types.h"
#include "preset.h"
#include "per_pixel_eqn_types.h"
#include "per_pixel_eqn.h"
#include "interface_types.h"
#include "menu.h"
#include "PCM.h"                    //Sound data handler (buffering, FFT, etc.)
#include "custom_wave_types.h"
#include "custom_wave.h"
#include "custom_shape_types.h"
#include "custom_shape.h"
#include "pbuffer.h"
#include "timer.h"
//#include <dmalloc.h>

#ifdef WIN32
#pragma warning (disable:4244)
#pragma warning (disable:4305)
#endif /** WIN32 */

#ifdef MACOS
#define inline
#endif

/** KEEP THIS UP TO DATE! */
#define PROJECTM_VERSION "0.97"
#define PROJECTM_TITLE "projectM 0.97"

#ifdef MACOS
#define kTVisualPluginName                      "\pprojectM"
#define kTVisualPluginCreator           'hook'

#define kTVisualPluginMajorVersion      1
#define kTVisualPluginMinorVersion      0
#define kTVisualPluginReleaseStage      finalStage
#define kTVisualPluginNonFinalRelease   0
#endif

/** Per-platform path separators */
#define WIN32_PATH_SEPARATOR '\\'
#define UNIX_PATH_SEPARATOR '/'
#ifdef WIN32
#define PATH_SEPARATOR WIN32_PATH_SEPARATOR
#else
#define PATH_SEPARATOR UNIX_PATH_SEPARATOR
#endif /** WIN32 */

/** External debug file */
#ifdef DEBUG
extern FILE *debugFile;
#endif

/** Thread state */
typedef enum { GO, STOP } PMThreadState;

typedef struct PROJECTM {

    int hasInit;

    int pcmframes;
    int freqframes;
    int totalframes;

    int showfps;
    int showtitle;
    int showpreset;
    int showhelp;

    int studio;

    GLubyte *fbuffer;

    preset_t * active_preset;

#ifndef WIN32
    /* The first ticks value of the application */
    struct timeval startTime;
#else
    long startTime;
#endif /** !WIN32 */
    double Time;

    /** Render target texture ID */
    RenderTarget *renderTarget;

    char disp[80];

    double wave_o;

    //int texsize=1024;   //size of texture to do actual graphics
    int fvw;     //fullscreen dimensions
    int fvh;
    int wvw;      //windowed dimensions
    int wvh;
    int vw;           //runtime dimensions
    int vh;
    int fullscreen;
    
    int maxsamples; //size of PCM buffer
    int numsamples; //size of new PCM info
    double *pcmdataL;     //holder for most recent pcm data 
    double *pcmdataR;     //holder for most recent pcm data 
    
    int avgtime;  //# frames per preset
    
 
    int correction;
    
    double vol;
    
    //per pixel equation variables
    double **gridx;  //grid containing interpolated mesh 
    double **gridy;  
    double **origtheta;  //grid containing interpolated mesh reference values
    double **origrad;  
    double **origx;  //original mesh 
    double **origy;

    /** Timing information */
    int mspf;      
    int timed;
    int timestart;
    int nohard;    
    int count;
    double realfps,
           fpsstart;

    /** PCM data */
    double vdataL[512];  //holders for FFT data (spectrum)
    double vdataR[512];

    /** Various toggles */
    int doPerPixelEffects;
    int doIterative;

    /** ENGINE VARIABLES */
    /** From engine_vars.h */

    /* PER FRAME CONSTANTS BEGIN */
    double zoom;
    double zoomexp;
    double rot;
    double warp;

    double sx;
    double sy;
    double dx;
    double dy;
    double cx;
    double cy;

    int gy;
    int gx;

    double decay;

    double wave_r;
    double wave_g;
    double wave_b;
    double wave_x;
    double wave_y;
    double wave_mystery;

    double ob_size;
    double ob_r;
    double ob_g;
    double ob_b;
    double ob_a;

    double ib_size;
    double ib_r;
    double ib_g;
    double ib_b;
    double ib_a;

    int meshx;
    int meshy;

    double mv_a ;
    double mv_r ;
    double mv_g ;
    double mv_b ;
    double mv_l;
    double mv_x;
    double mv_y;
    double mv_dy;
    double mv_dx;

    double treb ;
    double mid ;
    double bass ;
    double bass_old ;
	double beat_sensitivity;
    double treb_att ;
    double mid_att ;
    double bass_att ;
    double progress ;
    int frame ;

        /* PER_FRAME CONSTANTS END */

    /* PER_PIXEL CONSTANTS BEGIN */

    double x_per_pixel;
    double y_per_pixel;
    double rad_per_pixel;
    double ang_per_pixel;

    /* PER_PIXEL CONSTANT END */


    double fRating;
    double fGammaAdj;
    double fVideoEchoZoom;
    double fVideoEchoAlpha;
    
    int nVideoEchoOrientation;
    int nWaveMode;
    int bAdditiveWaves;
    int bWaveDots;
    int bWaveThick;
    int bModWaveAlphaByVolume;
    int bMaximizeWaveColor;
    int bTexWrap;
    int bDarkenCenter;
    int bRedBlueStereo;
    int bBrighten;
    int bDarken;
    int bSolarize;
    int bInvert;
    int bMotionVectorsOn;
    int fps; 
    
    double fWaveAlpha ;
    double fWaveScale;
    double fWaveSmoothing;
    double fWaveParam;
    double fModWaveAlphaStart;
    double fModWaveAlphaEnd;
    double fWarpAnimSpeed;
    double fWarpScale;
    double fShader;
    
    
    /* Q VARIABLES START */

    double q1;
    double q2;
    double q3;
    double q4;
    double q5;
    double q6;
    double q7;
    double q8;


    /* Q VARIABLES END */

    double **zoom_mesh;
    double **zoomexp_mesh;
    double **rot_mesh;

    double **sx_mesh;
    double **sy_mesh;
    double **dx_mesh;
    double **dy_mesh;
    double **cx_mesh;
    double **cy_mesh;

    double **x_mesh;
    double **y_mesh;
    double **rad_mesh;
    double **theta_mesh;
  } projectM_t;

/** Functions */
extern void projectM_init(projectM_t *pm);
extern void projectM_initengine(projectM_t *pm);
extern void projectM_reset( projectM_t *pm );
extern void projectM_resetengine(projectM_t *pm);
extern void projectM_resetGL( projectM_t *pm, int width, int height );

extern void projectM_setTitle( projectM_t *pm, char *title );

extern void renderFrame(projectM_t *pm);
extern void draw_fps(projectM_t *pm,double fps);
extern void draw_preset(projectM_t *pm);
extern void draw_title(projectM_t *pm);

extern void modulate_opacity_by_volume(projectM_t *pm);
extern void maximize_colors(projectM_t *pm);
extern void do_per_pixel_math(projectM_t *pm);
extern void do_per_frame(projectM_t *pm);
extern void render_texture_to_studio(projectM_t *pm);

extern void render_interpolation(projectM_t *pm);
extern void render_texture_to_screen(projectM_t *pm);
extern void render_texture_to_studio(projectM_t *pm);
extern void draw_motion_vectors(projectM_t *pm);
extern void draw_borders(projectM_t *pm);
extern void draw_shapes(projectM_t *pm);
extern void draw_waveform(projectM_t *pm);
extern void draw_custom_waves(projectM_t *pm);

extern void reset_per_pixel_matrices(projectM_t *pm);
extern void init_per_pixel_matrices(projectM_t *pm);
extern void rescale_per_pixel_matrices(projectM_t *pm);

/** Kludge! */
#define PM globalPM
extern projectM_t *globalPM;

#endif /** !_PROJECTM_H */
