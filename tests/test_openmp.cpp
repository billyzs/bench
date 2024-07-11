#include <benchmark/benchmark.h>

#include <omp.h>
#include <vector>
#include "config.h"

static void DISABLED_VectorAdd_StlVec_OpenMP(benchmark::State& state) {
  auto a = std::vector<double>(numElements);
  auto b = std::vector<double>(numElements);
  auto c = std::vector<double>(numElements);

  for (auto _ : state) {
    #pragma omp parallel
#pragma omp for
    for (auto x = 0; x < a.size(); ++x) {
      c[x] = a[x] + b[x];
    }
  }
}
BENCHMARK(DISABLED_VectorAdd_StlVec_OpenMP); // Disable until #3 fixed
