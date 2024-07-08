include(FetchContent)

# https://mac.r-project.org/openmp/#do
FetchContent_Declare(
  openmp_debug
  URL https://mac.r-project.org/openmp/openmp-16.0.4-darwin20-Debug.tar.gz
  URL_HASH
    SHA1=1253f7157f590804031095440ffd80aac016b101
  DOWNLOAD_NO_EXTRACT
    FALSE
  DOWNLOAD_NO_PROGRESS
    FALSE
  DOWNLOAD_EXTRACT_TIMESTAMP
  FALSE
  CONFIGURE_COMMAND
  ""
  BUILD_COMMAND
  ""
  INSTALL_COMMAND
  ""
  TEST_COMMAND
  ""
  EXCLUDE_FROM_ALL
)

FetchContent_Declare(
  openmp_release
  URL https://mac.r-project.org/openmp/openmp-16.0.4-darwin20-Release.tar.gz
  URL_HASH
    SHA1=591136d3c1cc26f3a21f1202a652be911bf1a2ad
  DOWNLOAD_NO_EXTRACT
    FALSE
  DOWNLOAD_NO_PROGRESS
    FALSE
  DOWNLOAD_EXTRACT_TIMESTAMP
  FALSE
  CONFIGURE_COMMAND
  ""
  BUILD_COMMAND
  ""
  INSTALL_COMMAND
  ""
  TEST_COMMAND
  ""
  EXCLUDE_FROM_ALL
)
FetchContent_MakeAvailable(
  openmp_debug
  openmp_release
)

add_library(
  openmp_cxx
  SHARED
  IMPORTED
  GLOBAL
)
add_dependencies(
  openmp_cxx
  openmp_debug
  openmp_release
)

target_compile_definitions(
  openmp_cxx
  INTERFACE
    HAS_OPENMP=1
)
set_target_properties(
  openmp_cxx
  PROPERTIES
    INTERFACE_COMPILE_OPTIONS "-Xclang;-fopenmp"
    IMPORTED_LOCATION_DEBUG "${openmp_debug_SOURCE_DIR}/local/lib/libomp.dylib"
    IMPORTED_LOCATION_RELEASE
    "${openmp_release_SOURCE_DIR}/local/lib/libomp.dylib"
    MAP_IMPORTED_CONFIG_MINSIZEREL Release MAP_IMPORTED_CONFIG_RELWITHDEBINFO
                                           Release
)
if(CMAKE_BUILD_TYPE
   STREQUAL
   "Debug"
)
  set_property(
    TARGET
      openmp_cxx
    APPEND
    PROPERTY
      IMPORTED_CONFIGURATIONS DEBUG
  )
  set(OpenMP_INCLUDE_DIR
      "${openmp_debug_SOURCE_DIR}/local/include"
  )
  set_target_properties(
    openmp_cxx
    PROPERTIES
      INTERFACE_INCLUDE_DIRECTORIES ${OpenMP_INCLUDE_DIR}
  )
else()
  set_property(
    TARGET
      openmp_cxx
    APPEND
    PROPERTY
      IMPORTED_CONFIGURATIONS RELEASE
  )
  set(OpenMP_INCLUDE_DIR
      "${openmp_release_SOURCE_DIR}/local/include"
  )
  set_target_properties(
    openmp_cxx
    PROPERTIES
      INTERFACE_INCLUDE_DIRECTORIES ${OpenMP_INCLUDE_DIR}
      INTERFACE_INSTALL_RPATH
      "${openmp_release_SOURCE_DIR}/local/lib/libomp.dylib"
      # IMPORTED_SONAME_RELEASE "@rpath/libomp.dylib"
  )
endif()
add_library(
  OpenMP::OpenMP_CXX
  ALIAS
  openmp_cxx
)
add_library(
  OpenMP::OpenMP_C
  ALIAS
  openmp_cxx
)
set(OpenMP_FOUND
    1
    PARENT_SCOPE
)
set(OpenMP_CXX_FOUND
    1
    PARENT_SCOPE
)
message(
  STATUS
  "Using Downloaded OpenMP"
)
