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

#include <math.h>
#include "projectM.h"
#include "beat_detect.h"

/** Renders a single frame */
void renderFrame( projectM_t *pm ) { 

#ifdef DEBUG
char fname[1024];
FILE *f = NULL;
int index = 0;
int x, y;
#endif 
  
//            printf("Start of loop at %d\n",timestart);

      pm->mspf=1000/pm->fps; //milliseconds per frame
      pm->totalframes++; //total amount of frames since startup

#ifndef WIN32
      pm->Time = getTicks( &pm->startTime ) * 0.001;
#else
        pm->Time = (double)getTicks( pm->startTime ) * 0.001;
#endif /** !WIN32 */

      pm->frame++;  //number of frames for current preset
      pm->progress= pm->frame/(double)pm->avgtime;
#ifdef DEBUG2
fprintf( debugFile, "frame: %d\tprogress: %f\tavgtime: %d\n", pm->frame, pm->progress, pm->avgtime );
fflush( debugFile );
#endif
      if (pm->progress>1.0) pm->progress=1.0;
     
      evalInitConditions();
      evalPerFrameEquations();
       
      evalCustomWaveInitConditions();
      evalCustomShapeInitConditions();
 
//     printf("%f %d\n",Time,frame);
 
      reset_per_pixel_matrices( pm );

      pm->numsamples = getPCMnew(pm->pcmdataR,1,0,pm->fWaveSmoothing,0,0);
      getPCMnew(pm->pcmdataL,0,0,pm->fWaveSmoothing,0,1);
      getPCM(pm->vdataL,512,0,1,0,0);
      getPCM(pm->vdataR,512,1,1,0,0);

      pm->bass_old = pm->bass;
      pm->bass=0;pm->mid=0;pm->treb=0;

      getBeatVals(pm,pm->vdataL,pm->vdataR);
//      printf("=== %f %f %f %f ===\n",pm->vol,pm->bass,pm->mid,pm->treb);

      pm->count++;
      
#ifdef DEBUG2
    fprintf( debugFile, "start Pass 1 \n" );
    fflush( debugFile );
#endif

      //BEGIN PASS 1
      //
      //This pass is used to render our texture
      //the texture is drawn to a subsection of the framebuffer
      //and then we perform our manipulations on it
      //in pass 2 we will copy the texture into texture memory

      if ( pm->renderTarget != NULL ) {
        lockPBuffer( pm->renderTarget, PBUFFER_PASS1 );
      }
	
      glPushAttrib( GL_ALL_ATTRIB_BITS ); /* Overkill, but safe */
      
      glViewport( 0, 0, pm->renderTarget->texsize, pm->renderTarget->texsize );
      
    glMatrixMode( GL_MODELVIEW );
    glPushMatrix();
    glLoadIdentity();
    
    glMatrixMode( GL_PROJECTION );
    glPushMatrix();
    glLoadIdentity();  
    
    glEnable( GL_TEXTURE_2D );
//    glBindTexture( GL_TEXTURE_2D, pm->renderTarget->textureID );
     
    //glFrustum(0.0, renderTarget->texsize, 0.0,renderTarget->texsize,10,40);
#ifdef DEBUG2
    if ( debugFile != NULL ) {
        fprintf( debugFile, "renderFrame: renderTarget->texsize: %d x %d\n", pm->renderTarget->texsize, pm->renderTarget->texsize );
        fflush( debugFile );
      }
#endif
    glOrtho(0.0, pm->renderTarget->texsize, 0.0,pm->renderTarget->texsize,10,40);
      //     glFrustum(0.0, (GLdouble) (width), 0.0, (GLdouble) h, -3, 10);
      //SDL_SetGamma(fGammaAdj,fGammaAdj,fGammaAdj);

    //draw_waveform(fdata_buffer);
        if ( pm->doPerPixelEffects ) {
            do_per_pixel_math( pm );
          }
    do_per_frame( pm );               //apply per-frame effects
    render_interpolation( pm );       //apply per-pixel effects
    draw_motion_vectors( pm );        //draw motion vectors
    draw_borders( pm );               //draw borders
    // draw_shapes();                //draw custom shapes
    // draw_custom_waves();
  
    draw_waveform( pm );
    draw_shapes( pm );
    draw_custom_waves( pm );
    //draw_shapes();

    /** Restore original view state */
    glMatrixMode( GL_MODELVIEW );
    glPopMatrix();

    glMatrixMode( GL_PROJECTION );
    glPopMatrix();

    /** Restore all original attributes */
    glPopAttrib();
    glFlush();
  
    if ( pm->renderTarget != NULL ) {
        unlockPBuffer( pm->renderTarget );
      }

    /** Reset the viewport size */
    glViewport( 0, 0, pm->vw, pm->vh );

    if ( pm->renderTarget ) {
//        glBindTexture( GL_TEXTURE_2D, pm->renderTarget->textureID[0] );
      }

      //BEGIN PASS 2
      //
      //end of texture rendering
      //now we copy the texture from the framebuffer to
      //video texture memory and render fullscreen on a quad surface.
      glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); 
      glMatrixMode(GL_PROJECTION);
      glLoadIdentity();  
      
      glFrustum(-pm->vw*.5, pm->vw*.5, -pm->vh*.5,pm->vh*.5,10,40);
     	
      glLineWidth( pm->renderTarget->texsize < 512 ? 1 : pm->renderTarget->texsize/512.0);
      if(pm->studio%2)render_texture_to_studio( pm );     
      else render_texture_to_screen( pm );

      // glClear(GL_COLOR_BUFFER_BIT);     
      //render_Studio();

   
      /** Frame-rate limiter */
      /** Compute once per preset */
      if (pm->count==100) 
	{
#ifndef WIN32
	  pm->realfps=100/((getTicks(&pm->startTime)-pm->fpsstart)/1000);
	  pm->fpsstart=getTicks(&pm->startTime);
      //framerate limiter
//      pm->timed=pm->mspf-(getTicks(&pm->startTime)-pm->timestart);
#ifdef DEBUG
        if ( debugFile != NULL ) {
            fprintf( debugFile, "realfps: %f\ttimed: %d\tmspf: %d\ttimestart: %d\n",
                    pm->realfps,pm->timed,pm->mspf, pm->timestart);
            printf( "Limiter %d\n",(getTicks( &pm->startTime)-pm->timestart));
            fflush( debugFile );
          }
#endif
//      if (pm->timed>0)SDL_Delay(pm->timed);
	 //xmms_usleep(time*1000); 
      pm->timestart=getTicks(&pm->startTime);
#else
	  pm->realfps=100/((getTicks(pm->startTime)-pm->fpsstart)/1000);
	pm->fpsstart=getTicks(pm->startTime);
      //framerate limiter
      pm->timed=pm->mspf-(getTicks(pm->startTime)-pm->timestart);
      // printf("%d,%d\n",time,mspf);
//             if (pm->timed>0)SDL_Delay(pm->timed);
	 //xmms_usleep(time*1000); 
	     // printf("Limiter %d\n",(SDL_GetTicks()-timestart));
      pm->timestart=getTicks(pm->startTime);
#endif /** WIN32 */
      
     }

    if ( pm->realfps > pm->fps ) {
	    int rmspf = 1000 / pm->realfps;
#ifndef WIN32
	    if ( usleep( (unsigned int)( pm->mspf - rmspf ) * 1000 ) != 0 ) {
#ifdef DEBUG
            if ( debugFile != NULL ) {
                fprintf( debugFile, "usleep() failed\n" );
                fflush( debugFile );
              }
#endif
          }
#else
#endif /** !WIN32 */
	  }
  }


void projectM_reset( projectM_t *pm ) {

#ifdef DEBUG
    if ( debugFile != NULL ) {
        fprintf( debugFile, "projectM_reset(): in\n" );
        fflush( debugFile );
      }
#endif

    /** Default variable settings */
    pm->hasInit = 0;

    pm->pcmframes = 1;
    pm->freqframes = 0;
    pm->totalframes = 1;
 
    pm->studio = 0;

    pm->active_preset = NULL;

    /** Allocate a new render target */
#ifdef PANTS
    if ( pm->renderTarget ) {
        if ( pm->renderTarget->renderTarget ) {
            /** Free existing */
            free( pm->renderTarget->renderTarget );
	    pm->renderTarget->renderTarget = NULL;
          }
        free( pm->renderTarget );
        pm->renderTarget = NULL;
      }
#endif
    pm->renderTarget = (RenderTarget *)wipemalloc( sizeof( RenderTarget ) );        
    pm->renderTarget->origContext = NULL;
    pm->renderTarget->pbufferContext = NULL;
    pm->renderTarget->pbuffer = NULL;

    /** Configurable engine variables */
    pm->renderTarget->texsize = 512;
    pm->fvw = 800;
    pm->fvh = 600;
    pm->wvw = 512;
    pm->wvh = 512;
    pm->fullscreen = 0;

    /** Configurable mesh size */
    pm->gx = 48;
    pm->gy = 36;

    /** PCM data */
    pm->maxsamples = 2048;
    pm->numsamples = 0;
    pm->pcmdataL = NULL;
    pm->pcmdataR = NULL;

    /** Frames per preset */
    pm->avgtime = 500;

    /** Other stuff... */
    pm->correction = 1;
    pm->vol = 0;

    /** Per pixel equation variables */
    pm->gridx = NULL;
    pm->gridy = NULL;
    pm->origtheta = NULL;
    pm->origrad = NULL;
    pm->origx = NULL;
    pm->origy = NULL;

    /** More other stuff */
    pm->mspf = 0;
    pm->timed = 0;
    pm->timestart = 0;
    pm->timestart = 0;
    pm->nohard = 0;
    pm->count = 0;
    pm->realfps = 0;
    pm->fpsstart = 0;

    projectM_resetengine( pm );
  }

void projectM_init( projectM_t *pm ) {

    /** Initialise engine variables */
    projectM_initengine( pm );

    DWRITE("projectM plugin: Initializing\n");

    /** Initialise start time */
#ifndef WIN32
    gettimeofday(&pm->startTime, NULL);
#else
    pm->startTime = GetTickCount();
#endif /** !WIN32 */

    /** Nullify frame stash */
    pm->fbuffer = NULL;

    /** Initialise per-pixel matrix calculations */
    init_per_pixel_matrices( pm );

    /* Preset loading function */
    initPresetLoader();
    switchToIdlePreset();

printf( "pre init_display()\n" );
//  init_display(pm->vw,pm->vh,pm->fullscreen);
  //  printf("FPS %d \n", fps);
printf( "post init_display()\n" );

  pm->mspf=1000/pm->fps;


   
  //create off-screen pbuffer (or not if unsupported)
//  CreateRenderTarget(pm->renderTarget->texsize, &pm->textureID, &pm->renderTarget);
printf( "post CreaterenderTarget\n" );
  

    /** Allocate PCM data structures */
    pm->pcmdataL=(double *)wipemalloc(pm->maxsamples*sizeof(double));
    pm->pcmdataR=(double *)wipemalloc(pm->maxsamples*sizeof(double));

DWRITE( "post initMenu()\n" );

    printf("mesh: %d %d\n", pm->gx,pm->gy );
    printf( "maxsamples: %d\n", pm->maxsamples );

  initPCM(pm->maxsamples);
  initBeatDetect();
DWRITE( "post PCM init\n" );

    pm->hasInit = 1;
printf( "exiting projectM_init()\n" );
}

