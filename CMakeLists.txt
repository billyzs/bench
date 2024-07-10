cmake_minimum_required(
  VERSION
    3.19
) # generator expression

project(
  bench
  VERSION
    0.0.1
  LANGUAGES
    C CXX
)
message(
  STATUS
    "Using CMake version: ${CMAKE_VERSION} on ${CMAKE_SYSTEM_PROCESSOR}"
)
message(
  STATUS
    "${CMAKE_SYSTEM_PROGRAM_PATH}"
)

if(NOT
   CMAKE_HOST_SYSTEM_NAME
   STREQUAL
   "Darwin"
)
  message(FATAL_ERROR
            "UNSUPPORTED PLATFORM"
  )
else()
  set(CMAKE_MACOSX_RPATH
      1
  )
endif()

set(CMAKE_CXX_STANDARD
    20
)
set(CMAKE_CXX_STANDARD_REQUIRED
    ON
)
set(CMAKE_CXX_EXTENSIONS
    OFF
)
set(CMAKE_EXPORT_COMPILE_COMMANDS
    ON
)
include(cmake/Cache.cmake)
enable_cache()

set(CPM_FILE
    "${CMAKE_CURRENT_BINARY_DIR}/cmake/CPM.cmake"
)
set(CPM_EXPECTED_SHA1
    9fe00008cc8c5b172edb7100707af661b4e54b2f
    CACHE
      STRING "expected SHA1 sum of CPM.cmake version v0.40.0"
) # v0.40.0
if(EXISTS
   $CPM_FILE}
)
  file(
    SHA1
    ${CPM_FILE}
    CPM_CURR_SHA1
  )
else()
  set(CPM_CURR_SHA1
      "CPM not found"
  )
endif()

if(CPM_CURR_SHA1
   STREQUAL
   CPM_EXPECTED_SHA1
)
  message(STATUS
            "Using cached CPM.cmake"
  )
else()
  message(STATUS
            "Downloading CPM.cmake"
  )
  file(
    DOWNLOAD
    https://github.com/cpm-cmake/CPM.cmake/releases/download/v0.40.0/CPM.cmake
    ${CPM_FILE}
    EXPECTED_HASH
      SHA1=${CPM_EXPECTED_SHA1}
    SHOW_PROGRESS
  )
endif()
include(${CPM_FILE})

# official doc requires NO_MODULE which is the same as config
find_package(
  Eigen3
  3.4.0
  CONFIG
)
if(NOT
   TARGET
   Eigen3::Eigen
)
  CPMAddPackage(
    NAME Eigen3
    GIT_REPOSITORY
      https://gitlab.com/libeigen/eigen.git
    GIT_TAG
      3.4.0
    OPTIONS
      "BUILD_TESTING OFF" "EIGEN_BUILD_TESTING OFF" "EIGEN_BUILD_DEMOS OFF"
      "EIGEN_LEAVE_TEST_IN_ALL_TARGET OFF" "EIGEN_BUILD_PKGCONFIG OFF"
      "EIGEN_BUILD_DOC OFF"
    GIT_SHALLOW
    EXCLUDE_FROM_ALL
    SYSTEM
      ON
  )
endif()

CPMAddPackage(
  NAME mlx
  GITHUB_REPOSITORY
    ml-explore/mlx
  VERSION
    0.15.2
  OPTIONS
    "MLX_BUILD_TESTS OFF" "MLX_BUILD_EXAMPLES OFF" "MLX_BUILD_BENCHMARKS OFF"
    "MLX_BUILD_METAL ON" "MLX_METAL_JIT ON"
  GIT_SHALLOW
  EXCLUDE_FROM_ALL
  SYSTEM
    ON
)

CPMAddPackage(
  NAME benchmark
  GITHUB_REPOSITORY
    google/benchmark
  VERSION
    1.8.4
  OPTIONS
    "BENCHMARK_ENABLE_TESTING OFF" "BENCHMARK_USE_BUNDLED_GTEST OFF"
    "BENCHMARK_ENABLE_GTEST_TESTS OFF" "BENCHMARK_INSTALL_DOCS OFF"
  GIT_SHALLOW
  EXCLUDE_FROM_ALL
  SYSTEM
    ON
)
if(benchmark_ADDED)
  # enable c++11 to avoid compilation errors
  set_target_properties(
    benchmark
    PROPERTIES
      CXX_STANDARD 11
  )
endif()

if(NOT
   CMAKE_CXX_COMPILER_ID
   STREQUAL
   "AppleClang"
)
  find_package(OpenMP)
else()
  add_subdirectory(cmake/deps/OpenMP)
endif()

include(cmake/CompileOptions.cmake)
set_project_compile_options()
target_include_directories(
  bench_compile_opts
  INTERFACE
    "include/"
)

add_subdirectory(src)

if(BUILD_TESTING)
  add_subdirectory(tests)
endif()
