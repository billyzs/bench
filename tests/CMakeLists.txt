add_executable(
  bench_main
  test_mlx.cpp
  $<$<TARGET_EXISTS:Eigen3::Eigen>:test_eigen.cpp>
  main.cpp
)

target_link_libraries(
  bench_main
  PRIVATE
    bench_compile_opts mlx_tutorial benchmark::benchmark
    $<TARGET_NAME_IF_EXISTS:Eigen3::Eigen>
)

if(OpenMP_CXX_FOUND)
  add_library(
    test_openmp
    test_openmp.cpp
  )
  target_link_libraries(
    test_openmp
    PRIVATE
      bench_compile_opts OpenMP::OpenMP_CXX benchmark::benchmark
  )
  add_dependencies(
    bench_main
    test_openmp
  ) # Hack to get the build system to compile openmp code (but not actually link
  # it until #3 is fixed)
endif()

enable_testing()
add_test(
  NAME bench_main.smoke_test
  COMMAND
    bench_main --benchmark_list_tests=true
    --benchmark_enable_random_interleaving=true
)
add_test(
  NAME bench_main.Trig_test
  COMMAND
    bench_main --benchmark_filter=Trig
    --benchmark_enable_random_interleaving=true
)
