#include <benchmark/benchmark.h>

#include <omp.h>
#include <vector>
#include "config.h"

static void VectorAdd_StlVec_OpenMP(benchmark::State& state) {
  auto a = std::vector<double>(numElements);
  auto b = std::vector<double>(numElements);
  auto c = std::vector<double>(numElements);
#pragma omp parallel
  for (auto _ : state) {
#pragma omp for
    for (auto x = 0; x < a.size(); ++x) {
      c[x] = a[x] + b[x];
    }
  }
}
// BENCHMARK(VectorAdd_StlVec_OpenMP);  // disable until #2 is fixed
