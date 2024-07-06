cmake_minimum_required(VERSION 3.19) # generator expression

project(
    bench
    VERSION 0.0.1
    LANGUAGES C CXX
)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
# enable_testing()
include(cmake/Cache.cmake)
enable_cache()

find_package(Eigen3 3.4.0 REQUIRED)
find_package(benchmark REQUIRED)
#find_package(MLX REQUIRED)
include(FetchContent)
FetchContent_Declare(
    mlx
    GIT_REPOSITORY https://github.com/ml-explore/mlx.git
    GIT_TAG        v0.15.2
    GIT_SHALLOW    TRUE
)
set(MLX_BUILD_TESTS OFF CACHE INTERNAL "")
set(MLX_BUILD_EXAMPLES OFF CACHE INTERNAL "")
set(MLX_BUILD_BENCHMARKS OFF CACHE INTERNAL "")
set(MLX_BUILD_METAL ON CACHE INTERNAL "")
set(MLX_METAL_JIT ON CACHE INTERNAL "")
FetchContent_MakeAvailable(mlx)

if(CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
    include(cmake/omp.cmake)
    find_openmp_appleclang()
else()
    find_package(OpenMP)
endif()
add_library(bench_compile_opts INTERFACE)
add_library(bench::compile_opts ALIAS bench_compile_opts)

target_compile_definitions(bench_compile_opts
INTERFACE
    $<$<AND:$<COMPILE_LANG_AND_ID:CXX,AppleClang,Clang>,$<CONFIG:Debug>>:
	_LIBCPP_DEBUG=0
        _LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_DEBUG
        _LIBCPP_ENABLE_DEBUG_MODE=1
        _LIBCPP_DEBUG_RANDOMIZE_UNSPECIFIED_STABILITY
        _LIBCPP_DEBUG_STRICT_WEAK_ORDERING_CHECK
    >
    $<$<AND:$<COMPILE_LANG_AND_ID:CXX,AppleClang,Clang>,$<CONFIG:Release>>:
	_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_EXTENSIVE
    >
    $<$<CONFIG:RelWithDebInfo>:>
    $<$<CONFIG:MinSizeRel>:>
)

target_compile_options(bench_compile_opts
INTERFACE
    $<$<CONFIG:Debug>:
        -Og
    >
    $<$<CONFIG:Debug>:
    	-Wall
	-Wextra
	-Wpedantic
	-Wdouble-promotion
	-Wno-sign-conversion
	-Wmissing-field-initializers
    >
    $<$<AND:$<CXX_COMPILER_ID:AppleClang,Clang>,$<CONFIG:Debug,RelWithDebInfo>>:
	-glldb
    >
    #$<$<CONFIG:Debug>:-fsanitize=address -fsanitize=undefined -fsanitize-trap>
    $<$<CONFIG:Release,RelWithDebInfo>:-O3>
    $<$<CXX_COMPILER_ID:AppleClang,Clang>:-fcolor-diagnostics>
    -march=native
)

target_compile_features(bench_compile_opts
INTERFACE
    cxx_std_${CMAKE_CXX_STANDARD}
)

add_library(tutorial STATIC
    tutorial.cpp
)
target_link_libraries(tutorial
PUBLIC
    bench_compile_opts
    $<BUILD_INTERFACE:mlx>
)
add_executable(tutorial_main
    tutorial_main.cpp
)
target_link_libraries(tutorial_main
PRIVATE
    tutorial
)
add_executable(main
    test_mlx.cpp
    main.cpp
)

target_link_libraries(main
PRIVATE
    bench_compile_opts
    tutorial
    $<$<BOOL:OpenMP_FOUND>:OpenMP::OpenMP_CXX>
    Eigen3::Eigen
    benchmark::benchmark
)

