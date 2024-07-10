add_library(
  mlx_tutorial
  STATIC
  tutorial.cpp
)
target_link_libraries(
  mlx_tutorial
  PUBLIC
    $<BUILD_INTERFACE:mlx>
  PRIVATE
    bench_compile_opts
)

add_executable(
  mlx_tutorial_main
  tutorial_main.cpp
)

target_link_libraries(
  mlx_tutorial_main
  PRIVATE
    mlx_tutorial bench_compile_opts
)