void free_per_pixel_matrices( projectM_t *pm )
{
  int x;

 for(x = 0; x < pm->gx; x++)
    {
      
      free(pm->gridx[x]);
      free(pm->gridy[x]); 
      free(pm->origtheta[x]);
      free(pm->origrad[x]);
      free(pm->origx[x]);
      free(pm->origy[x]);
      free(pm->x_mesh[x]);
      free(pm->y_mesh[x]);
      free(pm->rad_mesh[x]);
      free(pm->theta_mesh[x]);
      
    }

  
  free(pm->origx);
  free(pm->origy);
  free(pm->gridx);
  free(pm->gridy);
  free(pm->x_mesh);
  free(pm->y_mesh);
  free(pm->rad_mesh);
  free(pm->theta_mesh);

  pm->origx = NULL;
  pm->origy = NULL;
  pm->gridx = NULL;
  pm->gridy = NULL;
  pm->x_mesh = NULL;
  pm->y_mesh = NULL;
  pm->rad_mesh = NULL;
  pm->theta_mesh = NULL;
}


void init_per_pixel_matrices( projectM_t *pm )
{
  int x,y; 

  pm->gridx=(double **)wipemalloc(pm->gx * sizeof(double *));
  pm->gridy=(double **)wipemalloc(pm->gx * sizeof(double *));

  pm->origx=(double **)wipemalloc(pm->gx * sizeof(double *));
  pm->origy=(double **)wipemalloc(pm->gx * sizeof(double *)); 
  pm->origrad=(double **)wipemalloc(pm->gx * sizeof(double *));
  pm->origtheta=(double **)wipemalloc(pm->gx * sizeof(double *));
  
  pm->x_mesh=(double **)wipemalloc(pm->gx * sizeof(double *));
  pm->y_mesh=(double **)wipemalloc(pm->gx * sizeof(double *));
  pm->rad_mesh=(double **)wipemalloc(pm->gx * sizeof(double *));
  pm->theta_mesh=(double **)wipemalloc(pm->gx * sizeof(double *));

  pm->sx_mesh=(double **)wipemalloc(pm->gx * sizeof(double *));
  pm->sy_mesh=(double **)wipemalloc(pm->gx * sizeof(double *));
  pm->dx_mesh=(double **)wipemalloc(pm->gx * sizeof(double *));
  pm->dy_mesh=(double **)wipemalloc(pm->gx * sizeof(double *));
  pm->cx_mesh=(double **)wipemalloc(pm->gx * sizeof(double *));
  pm->cy_mesh=(double **)wipemalloc(pm->gx * sizeof(double *));
  pm->zoom_mesh=(double **)wipemalloc(pm->gx * sizeof(double *));
  pm->zoomexp_mesh=(double **)wipemalloc(pm->gx * sizeof(double *));
  pm->rot_mesh=(double **)wipemalloc(pm->gx * sizeof(double *));
 
  

   for(x = 0; x < pm->gx; x++)
    {
      pm->gridx[x] = (double *)wipemalloc(pm->gy * sizeof(double));
      pm->gridy[x] = (double *)wipemalloc(pm->gy * sizeof(double)); 

      pm->origtheta[x] = (double *)wipemalloc(pm->gy * sizeof(double));
      pm->origrad[x] = (double *)wipemalloc(pm->gy * sizeof(double));
      pm->origx[x] = (double *)wipemalloc(pm->gy * sizeof(double));
      pm->origy[x] = (double *)wipemalloc(pm->gy * sizeof(double));
     
      pm->x_mesh[x] = (double *)wipemalloc(pm->gy * sizeof(double));
      pm->y_mesh[x] = (double *)wipemalloc(pm->gy * sizeof(double));

      pm->rad_mesh[x] = (double *)wipemalloc(pm->gy * sizeof(double));
      pm->theta_mesh[x] = (double *)wipemalloc(pm->gy * sizeof(double));

      pm->sx_mesh[x] = (double *)wipemalloc(pm->gy * sizeof(double));
      pm->sy_mesh[x] = (double *)wipemalloc(pm->gy * sizeof(double));
      pm->dx_mesh[x] = (double *)wipemalloc(pm->gy * sizeof(double));
      pm->dy_mesh[x] = (double *)wipemalloc(pm->gy * sizeof(double));
      pm->cx_mesh[x] = (double *)wipemalloc(pm->gy * sizeof(double));
      pm->cy_mesh[x] = (double *)wipemalloc(pm->gy * sizeof(double));

      pm->zoom_mesh[x] = (double *)wipemalloc(pm->gy * sizeof(double));
      pm->zoomexp_mesh[x] = (double *)wipemalloc(pm->gy * sizeof(double));
      
      pm->rot_mesh[x] = (double *)wipemalloc(pm->gy * sizeof(double));
    
    }


  //initialize reference grid values
  for (x=0;x<pm->gx;x++)
    {
      for(y=0;y<pm->gy;y++)
	{
	   pm->origx[x][y]=x/(double)(pm->gx-1);
	   pm->origy[x][y]=-((y/(double)(pm->gy-1))-1);
	   pm->origrad[x][y]=hypot((pm->origx[x][y]-.5)*2,(pm->origy[x][y]-.5)*2) * .7071067;
  	   pm->origtheta[x][y]=atan2(((pm->origy[x][y]-.5)*2),((pm->origx[x][y]-.5)*2));
	   pm->gridx[x][y]=pm->origx[x][y]*pm->renderTarget->texsize;
	   pm->gridy[x][y]=pm->origy[x][y]*pm->renderTarget->texsize;
	}}
}



//calculate matrices for per_pixel
void do_per_pixel_math( projectM_t *pm )
{
  int x,y;

  
  
  double rotpp=0,rotx=0,roty=0;
   evalPerPixelEqns();


 if(!isPerPixelEqn(CX_OP))
       { 
      for (x=0;x<pm->gx;x++){
	for(y=0;y<pm->gy;y++){
	  pm->cx_mesh[x][y]=pm->cx;
	}}
    }

  if(!isPerPixelEqn(CY_OP))
        { 
      for (x=0;x<pm->gx;x++){
	for(y=0;y<pm->gy;y++){
	  pm->cy_mesh[x][y]=pm->cy;
	}}
    }
      
  if(isPerPixelEqn(ROT_OP))
    {
    

      for (x=0;x<pm->gx;x++){
	for(y=0;y<pm->gy;y++){
	  
       
	  pm->x_mesh[x][y]=pm->x_mesh[x][y]-pm->cx_mesh[x][y];
	  pm->y_mesh[x][y]=pm->y_mesh[x][y]-pm->cy_mesh[x][y];
	  rotx=(pm->x_mesh[x][y])*cos(pm->rot_mesh[x][y])-(pm->y_mesh[x][y])*sin(pm->rot_mesh[x][y]);
	  roty=(pm->x_mesh[x][y])*sin(pm->rot_mesh[x][y])+(pm->y_mesh[x][y])*cos(pm->rot_mesh[x][y]);
	  pm->x_mesh[x][y]=rotx+pm->cx_mesh[x][y];
	  pm->y_mesh[x][y]=roty+pm->cy_mesh[x][y];
	}}
    }
    
  

  if(!isPerPixelEqn(ZOOM_OP))
    {       
      for (x=0;x<pm->gx;x++){
	for(y=0;y<pm->gy;y++){
	  pm->zoom_mesh[x][y]=pm->zoom;
	}}
    }
 
  if(!isPerPixelEqn(ZOOMEXP_OP))
    {
      for (x=0;x<pm->gx;x++){
	for(y=0;y<pm->gy;y++){
	  pm->zoomexp_mesh[x][y]=pm->zoomexp;
	}}
    }
  
  
  //DO ZOOM PER PIXEL
  for (x=0;x<pm->gx;x++){
    for(y=0;y<pm->gy;y++){
     
      
      pm->x_mesh[x][y]=(pm->x_mesh[x][y]-.5)*2; 
      pm->y_mesh[x][y]=(pm->y_mesh[x][y]-.5)*2; 
      /*
      pm->x_mesh[x][y]=pm->x_mesh[x][y]/(((pm->zoom_mesh[x][y]-1)*(pow(pm->rad_mesh[x][y],pm->zoomexp_mesh[x][y])/pm->rad_mesh[x][y]))+1);
      pm->y_mesh[x][y]=pm->y_mesh[x][y]/(((pm->zoom_mesh[x][y]-1)*(pow(pm->rad_mesh[x][y],pm->zoomexp_mesh[x][y])/pm->rad_mesh[x][y]))+1);
      */
      pm->x_mesh[x][y]=pm->x_mesh[x][y]/(pow(pm->zoom_mesh[x][y], pow(pm->zoomexp_mesh[x][y],pm->rad_mesh[x][y])));
      pm->y_mesh[x][y]=pm->y_mesh[x][y]/(pow(pm->zoom_mesh[x][y], pow(pm->zoomexp_mesh[x][y],pm->rad_mesh[x][y])));

      pm->x_mesh[x][y]=(pm->x_mesh[x][y]*.5)+.5; 
      pm->y_mesh[x][y]=(pm->y_mesh[x][y]*.5)+.5; 
      
    }}
  

  
   if(isPerPixelEqn(SX_OP))
    {
      for (x=0;x<pm->gx;x++){
	for(y=0;y<pm->gy;y++){
	  pm->x_mesh[x][y]=((pm->x_mesh[x][y]-pm->cx_mesh[x][y])/pm->sx_mesh[x][y])+pm->cx_mesh[x][y];
	  
	}}
    }     
 
  if(isPerPixelEqn(SY_OP))
    {
      for (x=0;x<pm->gx;x++){
	for(y=0;y<pm->gy;y++){
	  
	  pm->y_mesh[x][y]=((pm->y_mesh[x][y]-pm->cy_mesh[x][y])/pm->sy_mesh[x][y])+pm->cy_mesh[x][y];
	  
	}}
    }    
 
  if(isPerPixelEqn(DX_OP))
    {
      for (x=0;x<pm->gx;x++){
	for(y=0;y<pm->gy;y++){
	  
	  pm->x_mesh[x][y]-=pm->dx_mesh[x][y];
	  
	}}
    }     
  
  if(isPerPixelEqn(DY_OP))
    {
      	  
      for (x=0;x<pm->gx;x++){
	for(y=0;y<pm->gy;y++){
	
	  pm->y_mesh[x][y]-=pm->dy_mesh[x][y];
	  
	}}
    }     
  
  
}

void reset_per_pixel_matrices( projectM_t *pm )
{
  int x,y;
  //memcpy(origx,origx_r,sizeof(double)*gy*gx);  memcpy(origy,origy_r,sizeof(double)*gy*gx);
   
    for (x=0;x<pm->gx;x++)
    {
      for(y=0;y<pm->gy;y++)
	{   
          pm->x_mesh[x][y]=pm->origx[x][y];
	  pm->y_mesh[x][y]=pm->origy[x][y];
	  pm->rad_mesh[x][y]=pm->origrad[x][y];
	  pm->theta_mesh[x][y]=pm->origtheta[x][y];	  
	  }}
 }

void rescale_per_pixel_matrices( projectM_t *pm ) {

    int x, y;

    for ( x = 0 ; x < pm->gx ; x++ ) {
        for ( y = 0 ; y < pm->gy ; y++ ) {
            pm->gridx[x][y]=pm->origx[x][y]*pm->renderTarget->texsize;
            pm->gridy[x][y]=pm->origy[x][y]*pm->renderTarget->texsize;

          }
      }
  }

