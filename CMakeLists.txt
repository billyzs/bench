cmake_minimum_required(VERSION 3.10)

project(bench LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED YES)
set(CMAKE_CXX_EXTENSIONS NO)
# enable_testing()

find_package(Eigen3 3.4.0 REQUIRED)
find_package(benchmark REQUIRED)

add_executable(main
    main.cpp
)

target_compile_options(main
PUBLIC
    -O3
)

target_link_libraries(main
PRIVATE
    Eigen3::Eigen
    benchmark::benchmark
)
# https://stackoverflow.com/a/70398644

