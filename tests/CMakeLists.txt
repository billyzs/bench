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

target_include_directories(
  main
  PRIVATE
    ../
)

target_link_libraries(
  main
  PRIVATE
    bench_compile_opts mlx_tutorial $<TARGET_NAME_IF_EXISTS::test_openmp>
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
  NAME benchmark_main.smoke_test
  COMMAND
    main --benchmark_list_tests=true
)