void draw_custom_waves( projectM_t *pm )
{
  int x;
  
  custom_wave_t *wavecode;
  glPointSize(pm->renderTarget->texsize < 512 ? 1 : pm->renderTarget->texsize/512); 
  //printf("%d\n",wavecode);
  //  more=isMoreCustomWave();
  // printf("not inner loop\n");
  while ((wavecode = nextCustomWave()) != NULL)
    {
      //printf("begin inner loop\n");
      if(wavecode->enabled==1)
	{
	  // nextCustomWave();
	  
	  //glPushMatrix();
	  
	  //if(wavecode->bUseDots==1) glEnable(GL_LINE_STIPPLE);
	  if (wavecode->bAdditive==0)  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); 
	  else    glBlendFunc(GL_SRC_ALPHA, GL_ONE); 
	  if (wavecode->bDrawThick==1)  glLineWidth(pm->renderTarget->texsize < 512 ? 1 : 2*pm->renderTarget->texsize/512);
	  
	  //  xx= ((pcmdataL[x]-pcmdataL[x-1])*80*fWaveScale)*2;
	  //yy=pcmdataL[x]*80*fWaveScale,-1;
	  //glVertex3f( (wave_x*renderTarget->texsize)+(xx+yy)*cos(45), (wave_y*renderTarget->texsize)+(-yy+xx)*cos(45),-1);
	  // printf("samples: %d\n", wavecode->samples);
	  
	  getPCM(wavecode->value1,wavecode->samples,0,wavecode->bSpectrum,wavecode->smoothing,0);
	  getPCM(wavecode->value2,wavecode->samples,1,wavecode->bSpectrum,wavecode->smoothing,0);
	  // printf("%f\n",pcmL[0]);
	  for(x=0;x<wavecode->samples;x++)
	    {wavecode->value1[x]=wavecode->value1[x]*wavecode->scaling;}
	  
	  for(x=0;x<wavecode->samples;x++)
	    {wavecode->value2[x]=wavecode->value2[x]*wavecode->scaling;}

	   for(x=0;x<wavecode->samples;x++)
	     {wavecode->sample_mesh[x]=((double)x)/((double)(wavecode->samples-1));}
	  
	  // printf("mid inner loop\n");  
	  evalPerPointEqns();
	 /* 
	  if(!isPerPointEquation("x"))
	  {for(x=0;x<wavecode->samples;x++)
	    {cw_x[x]=0;} }	   
	  
	  if(!isPerPointEquation(Y_POINT_OP))
	  {for(x=0;x<wavecode->samples;x++)
	    {cw_y[x]=0;}}	  
	  
	  if(!isPerPointEquation(R_POINT_OP))
	  {for(x=0;x<wavecode->samples;x++)
	    {cw_r[x]=wavecode->r;}}
	  if(!isPerPointEquation(G_POINT_OP)) 
	  {for(x=0;x<wavecode->samples;x++)
	  {cw_g[x]=wavecode->g;}}
	  if(!isPerPointEquation(B_POINT_OP))
	  {for(x=0;x<wavecode->samples;x++)
	    {cw_b[x]=wavecode->b;}}
	  if(!isPerPointEquation(A_POINT_OP))
	 {for(x=0;x<wavecode->samples;x++)
	    {cw_a[x]=wavecode->a;}}
	 */
	  //put drawing code here
	  if (wavecode->bUseDots==1)   glBegin(GL_POINTS);
	  else   glBegin(GL_LINE_STRIP);
	  
	  for(x=0;x<wavecode->samples;x++)
	    {
	      //	      printf("x:%f y:%f a:%f g:%f %f\n", wavecode->x_mesh[x], wavecode->y_mesh[x], wavecode->a_mesh[x], wavecode->g_mesh[x], wavecode->sample_mesh[x]); 
	      glColor4f(wavecode->r_mesh[x],wavecode->g_mesh[x],wavecode->b_mesh[x],wavecode->a_mesh[x]);
	      glVertex3f(wavecode->x_mesh[x]*pm->renderTarget->texsize,-(wavecode->y_mesh[x]-1)*pm->renderTarget->texsize,-1);
	    }
	  glEnd();
	  glPointSize(pm->renderTarget->texsize < 512 ? 1 : pm->renderTarget->texsize/512); 
	  glLineWidth(pm->renderTarget->texsize < 512 ? 1 : pm->renderTarget->texsize/512); 
	  glDisable(GL_LINE_STIPPLE); 
	  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); 
	  //  glPopMatrix();
	  
	}
      
    }
}

void draw_shapes( projectM_t *pm )
{ 
  int i;

  double theta;
  double radius;

  custom_shape_t *shapecode;
 
  double pi = 3.14159265;
  double start,inc,xval,yval;
  
  float t;

  //  more=isMoreCustomWave();
  // printf("not inner loop\n");
  
  while ((shapecode = nextCustomShape()) != NULL)
    {

      if(shapecode->enabled==1)
	{
	  // printf("drawing shape %f\n",shapecode->ang);
	  shapecode->y=-((shapecode->y)-1);
	  radius=.5;
	  shapecode->radius=shapecode->radius*(pm->renderTarget->texsize*.707*.707*.707*1.04);
	  //Additive Drawing or Overwrite
	  if (shapecode->additive==0)  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); 
	  else    glBlendFunc(GL_SRC_ALPHA, GL_ONE); 
	  
	  glMatrixMode(GL_MODELVIEW);
	  	   glPushMatrix(); 
		   if(pm->correction)
		     {		     
		       glTranslatef(pm->renderTarget->texsize*.5,pm->renderTarget->texsize*.5, 0);
		       glScalef(1.0,pm->vw/(double)pm->vh,1.0);  
		       glTranslatef((-pm->renderTarget->texsize*.5) ,(-pm->renderTarget->texsize*.5),0);   
		     }
	 
	
	   xval=shapecode->x*pm->renderTarget->texsize;
	   yval=shapecode->y*pm->renderTarget->texsize;
	  
	  if (shapecode->textured)
	    {
	      glMatrixMode(GL_TEXTURE);
	       glPushMatrix();
	      glLoadIdentity();
	      
	      glTranslatef(.5,.5, 0);
	      if (pm->correction) glScalef(1,pm->vw/(double)pm->vh,1);
   
	      glRotatef((shapecode->tex_ang*360/6.280), 0, 0, 1);
	      
	      glScalef(1/(shapecode->tex_zoom),1/(shapecode->tex_zoom),1); 
	      
	      // glScalef(1,vh/(double)vw,1);
	      glTranslatef((-.5) ,(-.5),0);  
	      // glScalef(1,pm->vw/(double)pm->vh,1);
	      glEnable(GL_TEXTURE_2D);
	      	     

	      glBegin(GL_TRIANGLE_FAN);
	      
	       glColor4f(shapecode->r,shapecode->g,shapecode->b,shapecode->a);
	   
	      glTexCoord2f(.5,.5);
	      glVertex3f(xval,yval,-1);	 
	      glColor4f(shapecode->r2,shapecode->g2,shapecode->b2,shapecode->a2);

	      for ( i=1;i<shapecode->sides+2;i++)
		{
		 
		  //		  theta+=inc;
		  //  glColor4f(shapecode->r2,shapecode->g2,shapecode->b2,shapecode->a2);
		  //glTexCoord2f(radius*cos(theta)+.5 ,radius*sin(theta)+.5 );
		  //glVertex3f(shapecode->radius*cos(theta)+xval,shapecode->radius*sin(theta)+yval,-1);  
		  t = (i-1)/(float)shapecode->sides;
		  
		  glTexCoord2f(  0.5f + 0.5f*cosf(t*3.1415927f*2 + shapecode->tex_ang + 3.1415927f*0.25f)/shapecode->tex_zoom, 0.5f + 0.5f*sinf(t*3.1415927f*2 + shapecode->tex_ang + 3.1415927f*0.25f)/shapecode->tex_zoom);
		   glVertex3f(shapecode->radius*cosf(t*3.1415927f*2 + shapecode->radius + 3.1415927f*0.25f)+xval, shapecode->radius*sinf(t*3.1415927f*2 + shapecode->radius + 3.1415927f*0.25f)+yval,-1);      
		}	
	      glEnd();

	    
	      
	    
	      glDisable(GL_TEXTURE_2D);
	       glPopMatrix();
	      glMatrixMode(GL_MODELVIEW);          
	    }
	  else{//Untextured (use color values)
	    //printf("untextured %f %f %f @:%f,%f %f %f\n",shapecode->a2,shapecode->a,shapecode->border_a, shapecode->x,shapecode->y,shapecode->radius,shapecode->ang);
	    //draw first n-1 triangular pieces
	      glBegin(GL_TRIANGLE_FAN);
	      
	      glColor4f(shapecode->r,shapecode->g,shapecode->b,shapecode->a);
	    
	      // glTexCoord2f(.5,.5);
	      glVertex3f(xval,yval,-1);	 
	     glColor4f(shapecode->r2,shapecode->g2,shapecode->b2,shapecode->a2);

	      for ( i=1;i<shapecode->sides+2;i++)
		{
		  
		  //theta+=inc;
		  //  glColor4f(shapecode->r2,shapecode->g2,shapecode->b2,shapecode->a2);
		  //  glTexCoord2f(radius*cos(theta)+.5 ,radius*sin(theta)+.5 );
		  //glVertex3f(shapecode->radius*cos(theta)+xval,shapecode->radius*sin(theta)+yval,-1);	  

		  t = (i-1)/(float)shapecode->sides;
		  	  
		   glVertex3f(shapecode->radius*cosf(t*3.1415927f*2 + shapecode->radius + 3.1415927f*0.25f)+xval, shapecode->radius*sinf(t*3.1415927f*2 + shapecode->radius + 3.1415927f*0.25f)+yval,-1);      
		}	
	      glEnd();

	   	 
	  }
	    if (pm->bWaveThick==1)  glLineWidth(pm->renderTarget->texsize < 512 ? 1 : 2*pm->renderTarget->texsize/512);
	      glBegin(GL_LINE_LOOP);
	      glColor4f(shapecode->border_r,shapecode->border_g,shapecode->border_b,shapecode->border_a);
	      for ( i=1;i<shapecode->sides+1;i++)
		{

		  t = (i-1)/(float)shapecode->sides;
		  	  
		  glVertex3f(shapecode->radius*cosf(t*3.1415927f*2 + shapecode->radius + 3.1415927f*0.25f)+xval, shapecode->radius*sinf(t*3.1415927f*2 + shapecode->radius + 3.1415927f*0.25f)+yval,-1); 

		  //theta+=inc;
		  //glVertex3f(shapecode->radius*cos(theta)+xval,shapecode->radius*sin(theta)+yval,-1);
		}
	      glEnd();
	  if (pm->bWaveThick==1)  glLineWidth(pm->renderTarget->texsize < 512 ? 1 : pm->renderTarget->texsize/512);
	  
	  glPopMatrix();
	}
    }
  
}


