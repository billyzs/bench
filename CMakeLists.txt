cmake_minimum_required(VERSION 3.19) # generator expression

project(bench LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED YES)
set(CMAKE_CXX_EXTENSIONS NO)
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
    GIT_TAG        v0.13.0
    GIT_SHALLOW    TRUE
)
set(MLX_BUILD_TESTS OFF CACHE INTERNAL "")
set(MLX_BUILD_EXAMPLES OFF CACHE INTERNAL "")
set(MLX_BUILD_BENCHMARKS OFF CACHE INTERNAL "")
set(MLX_BUILD_METAL OFF CACHE INTERNAL "")
FetchContent_MakeAvailable(mlx)

add_library(tutorial STATIC
    tutorial.cpp
)
target_link_libraries(tutorial
PUBLIC
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

target_compile_options(main
PRIVATE
    $<$<CONFIG:Debug>:-g3>
    $<$<CONFIG:Debug,RelWithDebInfo>:-glldb>
    $<$<CONFIG:Release,RelWithDebInfo>:-O3>
    -march=native
)

target_link_libraries(main
PRIVATE
    tutorial
    Eigen3::Eigen
    benchmark::benchmark
)


