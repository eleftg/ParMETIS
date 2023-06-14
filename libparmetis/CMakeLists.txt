# Include directories for library code.
include_directories(.)

# Find sources.
file(GLOB parmetis_sources *.c)

# Create libparmetis
add_library(parmetis ${ParMETIS_LIBRARY_TYPE} ${parmetis_sources})

if(BUILD_SHARED_LIBS)
  target_link_libraries(parmetis metis GKlib MPI::MPI_C)
endif()

install(TARGETS parmetis
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION lib
  ARCHIVE DESTINATION lib)