void draw_waveform( projectM_t *pm )
{

  int x;
  
  double r,theta;
 
  double offset,scale,dy2_adj;

  double co;  
  
  double wave_x_temp=0;
  double wave_y_temp=0;
  double dy_adj;
  double xx,yy; 
    
  modulate_opacity_by_volume(pm); 
  maximize_colors(pm);
  
  if(pm->bWaveDots==1) glEnable(GL_LINE_STIPPLE);
  
  offset=(pm->wave_x-.5)*pm->renderTarget->texsize;
  scale=(float)pm->renderTarget->texsize/505.0;


  

  //Thick wave drawing
  if (pm->bWaveThick==1)  glLineWidth( (pm->renderTarget->texsize < 512 ) ? 1 : 2*pm->renderTarget->texsize/512);

  //Additive wave drawing (vice overwrite)
  if (pm->bAdditiveWaves==0)  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); 
  else    glBlendFunc(GL_SRC_ALPHA, GL_ONE); 
 
      switch(pm->nWaveMode)
	{
	  
	case 8://monitor

	  glPushMatrix();
	  	  
	  glTranslatef(pm->renderTarget->texsize*.5,pm->renderTarget->texsize*.5, 0);
	  glRotated(-pm->wave_mystery*90,0,0,1);

	     glTranslatef(-pm->renderTarget->texsize*.5,-pm->renderTarget->texsize*.825, 0);
	     
	     /*
	     for (x=0;x<16;x++)
	       {
		 glBegin(GL_LINE_STRIP);
		 glColor4f(1.0-(x/15.0),.5,x/15.0,1.0);
		 glVertex3f((pm->totalframes%256)*2*scale, -pm->beat_val[x]*pm->fWaveScale+renderTarget->texsize*wave_y,-1);
		 glColor4f(.5,.5,.5,1.0);
		 glVertex3f((pm->totalframes%256)*2*scale, pm->renderTarget->texsize*pm->wave_y,-1);   
		 glColor4f(1.0,1.0,0,1.0);
		 //glVertex3f((pm->totalframes%256)*scale*2, pm->beat_val_att[x]*pm->fWaveScale+pm->renderTarget->texsize*pm->wave_y,-1);
		 glEnd();
	       
		 glTranslatef(0,pm->renderTarget->texsize*(1/36.0), 0);
	       }
	  */
	     
	    glTranslatef(0,pm->renderTarget->texsize*(1/18.0), 0);

 
	     glBegin(GL_LINE_STRIP);
	     glColor4f(1.0,1.0,0.5,1.0);
	     glVertex3f((pm->totalframes%256)*2*scale, pm->treb_att*5*pm->fWaveScale+pm->renderTarget->texsize*pm->wave_y,-1);
	     glColor4f(.2,.2,.2,1.0);
	     glVertex3f((pm->totalframes%256)*2*scale, pm->renderTarget->texsize*pm->wave_y,-1);   
	     glColor4f(1.0,1.0,0,1.0);
	     glVertex3f((pm->totalframes%256)*scale*2, pm->treb*-5*pm->fWaveScale+pm->renderTarget->texsize*pm->wave_y,-1);
	     glEnd();
	       
	       glTranslatef(0,pm->renderTarget->texsize*.075, 0);
	     glBegin(GL_LINE_STRIP);
	     glColor4f(0,1.0,0.0,1.0);
	     glVertex3f((pm->totalframes%256)*2*scale, pm->mid_att*5*pm->fWaveScale+pm->renderTarget->texsize*pm->wave_y,-1);
	     glColor4f(.2,.2,.2,1.0);
	     glVertex3f((pm->totalframes%256)*2*scale, pm->renderTarget->texsize*pm->wave_y,-1);   
	     glColor4f(.5,1.0,.5,1.0);
	     glVertex3f((pm->totalframes%256)*scale*2, pm->mid*-5*pm->fWaveScale+pm->renderTarget->texsize*pm->wave_y,-1);
	     glEnd(); 
	  
	   
	     glTranslatef(0,pm->renderTarget->texsize*.075, 0);
	     glBegin(GL_LINE_STRIP);
	     glColor4f(1.0,0,0,1.0);
	     glVertex3f((pm->totalframes%256)*2*scale, pm->bass_att*5*pm->fWaveScale+pm->renderTarget->texsize*pm->wave_y,-1);
	     glColor4f(.2,.2,.2,1.0);
	     glVertex3f((pm->totalframes%256)*2*scale, pm->renderTarget->texsize*pm->wave_y,-1);   
	     glColor4f(1.0,.5,.5,1.0);
	     glVertex3f((pm->totalframes%256)*scale*2, pm->bass*-5*pm->fWaveScale+pm->renderTarget->texsize*pm->wave_y,-1);
	     glEnd(); 
	     

	     glPopMatrix();
	  break;
	  
	case 0://circular waveforms 
	  //  double co;
	  glPushMatrix(); 

	  glTranslatef(pm->renderTarget->texsize*.5,pm->renderTarget->texsize*.5, 0);
	  glScalef(1.0,pm->vw/(double)pm->vh,1.0);
	  glTranslatef((-pm->renderTarget->texsize*.5) ,(-pm->renderTarget->texsize*.5),0);   

	  pm->wave_y=-1*(pm->wave_y-1.0);
 
	  glBegin(GL_LINE_STRIP);
	  
	  for ( x=0;x<pm->numsamples;x++)
	    {
	      co= -(fabs(x-((pm->numsamples*.5)-1))/pm->numsamples)+1;
	      // printf("%d %f\n",x,co);
	      theta=x*(6.28/pm->numsamples);
	      r= ((1+2*pm->wave_mystery)*(pm->renderTarget->texsize/5.0)+
		  ( co*pm->pcmdataL[x]+ (1-co)*pm->pcmdataL[-(x-(pm->numsamples-1))])
		  *25*pm->fWaveScale);
	      
	      glVertex3f(r*cos(theta)+(pm->wave_x*pm->renderTarget->texsize),r*sin(theta)+(pm->wave_y*pm->renderTarget->texsize),-1);
	    }

	  r= ( (1+2*pm->wave_mystery)*(pm->renderTarget->texsize/5.0)+
	       (0.5*pm->pcmdataL[0]+ 0.5*pm->pcmdataL[pm->numsamples-1])
	       *20*pm->fWaveScale);
      
      glVertex3f(r*cos(0)+(pm->wave_x*pm->renderTarget->texsize),r*sin(0)+(pm->wave_y*pm->renderTarget->texsize),-1);

	  glEnd();
	  /*
	  glBegin(GL_LINE_LOOP);
	  
	  for ( x=0;x<(512/pcmbreak);x++)
	    {
	      theta=(blockstart+x)*((6.28*pcmbreak)/512.0);
	      r= ((1+2*pm->wave_mystery)*(pm->renderTarget->texsize/5.0)+fdata_buffer[fbuffer][0][blockstart+x]*.0025*pm->fWaveScale);
	      
	      glVertex3f(r*cos(theta)+(pm->wave_x*pm->renderTarget->texsize),r*sin(theta)+(wave_y*pm->renderTarget->texsize),-1);
	    }
	  glEnd();
	  */
	  glPopMatrix();

	  break;	
	
	case 1://circularly moving waveform
	  //  double co;
	  glPushMatrix(); 
	  
	  glTranslatef(pm->renderTarget->texsize*.5,pm->renderTarget->texsize*.5, 0);
	  glScalef(1.0,pm->vw/(double)pm->vh,1.0);
	  glTranslatef((-pm->renderTarget->texsize*.5) ,(-pm->renderTarget->texsize*.5),0);   

	  pm->wave_y=-1*(pm->wave_y-1.0);

	  glBegin(GL_LINE_STRIP);
	  //theta=(frame%512)*(6.28/512.0);

	  for ( x=1;x<512;x++)
	    {
	      co= -(abs(x-255)/512.0)+1;
	      // printf("%d %f\n",x,co);
	      theta=((pm->frame%256)*(2*6.28/512.0))+pm->pcmdataL[x]*.2*pm->fWaveScale;
	      r= ((1+2*pm->wave_mystery)*(pm->renderTarget->texsize/5.0)+
		   (pm->pcmdataL[x]-pm->pcmdataL[x-1])*80*pm->fWaveScale);
	      
	      glVertex3f(r*cos(theta)+(pm->wave_x*pm->renderTarget->texsize),r*sin(theta)+(pm->wave_y*pm->renderTarget->texsize),-1);
	    }

	  glEnd(); 
	  /*
	  pm->wave_y=-1*(pm->wave_y-1.0);  
	  wave_x_temp=(pm->wave_x*.75)+.125;	
	  wave_x_temp=-(wave_x_temp-1); 

	  glBegin(GL_LINE_STRIP);

	    
	  
	  for (x=0; x<512-32; x++)
	    {
	      float rad = (.53 + 0.43*pm->pcmdataR[x]) + pm->wave_mystery;
	      float ang = pm->pcmdataL[x+32] * 1.57f + pm->Time*2.3f;
	      glVertex3f((rad*cosf(ang)*.2*scale*pm->fWaveScale + wave_x_temp)*pm->renderTarget->texsize,(rad*sinf(ang)*pm->fWaveScale*.2*scale + pm->wave_y)*pm->renderTarget->texsize,-1);
	      
	    }
	  glEnd();
	  */
	  glPopMatrix();

	  break;
	  
	case 2://EXPERIMENTAL

	  glPushMatrix();

	  /*
	  pm->wave_y=-1*(pm->wave_y-1.0);
	  glPushMatrix();	  	 	  
	  glBegin(GL_LINE_STRIP);
	  // double xr= (wave_x*renderTarget->texsize), yr=(wave_y*renderTarget->texsize);
	  xx=0;
	  for ( x=1;x<512;x++)
	    {
	      //xx = ((pcmdataL[x]-pcmdataL[x-1])*80*fWaveScale)*2;
	      xx += (pm->pcmdataL[x]*pm->fWaveScale);
	       yy= pm->pcmdataL[x]*80*pm->fWaveScale;
	       //  glVertex3f( (wave_x*renderTarget->texsize)+(xx+yy)*2, (wave_y*renderTarget->texsize)+(xx-yy)*2,-1);
 glVertex3f( (pm->wave_x*pm->renderTarget->texsize)+(xx)*2, (pm->wave_y*pm->renderTarget->texsize)+(yy)*2,-1);


	       //   xr+=fdata_buffer[fbuffer][0][x] *.0005* fWaveScale;
	       //yr=(fdata_buffer[fbuffer][0][x]-fdata_buffer[fbuffer][0][x-1])*.05*fWaveScale+(wave_y*renderTarget->texsize);
	      //glVertex3f(xr,yr,-1);

	    }
	  glEnd(); 
	  */

	  pm->wave_y=-1*(pm->wave_y-1.0);  
	  //wave_x_temp=(pm->wave_x*.75)+.125;	
	  //wave_x_temp=-(wave_x_temp-1); 
	  
	 

	  glBegin(GL_LINE_STRIP);

	  for (x=0; x<512-32; x++)
	    {
	      
	      glVertex3f((pm->pcmdataR[x]*pm->fWaveScale*0.5 + pm->wave_x)*pm->renderTarget->texsize,( (pm->pcmdataL[x+32]*pm->fWaveScale*0.5 + pm->wave_y)*pm->renderTarget->texsize ),-1);
 
	    }
	  glEnd();	
	  
    


	  glPopMatrix();
	  break;

	case 3://EXPERIMENTAL
	  glPushMatrix();	  
	  /*	 
	   pm->wave_y=-1*(pm->wave_y-1.0);
	  glBegin(GL_LINE_STRIP);
	  	 
	   
	  for ( x=1;x<512;x++)
	    {
	      xx= ((pm->pcmdataL[x]-pm->pcmdataL[x-1])*80*pm->fWaveScale)*2;
	      yy=pm->pcmdataL[x]*80*pm->fWaveScale,-1;
	      glVertex3f( (pm->wave_x*pm->renderTarget->texsize)+(xx+yy)*cos(45), (pm->wave_y*pm->renderTarget->texsize)+(-yy+xx)*cos(45),-1);
	    }
	  glEnd(); 
	  */
	  
	  pm->wave_y=-1*(pm->wave_y-1.0);  
	  //wave_x_temp=(pm->wave_x*.75)+.125;	
	  //wave_x_temp=-(wave_x_temp-1); 
	  
	 

	  glBegin(GL_LINE_STRIP);

	  for (x=0; x<512-32; x++)
	    {
	      
	      glVertex3f((pm->pcmdataR[x] * pm->fWaveScale*0.5 + pm->wave_x)*pm->renderTarget->texsize,( (pm->pcmdataL[x+32]*pm->fWaveScale*0.5 + pm->wave_y) * pm->renderTarget->texsize ),-1);
 
	    }
	  glEnd();	
	  
	  glPopMatrix();
	  break;

	case 4://single x-axis derivative waveform
	  glPushMatrix();
	   pm->wave_y=-1*(pm->wave_y-1.0);	  
glTranslatef(pm->renderTarget->texsize*.5,pm->renderTarget->texsize*.5, 0);
	  glRotated(-pm->wave_mystery*90,0,0,1);
	     glTranslatef(-pm->renderTarget->texsize*.5,-pm->renderTarget->texsize*.5, 0);
	  pm->wave_x=(pm->wave_x*.75)+.125;	  pm->wave_x=-(pm->wave_x-1); 
	  glBegin(GL_LINE_STRIP);
	 
	  for ( x=1;x<512;x++)
	    {
	      dy_adj=  pm->pcmdataL[x]*20*pm->fWaveScale-pm->pcmdataL[x-1]*20*pm->fWaveScale;
	      glVertex3f((x*scale)+dy_adj, pm->pcmdataL[x]*20*pm->fWaveScale+pm->renderTarget->texsize*pm->wave_x,-1);
	    }
	  glEnd(); 
	  glPopMatrix();
	  break;

	case 5://EXPERIMENTAL
	  glPushMatrix();
	  	  
	  /*
	  pm->wave_y=-1*(pm->wave_y-1.0);  
	  wave_x_temp=(pm->wave_x*.75)+.125;
	  wave_x_temp=-(wave_x_temp-1); 
	  glBegin(GL_LINE_STRIP);
	 	 
	  for ( x=1;x<512;x++)
	    {
	      dy2_adj=  (pm->pcmdataL[x]-pm->pcmdataL[x-1])*20*pm->fWaveScale;
	      glVertex3f((wave_x_temp*pm->renderTarget->texsize)+dy2_adj*2, pm->pcmdataL[x]*20*pm->fWaveScale+pm->renderTarget->texsize*pm->wave_y,-1);
	    }
	  glEnd(); 
	  */

	  /*
	switch(pm->renderTarget->texsize)
			{
			case 256:  alpha *= 0.07f; break;
			case 512:  alpha *= 0.09f; break;
			case 1024: alpha *= 0.11f; break;
			case 2048: alpha *= 0.13f; break;
			}

		
			if (alpha < 0) alpha = 0;
			if (alpha > 1) alpha = 1;
	  */			
	  
	  pm->wave_y=-1*(pm->wave_y-1.0);  
	  //wave_x_temp=(pm->wave_x*.75)+.125;	
	  //wave_x_temp=-(wave_x_temp-1); 
	  
	  float cos_rot = cosf(pm->Time*0.3f);
	  float sin_rot = sinf(pm->Time*0.3f);

	  glBegin(GL_LINE_STRIP);

	  for (x=0; x<512; x++)
	    {
	      //pm->pcmdataR[x]=(pm->pcmdataR[x]-0.5)*2;  
	      //pm->pcmdataL[x]=(pm->pcmdataL[x]-0.5)*2;
	      float x0 = (pm->pcmdataR[x]*pm->pcmdataL[x+32] + pm->pcmdataL[x+32]*pm->pcmdataR[x]);
	      float y0 = (pm->pcmdataR[x]*pm->pcmdataR[x] - pm->pcmdataL[x+32]*pm->pcmdataL[x+32]);
	      glVertex3f(((x0*cos_rot - y0*sin_rot)*pm->fWaveScale*0.5 + pm->wave_x)*pm->renderTarget->texsize,( (x0*sin_rot + y0*cos_rot)*pm->fWaveScale*0.5 + pm->wave_y)*pm->renderTarget->texsize ,-1);
 
	    }
	  glEnd();	
	  
	 
	  
	  glPopMatrix();
	  break;

	case 6://single waveform


	  glTranslatef(0,0, -1);
	  
	  //glMatrixMode(GL_MODELVIEW);
	  glPushMatrix();
	  //	  	  glLoadIdentity();
	  
	  glTranslatef(pm->renderTarget->texsize*.5,pm->renderTarget->texsize*.5, 0);
	  glRotated(-pm->wave_mystery*90,0,0,1);
	  
	  wave_x_temp=-2*0.4142*(fabs(fabs(pm->wave_mystery)-.5)-.5);
	  glScalef(1.0+wave_x_temp,1.0,1.0);
	  glTranslatef(-pm->renderTarget->texsize*.5,-pm->renderTarget->texsize*.5, 0);
	  wave_x_temp=-1*(pm->wave_x-1.0);

	  glBegin(GL_LINE_STRIP);
	  //	  wave_x_temp=(wave_x*.75)+.125;	  
	  //	  wave_x_temp=-(wave_x_temp-1);
	  for ( x=0;x<pm->numsamples;x++)
	    {
     
	      //glVertex3f(x*scale, fdata_buffer[fbuffer][0][blockstart+x]*.0012*fWaveScale+renderTarget->texsize*wave_x_temp,-1);
	      glVertex3f(x*pm->renderTarget->texsize/(double)pm->numsamples, pm->pcmdataR[x]*20*pm->fWaveScale+pm->renderTarget->texsize*wave_x_temp,-1);

	      //glVertex3f(x*scale, renderTarget->texsize*wave_y_temp,-1);
	    }
	  //	  printf("%f %f\n",renderTarget->texsize*wave_y_temp,wave_y_temp);
	  glEnd(); 
	    glPopMatrix();
	  break;
	  
	case 7://dual waveforms

	  glPushMatrix();  

	  glTranslatef(pm->renderTarget->texsize*.5,pm->renderTarget->texsize*.5, 0);
	  glRotated(-pm->wave_mystery*90,0,0,1);
	  
	  wave_x_temp=-2*0.4142*(fabs(fabs(pm->wave_mystery)-.5)-.5);
	  glScalef(1.0+wave_x_temp,1.0,1.0);
	     glTranslatef(-pm->renderTarget->texsize*.5,-pm->renderTarget->texsize*.5, 0);

         wave_y_temp=-1*(pm->wave_x-1);

		  glBegin(GL_LINE_STRIP);
	 
	  for ( x=0;x<pm->numsamples;x++)
	    {
     
	      glVertex3f((x*pm->renderTarget->texsize)/(double)pm->numsamples, pm->pcmdataL[x]*20*pm->fWaveScale+pm->renderTarget->texsize*(wave_y_temp+(pm->wave_y*pm->wave_y*.5)),-1);
	    }
	  glEnd(); 

	  glBegin(GL_LINE_STRIP);
	 

	  for ( x=0;x<pm->numsamples;x++)
	    {
     
	      glVertex3f((x*pm->renderTarget->texsize)/(double)pm->numsamples, pm->pcmdataR[x]*20*pm->fWaveScale+pm->renderTarget->texsize*(wave_y_temp-(pm->wave_y*pm->wave_y*.5)),-1);
	    }
	  glEnd(); 
	  glPopMatrix();
     break;
     
	default:  
 glBegin(GL_LINE_LOOP);
	  
	  for ( x=0;x<512;x++)
	    {
	      theta=(x)*(6.28/512.0);
	      r= (pm->renderTarget->texsize/5.0+pm->pcmdataL[x]*.002);
	      
	      glVertex3f(r*cos(theta)+(pm->wave_x*pm->renderTarget->texsize),r*sin(theta)+(pm->wave_y*pm->renderTarget->texsize),-1);
	    }
	  glEnd();

glBegin(GL_LINE_STRIP);
	
	  for ( x=0;x<512;x++)
	    {
	      glVertex3f(x*scale, pm->pcmdataL[x]*20*pm->fWaveScale+(pm->renderTarget->texsize*(pm->wave_x+.1)),-1);
	    }
	  glEnd();
	  
	  glBegin(GL_LINE_STRIP);
	  
	 for ( x=0;x<512;x++)
	    {
	      glVertex3f(x*scale, pm->pcmdataR[x]*20*pm->fWaveScale+(pm->renderTarget->texsize*(pm->wave_x-.1)),-1);
	      
	    }
	  glEnd();
     break;
         if (pm->bWaveThick==1)  glLineWidth( (pm->renderTarget->texsize < 512) ? 1 : 2*pm->renderTarget->texsize/512); 
}	
      glLineWidth( pm->renderTarget->texsize < 512 ? 1 : pm->renderTarget->texsize/512);
      glDisable(GL_LINE_STIPPLE);
}

