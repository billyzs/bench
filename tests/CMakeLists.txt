add_executable(
  bench_main
  test_mlx.cpp
  $<$<TARGET_EXISTS:Eigen3::Eigen>:test_eigen.cpp>
  main.cpp
)

if(${CMAKE_SYSTEM_NAME}
   STREQUAL
   "Darwin"
)
  target_sources(
    bench_main
    PRIVATE
      test_accelerate.cpp
  )
  find_library(
    ACCELERATE_LBRARIES
    Accelerate
  )
  target_link_libraries(
    bench_main
    PRIVATE
      ${ACCELERATE_LIBRARIES}
  )
  target_compile_definitions(
    bench_main
    PRIVATE
      ACCELERATE_NEW_LAPACK
  )
endif()

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
find_program(
  just_FOUND
  just
)
if(just_FOUND)
  add_test(
    NAME just_test
    WORKING_DIRECTORY
      ${CMAKE_SOURCE_DIR}
    COMMAND
      just configure
  )
endif()
