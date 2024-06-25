#include <benchmark/benchmark.h>

#include <Eigen/Dense>
#include <algorithm>
#include <iostream>
#include <random>
#include <vector>

/*
 * def vector_add(a, b, c):
    c[:] = a[:] + b[:]

num_elements = 128 * 1024 * 1024
a = np.random.rand( num_elements )
b = np.random.rand( num_elements )
c = np.empty( num_elements, dtype=np.float64 )

*/

inline constexpr size_t num_elements = 128 * 1024 * 1024;
inline constexpr double seed = 0xbeefbabe;

std::vector<double> rand_vec(size_t cnt) {
  std::vector<double> ret(cnt);
  std::generate(
      ret.begin(),
      ret.end(),
      [gen = std::mt19937(seed),
       dist = std::uniform_real_distribution<>(0, 1.0)]() mutable {
        return dist(gen);
      });
  return ret;
}

void vector_add(
    const std::vector<double>& a,
    const std::vector<double>& b,
    std::vector<double>& c) {
  std::transform(a.begin(), a.end(), b.begin(), c.begin(), std::plus<>());
}

static void BM_VectorAdd(
    benchmark::State& state,
    const std::vector<double>& a,
    const std::vector<double>& b,
    std::vector<double>& c) {
  for (auto _ : state) {
    vector_add(a, b, c);
  }
}

static auto a = rand_vec(num_elements);
static auto b = rand_vec(num_elements);
static auto c = std::vector<double>(num_elements);
BENCHMARK_CAPTURE(BM_VectorAdd, raw_loop, a, b, c);
BENCHMARK_MAIN();