void maximize_colors( projectM_t *pm )
{

 float wave_r_switch=0,wave_g_switch=0,wave_b_switch=0;
 //wave color brightening
      //
      //forces max color value to 1.0 and scales
      // the rest accordingly
 if(pm->nWaveMode==2 || pm->nWaveMode==5)
   {
	switch(pm->renderTarget->texsize)
			{
			case 256:  pm->wave_o *= 0.07f; break;
			case 512:  pm->wave_o *= 0.09f; break;
			case 1024: pm->wave_o *= 0.11f; break;
			case 2048: pm->wave_o *= 0.13f; break;
			}
   }

 else if(pm->nWaveMode==3)
   {
	switch(pm->renderTarget->texsize)
			{
			case 256:  pm->wave_o *= 0.075f; break;
			case 512:  pm->wave_o *= 0.15f; break;
			case 1024: pm->wave_o *= 0.22f; break;
			case 2048: pm->wave_o *= 0.33f; break;
			}
	pm->wave_o*=1.3f;
	pm->wave_o*=powf(pm->treb ,2.0f);
   }

      if (pm->bMaximizeWaveColor==1)  
	{
	  if(pm->wave_r>=pm->wave_g && pm->wave_r>=pm->wave_b)   //red brightest
	    {
	      wave_b_switch=pm->wave_b*(1/pm->wave_r);
	      wave_g_switch=pm->wave_g*(1/pm->wave_r);
	      wave_r_switch=1.0;
	    }
	  else if   (pm->wave_b>=pm->wave_g && pm->wave_b>=pm->wave_r)         //blue brightest
	    {  
	      wave_r_switch=pm->wave_r*(1/pm->wave_b);
	      wave_g_switch=pm->wave_g*(1/pm->wave_b);
	      wave_b_switch=1.0;
	      
	    }	
	
	  else  if (pm->wave_g>=pm->wave_b && pm->wave_g>=pm->wave_r)         //green brightest
	    {
	      wave_b_switch=pm->wave_b*(1/pm->wave_g);
	      wave_r_switch=pm->wave_r*(1/pm->wave_g);
	      wave_g_switch=1.0;
	    }
 
	
	  glColor4f(wave_r_switch, wave_g_switch, wave_b_switch, pm->wave_o);
	}
      else
	{ 
	  glColor4f(pm->wave_r, pm->wave_g, pm->wave_b, pm->wave_o);
	}
      
}


void modulate_opacity_by_volume( projectM_t *pm )

{
 //modulate volume by opacity
      //
      //set an upper and lower bound and linearly
      //calculate the opacity from 0=lower to 1=upper
      //based on current volume


      if (pm->bModWaveAlphaByVolume==1)
	{if (pm->vol<=pm->fModWaveAlphaStart)  pm->wave_o=0.0;       
	else if (pm->vol>=pm->fModWaveAlphaEnd) pm->wave_o=pm->fWaveAlpha;
	else pm->wave_o=pm->fWaveAlpha*((pm->vol-pm->fModWaveAlphaStart)/(pm->fModWaveAlphaEnd-pm->fModWaveAlphaStart));}
      else pm->wave_o=pm->fWaveAlpha;
}

