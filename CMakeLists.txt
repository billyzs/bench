cmake_minimum_required(VERSION 3.19) # generator expression

project(
    bench
    VERSION 0.0.1
    LANGUAGES C CXX
)
if(NOT CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
    message(FATAL_ERROR "UNSUPPORTED PLATFORM")
else()
    set(CMAKE_MACOSX_RPATH 1)
endif()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
include(cmake/Cache.cmake)
enable_cache()

# official doc requires NO_MODULE which is the same as config
add_subdirectory(cmake/deps/Eigen3)
add_subdirectory(cmake/deps/MLX)
if(NOT CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
    find_package(OpenMP)
else()
    add_subdirectory(cmake/deps/OpenMP)
endif()
set(BENCHMARK_ENABLE_TESTING NO)
include(FetchContent)
FetchContent_Declare(
    benchmark 
    GIT_REPOSITORY https://github.com/google/benchmark.git
    GIT_TAG        v1.8.4
    GIT_SHALLOW    TRUE
    GIT_PROGRESS   TURE
    EXCLUDE_FROM_ALL
    FIND_PACKAGE_ARGS
)


FetchContent_MakeAvailable(
    benchmark
)
add_library(bench_compile_opts INTERFACE)
add_library(bench::compile_opts ALIAS bench_compile_opts)

target_compile_definitions(bench_compile_opts
INTERFACE
    $<$<AND:$<COMPILE_LANG_AND_ID:CXX,AppleClang,Clang>,$<CONFIG:Debug>>:
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

if(Eigen3_FOUND)
    add_library(test_eigen STATIC
        test_eigen.cpp
    )
    target_link_libraries(test_eigen
    PRIVATE
        Eigen3::Eigen
        bench_compile_opts
        benchmark::benchmark
    )
endif()

if(OpenMP_CXX_FOUND)
    add_library(test_openmp STATIC
        test_openmp.cpp
    )
    target_link_libraries(test_openmp
    PRIVATE
	OpenMP::OpenMP_CXX
        bench_compile_opts
        benchmark::benchmark
    )
endif()


add_executable(main
    test_mlx.cpp
    main.cpp
)

target_link_libraries(main
PRIVATE
    bench_compile_opts
    tutorial
    $<TARGET_NAME_IF_EXISTS::test_openmp>
    $<TARGET_NAME_IF_EXISTS:test_eigen>
    benchmark::benchmark
)
if(CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
    add_dependencies(main test_openmp)  # HACK until #3 is solved
endif()

enable_testing()
add_test(
    NAME benchmark_main.list_tests
    COMMAND main --benchmark_list_tests=true
)
