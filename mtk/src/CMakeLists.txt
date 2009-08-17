INCLUDE_DIRECTORIES(${MTK_SOURCE_DIR}/include)
INCLUDE_DIRECTORIES(${FREETYPE_INCLUDE_DIRS})
ADD_DEFINITIONS(${PNG_DEFINITIONS})
INCLUDE_DIRECTORIES(${PNG_INCLUDE_DIR})

ADD_LIBRARY(MTK colorschema events region screen widget dc container window padder fontrenderer fontschema label linearcontainer separator pngloader icon focus focusable selcontainer selcontainergroup eventcallback colormodel iconregistry environment application regionpathgroup parabolicpath combo)
