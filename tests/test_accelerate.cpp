// #include <Accelerate/Accelerate.h>
#include <benchmark/benchmark.h>
#include <vecLib/vForce.h>
#include <vector>
#include "config.h"

static void Accelerate_Trig(::benchmark::State& st) {
  std::vector<float> v1(numElements, 0);
  std::vector<float> v2(numElements, 0);
  std::vector<float> v3(numElements, 0);
  const int num = numElements;
  for (auto _ : st) {
    ::benchmark::DoNotOptimize(v3);
    vvatan2f(v3.data(), v1.data(), v2.data(), &num);
  }
}
BENCHMARK(Accelerate_Trig);