void draw_motion_vectors( projectM_t *pm )

{
  int x,y;

  double offsetx=pm->mv_dx*pm->renderTarget->texsize, intervalx=pm->renderTarget->texsize/(double)pm->mv_x;
  double offsety=pm->mv_dy*pm->renderTarget->texsize, intervaly=pm->renderTarget->texsize/(double)pm->mv_y;

  glPointSize(pm->mv_l);
  glColor4f(pm->mv_r, pm->mv_g, pm->mv_b, pm->mv_a);
  glBegin(GL_POINTS);
  for (x=0;x<pm->mv_x;x++){
    for(y=0;y<pm->mv_y;y++){
      glVertex3f(offsetx+x*intervalx,offsety+y*intervaly,-1);	  
    }}
  
    glEnd();
    
}


void draw_borders( projectM_t *pm )
{
  //Draw Borders
  double of=pm->renderTarget->texsize*pm->ob_size*.5;
  double iff=(pm->renderTarget->texsize*pm->ib_size*.5);
  double texof=pm->renderTarget->texsize-of;

  //no additive drawing for borders
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); 
  
  glTranslatef(0,0,-1);

  glColor4d(pm->ob_r,pm->ob_g,pm->ob_b,pm->ob_a);
  
  glRectd(0,0,of,pm->renderTarget->texsize);
  glRectd(of,0,texof,of);
  glRectd(texof,0,pm->renderTarget->texsize,pm->renderTarget->texsize);
  glRectd(of,pm->renderTarget->texsize,texof,texof);
  glColor4d(pm->ib_r,pm->ib_g,pm->ib_b,pm->ib_a);
  glRectd(of,of,of+iff,texof);
  glRectd(of+iff,of,texof-iff,of+iff);
  glRectd(texof-iff,of,texof,texof);
  glRectd(of+iff,texof,texof-iff,texof-iff);
  
}

//Here we render the interpolated mesh, and then apply the texture to it.  
//Well, we actually do the inverse, but its all the same.
void render_interpolation( projectM_t *pm )
{
  
  int x,y;  
  
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
  glTranslated(0, 0, -9);
  
//    glColor4f( 0.5, 0.5, 0.5, pm->decay );
  glColor4f(0.0, 0.0, 0.0,pm->decay);          
  
  
  glEnable(GL_TEXTURE_2D);

    /** Bind the stashed texture */
    if ( pm->renderTarget->pbuffer != NULL ) {
        glBindTexture( GL_TEXTURE_2D, pm->renderTarget->textureID[1] );
#ifdef DEBUG
        if ( glGetError() ) {
            fprintf( debugFile, "failed to bind texture\n" );
            fflush( debugFile );
          }
#endif
      }

//#define DUMP_MESH
  for (x=0;x<pm->gx - 1;x++){
    glBegin(GL_TRIANGLE_STRIP);
    for(y=0;y<pm->gy;y++){
    #ifdef DUMP_MESH
    printf("mesh: (%d, %d):(%f, %f)->(%f, %f)\n", x, y, pm->x_mesh[x][y], pm->y_mesh[x][y], pm->gridx[x][y]/256.0, pm->gridy[x][y]/256.0);
    #endif
      glTexCoord4f(pm->x_mesh[x][y], pm->y_mesh[x][y],-1,1);
      glVertex4f(pm->gridx[x][y], pm->gridy[x][y],-1,1);
      glTexCoord4f(pm->x_mesh[x+1][y], pm->y_mesh[x+1][y],-1,1); 
      glVertex4f(pm->gridx[x+1][y], pm->gridy[x+1][y],-1,1);
    }
    glEnd();	
#ifdef DEBUG
        if ( glGetError() ) {
            fprintf( debugFile, "failed to render_interpolation()\n" );
            fflush( debugFile );
          }
#endif
  }
  #ifdef DUMP_MESH
  printf("\n\n");
  #endif

/**
    glEnable( GL_LIGHTING );
    glEnable( GL_DEPTH_TEST );
    glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
*/
  
    /** Re-bind the pbuffer */
    if ( pm->renderTarget->pbuffer != NULL ) {
        glBindTexture( GL_TEXTURE_2D, pm->renderTarget->textureID[0] );
      }

    glDisable(GL_TEXTURE_2D);
  }

void do_per_frame( projectM_t *pm )
{

  //Texture wrapping( clamp vs. wrap)
  if (pm->bTexWrap==0){
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);}
  else{ glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
  glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);}
      

  //      glRasterPos2i(0,0);
      //      glClear(GL_COLOR_BUFFER_BIT);
      //      glColor4d(0.0, 0.0, 0.0,1.0);     
       
  //      glMatrixMode(GL_TEXTURE);
    //  glLoadIdentity();

      glRasterPos2i(0,0);
      glClear(GL_COLOR_BUFFER_BIT);
      glColor4d(0.0, 0.0, 0.0,1.0);

 glMatrixMode(GL_TEXTURE);
      glLoadIdentity();

      glTranslatef(pm->cx,pm->cy, 0);
     if(pm->correction)  glScalef(1,pm->vw/(double)pm->vh,1);

      if(!isPerPixelEqn(ROT_OP)) {
	//	printf("ROTATING: rot = %f\n", rot);
	glRotatef(pm->rot*90, 0, 0, 1);
      }
      if(!isPerPixelEqn(SX_OP)) glScalef(1/pm->sx,1,1);     
      if(!isPerPixelEqn(SY_OP)) glScalef(1,1/pm->sy,1); 

      if(pm->correction)glScalef(1,pm->vh/(double)pm->vw,1);
            glTranslatef((-pm->cx) ,(-pm->cy),0);  
 
      if(!isPerPixelEqn(DX_OP)) glTranslatef(-pm->dx,0,0);   
      if(!isPerPixelEqn(DY_OP)) glTranslatef(0 ,-pm->dy,0); 
     
}


//Actually draws the texture to the screen
//
//The Video Echo effect is also applied here
void render_texture_to_screen( projectM_t *pm )
{ 
      int flipx=1,flipy=1;
 
     glMatrixMode(GL_TEXTURE);  
     glLoadIdentity();

  glMatrixMode(GL_MODELVIEW);
      glLoadIdentity();
      glTranslatef(0, 0, -9);  

      // Milkymist TMU does not support linear filtering
      //glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      //glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    
      glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE,  GL_DECAL);
      glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_FASTEST);
      
      //       glClear(GL_ACCUM_BUFFER_BIT);
      glColor4d(0.0, 0.0, 0.0,1.0f);

   glBegin(GL_QUADS);
     glVertex4d(-pm->vw*.5,-pm->vh*.5,-1,1);
     glVertex4d(-pm->vw*.5,  pm->vh*.5,-1,1);
     glVertex4d(pm->vw*.5,  pm->vh*.5,-1,1);
     glVertex4d(pm->vw*.5, -pm->vh*.5,-1,1);
      glEnd();

     

      //      glBindTexture( GL_TEXTURE_2D, tex2 );
      glEnable(GL_TEXTURE_2D);
