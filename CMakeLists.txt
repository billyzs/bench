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
  "Using CMake version: ${CMAKE_VERSION}"
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
  message(
    FATAL_ERROR
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

# official doc requires NO_MODULE which is the same as config
add_subdirectory(cmake/deps/Eigen3)
add_subdirectory(cmake/deps/MLX)
add_subdirectory(cmake/deps/benchmark)
if(NOT CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
    find_package(OpenMP)
else()
    add_subdirectory(cmake/deps/OpenMP)
endif()


include(cmake/CompileOptions.cmake)
set_project_compile_options()

add_library(
  tutorial
  STATIC
  tutorial.cpp
)
target_link_libraries(
  tutorial
  PUBLIC
    $<BUILD_INTERFACE:mlx>
  PRIVATE
    bench_compile_opts
)

if(TARGET
   Eigen3::Eigen
)
  add_library(
    test_eigen
    STATIC
    test_eigen.cpp
  )
  target_link_libraries(
    test_eigen
    PRIVATE
      Eigen3::Eigen bench_compile_opts benchmark::benchmark
  )
endif()

if(OpenMP_CXX_FOUND)
  add_library(
    test_openmp
    STATIC
    test_openmp.cpp
  )
  target_link_libraries(
    test_openmp
    PRIVATE
      OpenMP::OpenMP_CXX bench_compile_opts benchmark::benchmark
  )
endif()

add_executable(
  main
  test_mlx.cpp
  main.cpp
)

target_link_libraries(
  main
  PRIVATE
    bench_compile_opts tutorial $<TARGET_NAME_IF_EXISTS::test_openmp>
    $<TARGET_NAME_IF_EXISTS:test_eigen> benchmark::benchmark
)
if(CMAKE_CXX_COMPILER_ID
   STREQUAL
   "AppleClang"
)
  add_dependencies(
    main
    test_openmp
  ) # HACK until #3 is solved
endif()

enable_testing()
add_test(
  NAME benchmark_main.list_tests
  COMMAND
    main --benchmark_list_tests=true
)
