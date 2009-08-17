CMAKE_MINIMUM_REQUIRED(VERSION 2.6)

PROJECT(projectM)

SET(CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR})

FIND_PACKAGE(Alsa REQUIRED)
FIND_PACKAGE(OpenGL REQUIRED)
FIND_PACKAGE(SDL REQUIRED)

SET(libprojectM_SOURCES PCM.c beat_detect.c builtin_funcs.c custom_shape.c custom_wave.c eval.c fftsg.c func.c init_cond.c param.c parser.c pbuffer.c per_frame_eqn.c per_pixel_eqn.c preset.c projectM.c splaytree.c timer.c  tree_types.c wipemalloc.c)

ADD_DEFINITIONS(-DLINUX -DHAVE_OPENGL -DHAVE_CONFIG_H -D_THREAD_SAFE)

INCLUDE_DIRECTORIES(${OPENGL_INCLUDE_DIR})

ADD_EXECUTABLE(projectM ${libprojectM_SOURCES} main.c)

TARGET_LINK_LIBRARIES(projectM ${GLEW_LINK_TARGETS} ${OPENGL_LIBRARIES} ${ASOUND_LIBRARY} ${SDL_LIBRARY} m)