//      glBindTexture( GL_TEXTURE_2D, pm->renderTarget->textureID );

      // glAccum(GL_LOAD,0);
      // if (bDarken==1)  glBlendFunc(GL_SRC_COLOR,GL_ZERO); 
	
      //Draw giant rectangle and texture it with our texture!
      glBegin(GL_QUADS);
      glTexCoord4d(0, 1,0,1); glVertex4d(-pm->vw*.5,-pm->vh*.5,-1,1);
      glTexCoord4d(0, 0,0,1); glVertex4d(-pm->vw*.5,  pm->vh*.5,-1,1);
      glTexCoord4d(1, 0,0,1); glVertex4d(pm->vw*.5,  pm->vh*.5,-1,1);
      glTexCoord4d(1, 1,0,1); glVertex4d(pm->vw*.5, -pm->vh*.5,-1,1);
      glEnd();
       
  glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);

  //  if (bDarken==1)  glBlendFunc(GL_SRC_COLOR,GL_ONE_MINUS_SRC_ALPHA); 

  // if (bDarken==1) { glAccum(GL_ACCUM,1-fVideoEchoAlpha); glBlendFunc(GL_SRC_COLOR,GL_ZERO); }

       glMatrixMode(GL_TEXTURE);

      //draw video echo
      glColor4f(0.0, 0.0, 0.0,pm->fVideoEchoAlpha);
      glTranslated(.5,.5,0);
      glScaled(1/pm->fVideoEchoZoom,1/pm->fVideoEchoZoom,1);
       glTranslated(-.5,-.5,0);    

      switch (((int)pm->nVideoEchoOrientation))
	{
	case 0: flipx=1;flipy=1;break;
	case 1: flipx=-1;flipy=1;break;
  	case 2: flipx=1;flipy=-1;break;
	case 3: flipx=-1;flipy=-1;break;
	default: flipx=1;flipy=1; break;
	}
      glBegin(GL_QUADS);
      glTexCoord4d(0, 1,0,1); glVertex4f(-pm->vw*.5*flipx,-pm->vh*.5*flipy,-1,1);
      glTexCoord4d(0, 0,0,1); glVertex4f(-pm->vw*.5*flipx,  pm->vh*.5*flipy,-1,1);
      glTexCoord4d(1, 0,0,1); glVertex4f(pm->vw*.5*flipx,  pm->vh*.5*flipy,-1,1);
      glTexCoord4d(1, 1,0,1); glVertex4f(pm->vw*.5*flipx, -pm->vh*.5*flipy,-1,1);
      glEnd();

    
      glDisable(GL_TEXTURE_2D);
      glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);


      if (pm->bBrighten==1)
	{ 
	  glColor4f(1.0, 1.0, 1.0,1.0);
	  glBlendFunc(GL_ONE_MINUS_DST_COLOR,GL_ZERO);
	  glBegin(GL_QUADS);
	  glVertex4f(-pm->vw*.5*flipx,-pm->vh*.5*flipy,-1,1);
	  glVertex4f(-pm->vw*.5*flipx,  pm->vh*.5*flipy,-1,1);
	  glVertex4f(pm->vw*.5*flipx,  pm->vh*.5*flipy,-1,1);
	  glVertex4f(pm->vw*.5*flipx, -pm->vh*.5*flipy,-1,1);
	  glEnd();
	  glBlendFunc(GL_ZERO, GL_DST_COLOR);
	  glBegin(GL_QUADS);
	  glVertex4f(-pm->vw*.5*flipx,-pm->vh*.5*flipy,-1,1);
	  glVertex4f(-pm->vw*.5*flipx,  pm->vh*.5*flipy,-1,1);
	  glVertex4f(pm->vw*.5*flipx,  pm->vh*.5*flipy,-1,1);
	  glVertex4f(pm->vw*.5*flipx, -pm->vh*.5*flipy,-1,1);
	  glEnd();
	  glBlendFunc(GL_ONE_MINUS_DST_COLOR,GL_ZERO);
	  glBegin(GL_QUADS);
	  glVertex4f(-pm->vw*.5*flipx,-pm->vh*.5*flipy,-1,1);
	  glVertex4f(-pm->vw*.5*flipx,  pm->vh*.5*flipy,-1,1);
	  glVertex4f(pm->vw*.5*flipx,  pm->vh*.5*flipy,-1,1);
	  glVertex4f(pm->vw*.5*flipx, -pm->vh*.5*flipy,-1,1);
	  glEnd();

	  glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);

	} 

      if (pm->bDarken==1)
	{ 
	  
	  glColor4f(1.0, 1.0, 1.0,1.0);
	  glBlendFunc(GL_ZERO,GL_DST_COLOR);
	  glBegin(GL_QUADS);
	  glVertex4f(-pm->vw*.5*flipx,-pm->vh*.5*flipy,-1,1);
	  glVertex4f(-pm->vw*.5*flipx,  pm->vh*.5*flipy,-1,1);
	  glVertex4f(pm->vw*.5*flipx,  pm->vh*.5*flipy,-1,1);
	  glVertex4f(pm->vw*.5*flipx, -pm->vh*.5*flipy,-1,1);
	  glEnd();
	  


	  glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);

	} 
    

      if (pm->bSolarize==1)
	{ 
       
	  glColor4f(1.0, 1.0, 1.0,1.0);
	  glBlendFunc(GL_ZERO,GL_ONE_MINUS_DST_COLOR);
	  glBegin(GL_QUADS);
	  glVertex4f(-pm->vw*.5*flipx,-pm->vh*.5*flipy,-1,1);
	  glVertex4f(-pm->vw*.5*flipx,  pm->vh*.5*flipy,-1,1);
	  glVertex4f(pm->vw*.5*flipx,  pm->vh*.5*flipy,-1,1);
	  glVertex4f(pm->vw*.5*flipx, -pm->vh*.5*flipy,-1,1);
	  glEnd();
	  glBlendFunc(GL_DST_COLOR,GL_ONE);
	  glBegin(GL_QUADS);
	  glVertex4f(-pm->vw*.5*flipx,-pm->vh*.5*flipy,-1,1);
	  glVertex4f(-pm->vw*.5*flipx,  pm->vh*.5*flipy,-1,1);
	  glVertex4f(pm->vw*.5*flipx,  pm->vh*.5*flipy,-1,1);
	  glVertex4f(pm->vw*.5*flipx, -pm->vh*.5*flipy,-1,1);
	  glEnd();


	  glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);

	} 

      if (pm->bInvert==1)
	{ 
	  glColor4f(1.0, 1.0, 1.0,1.0);
	  glBlendFunc(GL_ONE_MINUS_DST_COLOR,GL_ZERO);
	  glBegin(GL_QUADS);
	  glVertex4f(-pm->vw*.5*flipx,-pm->vh*.5*flipy,-1,1);
	  glVertex4f(-pm->vw*.5*flipx,  pm->vh*.5*flipy,-1,1);
	  glVertex4f(pm->vw*.5*flipx,  pm->vh*.5*flipy,-1,1);
	  glVertex4f(pm->vw*.5*flipx, -pm->vh*.5*flipy,-1,1);
	  glEnd();
	  glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
	} 

}
void render_texture_to_studio( projectM_t *pm )
{ 
      int x,y;
      int flipx=1,flipy=1;
 
     glMatrixMode(GL_TEXTURE);  
     glLoadIdentity();

  glMatrixMode(GL_MODELVIEW);
      glLoadIdentity();
      glTranslatef(0, 0, -9);  
     
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
      glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE,  GL_DECAL);
      glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_FASTEST);
      
      //       glClear(GL_ACCUM_BUFFER_BIT);
      glColor4f(0.0, 0.0, 0.0,0.04);
      

   glBegin(GL_QUADS);
     glVertex4d(-pm->vw*.5,-pm->vh*.5,-1,1);
     glVertex4d(-pm->vw*.5,  pm->vh*.5,-1,1);
     glVertex4d(pm->vw*.5,  pm->vh*.5,-1,1);
     glVertex4d(pm->vw*.5, -pm->vh*.5,-1,1);
      glEnd();


      glColor4f(0.0, 0.0, 0.0,1.0);
      
      glBegin(GL_QUADS);
      glVertex4d(-pm->vw*.5,0,-1,1);
      glVertex4d(-pm->vw*.5,  pm->vh*.5,-1,1);
      glVertex4d(pm->vw*.5,  pm->vh*.5,-1,1);
      glVertex4d(pm->vw*.5, 0,-1,1);
      glEnd();
     
     glBegin(GL_QUADS);
     glVertex4d(0,-pm->vh*.5,-1,1);
     glVertex4d(0,  pm->vh*.5,-1,1);
     glVertex4d(pm->vw*.5,  pm->vh*.5,-1,1);
     glVertex4d(pm->vw*.5, -pm->vh*.5,-1,1);
     glEnd();

      glPushMatrix();
 glTranslatef(.25*pm->vw, .25*pm->vh, 0);
      glScalef(.5,.5,1);

      //      glBindTexture( GL_TEXTURE_2D, tex2 );
      glEnable(GL_TEXTURE_2D);

      // glAccum(GL_LOAD,0);
      // if (bDarken==1)  glBlendFunc(GL_SRC_COLOR,GL_ZERO); 

      //Draw giant rectangle and texture it with our texture!
      glBegin(GL_QUADS);
      glTexCoord4d(0, 1,0,1); glVertex4d(-pm->vw*.5,-pm->vh*.5,-1,1);
      glTexCoord4d(0, 0,0,1); glVertex4d(-pm->vw*.5,  pm->vh*.5,-1,1);
      glTexCoord4d(1, 0,0,1); glVertex4d(pm->vw*.5,  pm->vh*.5,-1,1);
      glTexCoord4d(1, 1,0,1); glVertex4d(pm->vw*.5, -pm->vh*.5,-1,1);
      glEnd();
       
  glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);

  //  if (bDarken==1)  glBlendFunc(GL_SRC_COLOR,GL_ONE_MINUS_SRC_ALPHA); 

  // if (bDarken==1) { glAccum(GL_ACCUM,1-fVideoEchoAlpha); glBlendFunc(GL_SRC_COLOR,GL_ZERO); }

       glMatrixMode(GL_TEXTURE);

      //draw video echo
      glColor4f(0.0, 0.0, 0.0,pm->fVideoEchoAlpha);
      glTranslated(.5,.5,0);
      glScaled(1/pm->fVideoEchoZoom,1/pm->fVideoEchoZoom,1);
       glTranslated(-.5,-.5,0);    

      switch (((int)pm->nVideoEchoOrientation))
	{
	case 0: flipx=1;flipy=1;break;
	case 1: flipx=-1;flipy=1;break;
  	case 2: flipx=1;flipy=-1;break;
	case 3: flipx=-1;flipy=-1;break;
	default: flipx=1;flipy=1; break;
	}
      glBegin(GL_QUADS);
      glTexCoord4d(0, 1,0,1); glVertex4f(-pm->vw*.5*flipx,-pm->vh*.5*flipy,-1,1);
      glTexCoord4d(0, 0,0,1); glVertex4f(-pm->vw*.5*flipx,  pm->vh*.5*flipy,-1,1);
      glTexCoord4d(1, 0,0,1); glVertex4f(pm->vw*.5*flipx,  pm->vh*.5*flipy,-1,1);
      glTexCoord4d(1, 1,0,1); glVertex4f(pm->vw*.5*flipx, -pm->vh*.5*flipy,-1,1);
      glEnd();

    
      glDisable(GL_TEXTURE_2D);
      glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);

 // if (bDarken==1) { glAccum(GL_ACCUM,fVideoEchoAlpha); glAccum(GL_RETURN,1);}


      if (pm->bInvert==1)
	{ 
	  glColor4f(1.0, 1.0, 1.0,1.0);
	  glBlendFunc(GL_ONE_MINUS_DST_COLOR,GL_ZERO);
	  glBegin(GL_QUADS);
	  glVertex4f(-pm->vw*.5*flipx,-pm->vh*.5*flipy,-1,1);
	  glVertex4f(-pm->vw*.5*flipx,  pm->vh*.5*flipy,-1,1);
	  glVertex4f(pm->vw*.5*flipx,  pm->vh*.5*flipy,-1,1);
	  glVertex4f(pm->vw*.5*flipx, -pm->vh*.5*flipy,-1,1);
	  glEnd();
	  glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
	} 

      //  glTranslated(.5,.5,0);
  //  glScaled(1/fVideoEchoZoom,1/fVideoEchoZoom,1);
      //   glTranslated(-.5,-.5,0);    
      //glTranslatef(0,.5*vh,0);

      /** Per-pixel mesh display -- bottom-right corner */
      //glBlendFunc(GL_ONE_MINUS_DST_COLOR,GL_ZERO);
      glMatrixMode(GL_MODELVIEW);
      glPopMatrix();
      glPushMatrix();
      glTranslatef(.25*pm->vw, -.25*pm->vh, 0);
      glScalef(.5,.5,1);
       glColor4f(1,1,1,.6);

       for (x=0;x<pm->gx;x++){
	 glBegin(GL_LINE_STRIP);
	 for(y=0;y<pm->gy;y++){
	   glVertex4f((pm->x_mesh[x][y]-.5)* pm->vw, (pm->y_mesh[x][y]-.5)*pm->vh,-1,1);
	   //glVertex4f((origx[x+1][y]-.5) * vw, (origy[x+1][y]-.5) *vh ,-1,1);
	 }
	 glEnd();	
       }    
       
       for (y=0;y<pm->gy;y++){
	 glBegin(GL_LINE_STRIP);
	 for(x=0;x<pm->gx;x++){
	   glVertex4f((pm->x_mesh[x][y]-.5)* pm->vw, (pm->y_mesh[x][y]-.5)*pm->vh,-1,1);
	   //glVertex4f((origx[x+1][y]-.5) * vw, (origy[x+1][y]-.5) *vh ,-1,1);
	 }
	 glEnd();	
       }    
      
       /*
       for (x=0;x<pm->gx-1;x++){
	 glBegin(GL_POINTS);
	 for(y=0;y<pm->gy;y++){
	   glVertex4f((pm->origx[x][y]-.5)* pm->vw, (pm->origy[x][y]-.5)*pm->vh,-1,1);
	   glVertex4f((pm->origx[x+1][y]-.5) * pm->vw, (pm->origy[x+1][y]-.5) *pm->vh ,-1,1);
	 }
	 glEnd();	
       }    
       */
 // glTranslated(-.5,-.5,0);     glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA); 

    /** Waveform display -- bottom-left */
    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
       glMatrixMode(GL_MODELVIEW);
       glPopMatrix();
       glPushMatrix();    
   glTranslatef(-.5*pm->vw,0, 0);

    glTranslatef(0,-pm->vh*.10, 0);
   glBegin(GL_LINE_STRIP);
	     glColor4f(0,1.0,1.0,1.0);
	     glVertex3f((((pm->totalframes%256)/551.0))*pm->vw, pm->treb_att*-7,-1);
	     glColor4f(1.0,1.0,1.0,1.0);
	     glVertex3f((((pm->totalframes%256)/551.0))*pm->vw,0 ,-1);   
	     glColor4f(.5,1.0,1.0,1.0);
	     glVertex3f((((pm->totalframes%256)/551.0))*pm->vw, pm->treb*7,-1);
	     glEnd(); 	
	       
	       glTranslatef(0,-pm->vh*.13, 0);
 glBegin(GL_LINE_STRIP);
	      glColor4f(0,1.0,0.0,1.0);
	     glVertex3f((((pm->totalframes%256)/551.0))*pm->vw, pm->mid_att*-7,-1);
	     glColor4f(1.0,1.0,1.0,1.0);
	     glVertex3f((((pm->totalframes%256)/551.0))*pm->vw,0 ,-1);   
	     glColor4f(.5,1.0,0.0,0.5);
	     glVertex3f((((pm->totalframes%256)/551.0))*pm->vw, pm->mid*7,-1);
	     glEnd();
	  
	   
	     glTranslatef(0,-pm->vh*.13, 0);
 glBegin(GL_LINE_STRIP);
	     glColor4f(1.0,0.0,0.0,1.0);
	     glVertex3f((((pm->totalframes%256)/551.0))*pm->vw, pm->bass_att*-7,-1);
	     glColor4f(1.0,1.0,1.0,1.0);
	     glVertex3f((((pm->totalframes%256)/551.0))*pm->vw,0 ,-1);   
	     glColor4f(.7,0.2,0.2,1.0);
	     glVertex3f((((pm->totalframes%256)/551.0))*pm->vw, pm->bass*7,-1);
	     glEnd();

 glTranslatef(0,-pm->vh*.13, 0);
 glBegin(GL_LINES);
	     
	     glColor4f(1.0,1.0,1.0,1.0);
	     glVertex3f((((pm->totalframes%256)/551.0))*pm->vw,0 ,-1);   
	     glColor4f(1.0,0.6,1.0,1.0);
	     glVertex3f((((pm->totalframes%256)/551.0))*pm->vw, pm->vol*7,-1);
	     glEnd();

	     glPopMatrix();
}



