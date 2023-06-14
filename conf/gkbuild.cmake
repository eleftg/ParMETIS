# Helper modules.
include(CheckFunctionExists)
include(CheckIncludeFile)

# Setup options.
option(GDB "enable use of GDB" OFF)
option(ASSERT "turn asserts on" OFF)
option(ASSERT2 "additional assertions" OFF)
option(DEBUG "add debugging support" OFF)
option(GPROF "add gprof support" OFF)
option(OPENMP "enable OpenMP support" OFF)
option(PCRE "enable PCRE support" OFF)
option(GKREGEX "enable GKREGEX support" OFF)
option(GKRAND "enable GKRAND support" OFF)

# Add compiler flags.
if(MSVC)
  set(GK_COPTS "/Ox")
  set(GK_COPTIONS "-DWIN32 -DMSC -D_CRT_SECURE_NO_WARNINGS -DUSE_GKREGEX")
elseif(MINGW)
  set(GK_COPTS "-DUSE_GKREGEX")
else()
  set(GK_COPTIONS "-DLINUX -D_FILE_OFFSET_BITS=64")
endif()

if(CYGWIN)
  set(GK_COPTIONS "${GK_COPTIONS} -DCYGWIN")
endif()

if(CMAKE_C_COMPILER_ID MATCHES GNU)
# GCC opts.
  set(GK_COPTIONS "${GK_COPTIONS} -std=c99 -fno-strict-aliasing")
# -march=native is not a valid flag on PPC:
if(CMAKE_SYSTEM_PROCESSOR MATCHES "power|ppc|powerpc|ppc64|powerpc64" OR (APPLE AND CMAKE_OSX_ARCHITECTURES MATCHES "ppc|ppc64"))
  set(GK_COPTIONS "${GK_COPTIONS} -mtune=native")
else()
  set(GK_COPTIONS "${GK_COPTIONS} -march=native")
endif()
  if(NOT MINGW)
      set(GK_COPTIONS "${GK_COPTIONS} -fPIC")
  endif()
# GCC warnings.
  set(GK_COPTIONS "${GK_COPTIONS} -Werror -Wall -pedantic -Wno-unused-function -Wno-unused-but-set-variable -Wno-unused-variable -Wno-unknown-pragmas -Wno-unused-label")
elseif(CMAKE_C_COMPILER_ID MATCHES Sun)
# Sun insists on -xc99.
  set(GK_COPTIONS "${GK_COPTIONS} -xc99")
endif()

if(CMAKE_C_COMPILER_ID MATCHES Intel)
    if(WIN32)
        set(GK_COPTIONS "${GK_COPTIONS} /QxHost")
    else()
        set(GK_COPTIONS "${GK_COPTIONS} -xHost")
  #  set(GK_COPTIONS "${GK_COPTIONS} -fast")
    endif()
endif()

# Add support for the Accelerate framework in OS X
if(APPLE)
  set(GK_COPTIONS "${GK_COPTIONS} -framework Accelerate")
endif()

# Find OpenMP if it is requested.
if(OPENMP)
  include(FindOpenMP)
  if(OPENMP_FOUND)
    set(GK_COPTIONS "${GK_COPTIONS} -D__OPENMP__ ${OpenMP_C_FLAGS}")
  else()
    message(WARNING "OpenMP was requested but support was not found")
  endif()
endif()


# Add various definitions.
if(GDB)
  set(GK_COPTS "${GK_COPTS} -g")
  set(GK_COPTIONS "${GK_COPTIONS} -Werror")
else()
  set(GK_COPTS "-O3")
endif(GDB)


if(DEBUG)
  set(GK_COPTS "-Og")
  set(GK_COPTIONS "${GK_COPTIONS} -DDEBUG")
endif()

if(GPROF)
  set(GK_COPTS "-pg")
endif()

if(NOT ASSERT)
  set(GK_COPTIONS "${GK_COPTIONS} -DNDEBUG")
endif()

if(NOT ASSERT2)
  set(GK_COPTIONS "${GK_COPTIONS} -DNDEBUG2")
endif()


# Add various options
if(PCRE)
  set(GK_COPTIONS "${GK_COPTIONS} -D__WITHPCRE__")
endif()

if(GKREGEX)
  set(GK_COPTIONS "${GK_COPTIONS} -DUSE_GKREGEX")
endif()

if(GKRAND)
  set(GK_COPTIONS "${GK_COPTIONS} -DUSE_GKRAND")
endif()


# Check for features.
check_include_file(execinfo.h HAVE_EXECINFO_H)
if(HAVE_EXECINFO_H)
  set(GK_COPTIONS "${GK_COPTIONS} -DHAVE_EXECINFO_H")
endif()

check_function_exists(getline HAVE_GETLINE)
if(HAVE_GETLINE)
  set(GK_COPTIONS "${GK_COPTIONS} -DHAVE_GETLINE")
endif()


# Custom check for TLS.
if(MSVC)
  set(GK_COPTIONS "${GK_COPTIONS} -D \"__thread=__declspec(thread)\"")

  # This if checks if that value is cached or not.
  if("${HAVE_THREADLOCALSTORAGE}" MATCHES "^${HAVE_THREADLOCALSTORAGE}$")
    try_compile(HAVE_THREADLOCALSTORAGE
      ${CMAKE_BINARY_DIR}
      ${CMAKE_SOURCE_DIR}/conf/check_thread_storage.c)
    if(HAVE_THREADLOCALSTORAGE)
      message(STATUS "checking for thread-local storage - found")
    else()
      message(STATUS "checking for thread-local storage - not found")
    endif()
  endif()
  if(NOT HAVE_THREADLOCALSTORAGE)
    set(GK_COPTIONS "${GK_COPTIONS} -D \"__thread=\"")
  endif()
endif()

# Finally set the official C flags.
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${GK_COPTIONS} ${GK_COPTS}")

