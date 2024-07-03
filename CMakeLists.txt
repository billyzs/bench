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
find_package(MLX REQUIRED)

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
    Eigen3::Eigen
    benchmark::benchmark
    mlx
)


