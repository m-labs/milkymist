# - Find GD
# Find the native GD includes and library
# This module defines
#  GD_INCLUDE_DIR, where to find gd.h, etc.
#  GD_LIBRARIES, the libraries needed to use GD.
#  GD_FOUND, If false, do not try to use GD.
# also defined, but not for general use are
#  GD_LIBRARY, where to find the GD library.
#  GD_SUPPORTS_PNG, GD_SUPPORTS_JPEG, GD_SUPPORTS_GIF, test
#  support for image formats in GD.

find_path(GD_INCLUDE_DIR gd.h
/usr/local/include
/usr/include
)

if(WIN32 AND NOT CYGWIN)
  set(GD_NAMES ${GD_NAMES} bgd)
else(WIN32)
  set(GD_NAMES ${GD_NAMES} gd)
endif(WIN32 AND NOT CYGWIN)

find_library(GD_LIBRARY
  NAMES ${GD_NAMES}
  PATHS /usr/local/lib /usr/lib
  )

if(GD_LIBRARY AND GD_INCLUDE_DIR)
  set(GD_LIBRARIES ${GD_LIBRARY})
  set(GD_FOUND "YES")
else(GD_LIBRARY AND GD_INCLUDE_DIR)
  set(GD_FOUND "NO")
endif(GD_LIBRARY AND GD_INCLUDE_DIR)

if(GD_FOUND)
  if(WIN32 AND NOT CYGWIN)
    set(GD_SUPPORTS_PNG ON)
    set(GD_SUPPORTS_JPEG ON)
    set(GD_SUPPORTS_GIF ON)
    get_filename_component(GD_LIBRARY_DIR ${GD_LIBRARY} PATH)
  else(WIN32 AND NOT CYGWIN)
    include(CheckLibraryExists)
    get_filename_component(GD_LIB_PATH ${GD_LIBRARY} PATH)
    get_filename_component(GD_LIB ${GD_LIBRARY} NAME)

    check_library_exists(
    "${GD_LIBRARY}"
    "gdImagePng"
    "${GD_LIB_PATH}"
    GD_SUPPORTS_PNG
    )
    if(GD_SUPPORTS_PNG)
      find_package(PNG)
      if(PNG_FOUND)
        set(GD_LIBRARIES ${GD_LIBRARIES} ${PNG_LIBRARIES})
        set(GD_INCLUDE_DIR ${GD_INCLUDE_DIR} ${PNG_INCLUDE_DIR})
      else(PNG_FOUND)
        set(GD_SUPPORTS_PNG "NO")
      endif(PNG_FOUND)
    endif(GD_SUPPORTS_PNG)

    check_library_exists(
    "${GD_LIBRARY}"
    "gdImageJpeg"
    "${GD_LIB_PATH}"
    GD_SUPPORTS_JPEG
    )
    if(GD_SUPPORTS_JPEG)
      find_package(JPEG)
      if(JPEG_FOUND)
        set(GD_LIBRARIES ${GD_LIBRARIES} ${JPEG_LIBRARIES})
        set(GD_INCLUDE_DIR ${GD_INCLUDE_DIR} ${JPEG_INCLUDE_DIR})
      else(JPEG_FOUND)
        set(GD_SUPPORTS_JPEG "NO")
      endif(JPEG_FOUND)
    endif(GD_SUPPORTS_JPEG)

    check_library_exists(
    "${GD_LIBRARY}"
    "gdImageGif"
    "${GD_LIB_PATH}"
    GD_SUPPORTS_GIF)

    # Trim the list of include directories
    set(GDINCTRIM)
    foreach(GD_DIR ${GD_INCLUDE_DIR})
      set(GD_TMP_FOUND OFF)
      foreach(GD_TRIMMED ${GDINCTRIM})
        if("${GD_DIR}" STREQUAL "${GD_TRIMMED}")
          set(GD_TMP_FOUND ON)
        endif("${GD_DIR}" STREQUAL "${GD_TRIMMED}")
      endforeach(GD_TRIMMED ${GDINCTRIM})
      if(NOT GD_TMP_FOUND)
        set(GDINCTRIM "${GDINCTRIM}" "${GD_DIR}")
      endif(NOT GD_TMP_FOUND)
    endforeach(GD_DIR ${GD_INCLUDE_DIR})
    set(GD_INCLUDE_DIR ${GDINCTRIM})

    set(GD_LIBRARY_DIR)
    # Generate trimmed list of library directories and list of libraries
    foreach(GD_LIB ${GD_LIBRARIES})
      get_filename_component(GD_NEXTLIBDIR ${GD_LIB} PATH)
      set(GD_TMP_FOUND OFF)
      foreach(GD_LIBDIR ${GD_LIBRARY_DIR})
        if("${GD_NEXTLIBDIR}" STREQUAL "${GD_LIBDIR}")
          set(GD_TMP_FOUND ON)
        endif("${GD_NEXTLIBDIR}" STREQUAL "${GD_LIBDIR}")
      endforeach(GD_LIBDIR ${GD_LIBRARIES})
      if(NOT GD_TMP_FOUND)
        set(GD_LIBRARY_DIR "${GD_LIBRARY_DIR}" "${GD_NEXTLIBDIR}")
      endif(NOT GD_TMP_FOUND)
    endforeach(GD_LIB ${GD_LIBRARIES})
  endif(WIN32 AND NOT CYGWIN)
endif(GD_FOUND)

if(GD_FOUND)
   if(NOT GD_FIND_QUIETLY)
      message(STATUS "Found GD: ${GD_LIBRARY}")
   endif(NOT GD_FIND_QUIETLY)
else(GD_FOUND)
   if(GD_FIND_REQUIRED)
      message(FATAL_ERROR "Could not find GD library")
   endif(GD_FIND_REQUIRED)
endif(GD_FOUND)

mark_as_advanced(
GD_LIBRARY
GD_LIBRARIES
GD_INCLUDE_DIR
GD_LIBRARY_DIR
GD_SUPPORTS_PNG
GD_SUPPORTS_JPEG
GD_SUPPORTS_GIF
)
