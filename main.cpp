#include <benchmark/benchmark.h>

#include <algorithm>
#include <cassert>
#include <cstdio>
#include <iostream>
#include <random>
#include <valarray>
#include <vector>
#include "tutorial.h"
#ifdef HAS_OPENMP
#include <omp.h>
#endif

/*
 * def vector_add(a, b, c):
    c[:] = a[:] + b[:]

num_elements = 128 * 1024 * 1024
a = np.random.rand( num_elements )
b = np.random.rand( num_elements )
c = np.empty( num_elements, dtype=np.float64 )

*/
inline constexpr double seed = 0xbeefbabe;
auto rand_vec(auto begin, auto end) {
  std::generate(
      begin,
      end,
      [gen = std::mt19937(seed),
       dist = std::uniform_real_distribution<>(0, 1.0)]() mutable {
        return dist(gen);
      });
  return end;
}

static void VectorAdd_StlVec(benchmark::State& state) {
  auto a = std::vector<double>(numElements);
  auto b = std::vector<double>(numElements);
  auto c = std::vector<double>(numElements);
  rand_vec(a.begin(), a.end());
  rand_vec(b.begin(), b.end());
  for (auto _ : state) {
#ifdef _OPENMP // this is the OpenMP standard ppd
#pragma omp parallel for
#endif
    for (auto x = 0; x < a.size(); ++x) {
      c[x] = a[x] + b[x];
    }
  }
}
BENCHMARK(VectorAdd_StlVec)->Name(
#ifdef _OPENMP // this is the OpenMP standard ppd
    "VectorAdd_StlVec_OpenMP"
#else 
    "VectorAdd_StlVec"
#endif
);

struct VectorAdd : public ::benchmark::Fixture {
  std::valarray<double> val_arr1; // can't use {} due to BENCHMARK macro
  std::valarray<double> val_arr2;
  std::valarray<double> val_arr3;
  void SetUp(::benchmark::State&) {
    val_arr1.resize(numElements);
    val_arr2.resize(numElements);
    val_arr3.resize(numElements);
    rand_vec(std::begin(val_arr1), std::begin(val_arr1));
    assert(v2.size() == val_arr1.size());
  }
  void TearDown(::benchmark::State&) {}
};

BENCHMARK_DEFINE_F(VectorAdd, Valarray)(benchmark::State& st) {
  // this is reasonably fast, often a tiny bit faster than the raw loop
  for (auto _ : st) {
    ::benchmark::DoNotOptimize(val_arr3);
    val_arr3 = val_arr1 + val_arr2;
  }
}
BENCHMARK_REGISTER_F(VectorAdd, Valarray);

BENCHMARK_DEFINE_F(VectorAdd, StlAdd)(benchmark::State& st) {
  // runs at about the same speed as EigenAdd
  // we are probably lucky here because std::plus<>() resolved to
  // Eigen's efficient version of add
  for (auto _ : st) {
    std::transform(
        std::begin(val_arr1),
        std::end(val_arr1),
        std::begin(val_arr2),
        std::begin(val_arr3),
        std::plus<>());
  }
}
BENCHMARK_REGISTER_F(VectorAdd, StlAdd);
void VectorAdd_Mlx(::benchmark::State& st, const mlx::core::Dtype dtype) {
  MlxVectorData d(numElements * st.range(0), dtype);
  for (auto _ : st) {
    ::benchmark::DoNotOptimize(d.v3);
    d.v3 = d.v1 + d.v2;
    d.v3.eval();
  }
}
BENCHMARK_CAPTURE(VectorAdd_Mlx, Bfloat16, mlx::core::bfloat16)->DenseRange(1, 4, 1);
BENCHMARK_CAPTURE(VectorAdd_Mlx, Float32, mlx::core::float32)->DenseRange(1, 2, 1);
BENCHMARK_MAIN();