void projectM_initengine( projectM_t *pm ) {

/* PER FRAME CONSTANTS BEGIN */
 pm->zoom=1.0;
 pm->zoomexp= 1.0;
 pm->rot= 0.0;
 pm->warp= 0.0;

 pm->sx= 1.0;
 pm->sy= 1.0;
 pm->dx= 0.0;
 pm->dy= 0.0;
 pm->cx= 0.5;
 pm->cy= 0.5;

 pm->decay=.98;

 pm->wave_r= 1.0;
 pm->wave_g= 0.2;
 pm->wave_b= 0.0;
 pm->wave_x= 0.5;
 pm->wave_y= 0.5;
 pm->wave_mystery= 0.0;

 pm->ob_size= 0.0;
 pm->ob_r= 0.0;
 pm->ob_g= 0.0;
 pm->ob_b= 0.0;
 pm->ob_a= 0.0;

 pm->ib_size = 0.0;
 pm->ib_r = 0.0;
 pm->ib_g = 0.0;
 pm->ib_b = 0.0;
 pm->ib_a = 0.0;

 pm->mv_a = 0.0;
 pm->mv_r = 0.0;
 pm->mv_g = 0.0;
 pm->mv_b = 0.0;
 pm->mv_l = 1.0;
 pm->mv_x = 16.0;
 pm->mv_y = 12.0;
 pm->mv_dy = 0.02;
 pm->mv_dx = 0.02;
  
 pm->meshx = 0;
 pm->meshy = 0;
 
 pm->Time = 0;
 pm->treb = 0;
 pm->mid = 0;
 pm->bass = 0;
 pm->bass_old = 0;
 pm->treb_att = 0;
 pm->beat_sensitivity = 8.00;
 pm->mid_att = 0;
 pm->bass_att = 0;
 pm->progress = 0;
 pm->frame = 0;
 pm->fps = 30;
    pm->avgtime = 600;
//bass_thresh = 0;

/* PER_FRAME CONSTANTS END */
 pm->fRating = 0;
 pm->fGammaAdj = 1.0;
 pm->fVideoEchoZoom = 1.0;
 pm->fVideoEchoAlpha = 0;
 pm->nVideoEchoOrientation = 0;
 
 pm->nWaveMode = 7;
 pm->bAdditiveWaves = 0;
 pm->bWaveDots = 0;
 pm->bWaveThick = 0;
 pm->bModWaveAlphaByVolume = 0;
 pm->bMaximizeWaveColor = 0;
 pm->bTexWrap = 0;
 pm->bDarkenCenter = 0;
 pm->bRedBlueStereo = 0;
 pm->bBrighten = 0;
 pm->bDarken = 0;
 pm->bSolarize = 0;
 pm->bInvert = 0;
 pm->bMotionVectorsOn = 1;
 
 pm->fWaveAlpha =1.0;
 pm->fWaveScale = 1.0;
 pm->fWaveSmoothing = 0;
 pm->fWaveParam = 0;
 pm->fModWaveAlphaStart = 0;
 pm->fModWaveAlphaEnd = 0;
 pm->fWarpAnimSpeed = 0;
 pm->fWarpScale = 0;
 pm->fShader = 0;


/* PER_PIXEL CONSTANTS BEGIN */
pm->x_per_pixel = 0;
pm->y_per_pixel = 0;
pm->rad_per_pixel = 0;
pm->ang_per_pixel = 0;

/* PER_PIXEL CONSTANT END */


/* Q AND T VARIABLES START */

pm->q1 = 0;
pm->q2 = 0;
pm->q3 = 0;
pm->q4 = 0;
pm->q5 = 0;
pm->q6 = 0;
pm->q7 = 0;
pm->q8 = 0;


/* Q AND T VARIABLES END */

//per pixel meshes
 pm->zoom_mesh = NULL;
 pm->zoomexp_mesh = NULL;
 pm->rot_mesh = NULL;
 

 pm->sx_mesh = NULL;
 pm->sy_mesh = NULL;
 pm->dx_mesh = NULL;
 pm->dy_mesh = NULL;
 pm->cx_mesh = NULL;
 pm->cy_mesh = NULL;

 pm->x_mesh = NULL;
 pm->y_mesh = NULL;
 pm->rad_mesh = NULL;
 pm->theta_mesh = NULL;

//custom wave per point meshes
  }

/* Reinitializes the engine variables to a default (conservative and sane) value */
void projectM_resetengine( projectM_t *pm ) {

  pm->doPerPixelEffects = 1;
  pm->doIterative = 1;

  pm->zoom=1.0;
  pm->zoomexp= 1.0;
  pm->rot= 0.0;
  pm->warp= 0.0;
  
  pm->sx= 1.0;
  pm->sy= 1.0;
  pm->dx= 0.0;
  pm->dy= 0.0;
  pm->cx= 0.5;
  pm->cy= 0.5;

  pm->decay=.98;
  
  pm->wave_r= 1.0;
  pm->wave_g= 0.2;
  pm->wave_b= 0.0;
  pm->wave_x= 0.5;
  pm->wave_y= 0.5;
  pm->wave_mystery= 0.0;

  pm->ob_size= 0.0;
  pm->ob_r= 0.0;
  pm->ob_g= 0.0;
  pm->ob_b= 0.0;
  pm->ob_a= 0.0;

  pm->ib_size = 0.0;
  pm->ib_r = 0.0;
  pm->ib_g = 0.0;
  pm->ib_b = 0.0;
  pm->ib_a = 0.0;

  pm->mv_a = 0.0;
  pm->mv_r = 0.0;
  pm->mv_g = 0.0;
  pm->mv_b = 0.0;
  pm->mv_l = 1.0;
  pm->mv_x = 16.0;
  pm->mv_y = 12.0;
  pm->mv_dy = 0.02;
  pm->mv_dx = 0.02;
  
  pm->meshx = 0;
  pm->meshy = 0;
 
  pm->Time = 0;
  pm->treb = 0;
  pm->mid = 0;
  pm->bass = 0;
  pm->treb_att = 0;
  pm->mid_att = 0;
  pm->bass_att = 0;
  pm->progress = 0;
  pm->frame = 0;

// bass_thresh = 0;

/* PER_FRAME CONSTANTS END */
  pm->fRating = 0;
  pm->fGammaAdj = 1.0;
  pm->fVideoEchoZoom = 1.0;
  pm->fVideoEchoAlpha = 0;
  pm->nVideoEchoOrientation = 0;
 
  pm->nWaveMode = 7;
  pm->bAdditiveWaves = 0;
  pm->bWaveDots = 0;
  pm->bWaveThick = 0;
  pm->bModWaveAlphaByVolume = 0;
  pm->bMaximizeWaveColor = 0;
  pm->bTexWrap = 0;
  pm->bDarkenCenter = 0;
  pm->bRedBlueStereo = 0;
  pm->bBrighten = 0;
  pm->bDarken = 0;
  pm->bSolarize = 0;
 pm->bInvert = 0;
 pm->bMotionVectorsOn = 1;
 
  pm->fWaveAlpha =1.0;
  pm->fWaveScale = 1.0;
  pm->fWaveSmoothing = 0;
  pm->fWaveParam = 0;
  pm->fModWaveAlphaStart = 0;
  pm->fModWaveAlphaEnd = 0;
  pm->fWarpAnimSpeed = 0;
  pm->fWarpScale = 0;
  pm->fShader = 0;


/* PER_PIXEL CONSTANTS BEGIN */
 pm->x_per_pixel = 0;
 pm->y_per_pixel = 0;
 pm->rad_per_pixel = 0;
 pm->ang_per_pixel = 0;

/* PER_PIXEL CONSTANT END */


/* Q VARIABLES START */

 pm->q1 = 0;
 pm->q2 = 0;
 pm->q3 = 0;
 pm->q4 = 0;
 pm->q5 = 0;
 pm->q6 = 0;
 pm->q7 = 0;
 pm->q8 = 0;


 /* Q VARIABLES END */
}

/** Resets OpenGL state */
void projectM_resetGL( projectM_t *pm, int w, int h ) {
   
    char path[1024];

#ifdef DEBUG
    if ( debugFile != NULL ) {
        fprintf( debugFile, "projectM_resetGL(): in: %d x %d\n", w, h );
        fflush( debugFile );
      }
#endif

    /** Stash the new dimensions */
    pm->vw = w;
    pm->vh = h;

    if ( pm->fbuffer != NULL ) {
        free( pm->fbuffer );
      }
    pm->fbuffer = 
        (GLubyte *)malloc( sizeof( GLubyte ) * pm->renderTarget->texsize * pm->renderTarget->texsize * 3 );

    /* Our shading model--Gouraud (smooth). */
    glShadeModel( GL_SMOOTH);
    /* Culling. */
    //    glCullFace( GL_BACK );
    //    glFrontFace( GL_CCW );
    //    glEnable( GL_CULL_FACE );
    /* Set the clear color. */
    glClearColor( 0, 0, 0, 0 );
    /* Setup our viewport. */
    glViewport( 0, 0, w, h );
    /*
    * Change to the projection matrix and set
    * our viewing volume.
    */
    glMatrixMode(GL_TEXTURE);
    glLoadIdentity();

    //    gluOrtho2D(0.0, (GLfloat) width, 0.0, (GLfloat) height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();  

    //    glFrustum(0.0, height, 0.0,width,10,40);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    glDrawBuffer(GL_BACK); 
    glReadBuffer(GL_BACK); 
    glEnable(GL_BLEND); 

    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); 
    // glBlendFunc(GL_SRC_ALPHA, GL_ONE); 
    if ( pm->fullscreen ) {
        glDisable( GL_LINE_SMOOTH );
      } else {
        glEnable( GL_LINE_SMOOTH );
      }
    glEnable(GL_POINT_SMOOTH);
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    // glCopyTexImage2D(GL_TEXTURE_2D,0,GL_RGB,0,0,renderTarget->texsize,renderTarget->texsize,0);
    //glCopyTexSubImage2D(GL_TEXTURE_2D,0,0,0,0,0,renderTarget->texsize,renderTarget->texsize);
    glLineStipple(2, 0xAAAA);

    /** (Re)create the offscreen for pass 1 */
    createPBuffers( w, h, pm->renderTarget );

    rescale_per_pixel_matrices( pm );

  }

