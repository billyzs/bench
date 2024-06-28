#include <benchmark/benchmark.h>

#include <Eigen/Dense>
#include <algorithm>
#include <cassert>
#include <cstdio>
#include <iostream>
#include <random>
#include <valarray>
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

static void VectorAdd_RawLoop(benchmark::State& state) {
  const auto a = rand_vec(num_elements);
  const auto b = rand_vec(num_elements);
  auto c = std::vector<double>(num_elements);
  for (auto _ : state) {
    ::benchmark::DoNotOptimize(c);
    for (int x = 0; x < num_elements; ++x) {
      c[x] = a[x] + b[x];
    }
  }
}
BENCHMARK(VectorAdd_RawLoop);

static void VectorAdd_StlVec(benchmark::State& state) {
  const auto a = rand_vec(num_elements);
  const auto b = rand_vec(num_elements);
  auto c = std::vector<double>(num_elements);
  for (auto _ : state) {
    std::transform(a.cbegin(), a.cend(), b.cbegin(), c.begin(), std::plus<>());
  }
}
BENCHMARK(VectorAdd_StlVec);

struct VectorAdd : public ::benchmark::Fixture {
  Eigen::VectorXd v1{num_elements};
  Eigen::VectorXd v2{num_elements};
  Eigen::VectorXd v3{num_elements};
  std::valarray<double> val_arr1; // can't use {} due to BENCHMARK macro
  std::valarray<double> val_arr2;
  std::valarray<double> val_arr3;
  void SetUp(::benchmark::State&) {
    v1.setRandom();
    v2.setRandom();
    assert(v1.size() == num_elements);
    assert(v1.size() == v2.size());
    assert(v2.size() == v3.size());
    val_arr1.resize(num_elements);
    val_arr2.resize(num_elements);
    val_arr3.resize(num_elements);
    assert(v2.size() == val_arr1.size());
    std::copy(v1.begin(), v1.end(), std::begin(val_arr1));
    std::copy(v2.begin(), v2.end(), std::begin(val_arr2));
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

BENCHMARK_DEFINE_F(VectorAdd, EigenAdd)(benchmark::State& st) {
  for (auto _ : st) {
    // somehow this doesn't need the DoNotOptimize directive, but valarray needs
    // it
    v3 = v2 + v1;
  }
}
BENCHMARK_REGISTER_F(VectorAdd, EigenAdd);

BENCHMARK_DEFINE_F(VectorAdd, RawLoopAdd)(benchmark::State& st) {
  // this measures mainly the efficiency of operator[] on Eigen Matrix
  // the Eigen operator[] probably does more complex things than
  // std::vector's operator[] and as expected , this performs miserably
  for (auto _ : st) {
    for (auto x = 0; x < v1.size(); ++x) {
      v3[x] = v1[x] + v2[x];
    }
  }
}
BENCHMARK_REGISTER_F(VectorAdd, RawLoopAdd);

BENCHMARK_DEFINE_F(VectorAdd, StlAdd)(benchmark::State& st) {
  // runs at about the same speed as EigenAdd
  // we are probably lucky here because std::plus<>() resolved to
  // Eigen's efficient version of add
  for (auto _ : st) {
    std::transform(v1.begin(), v1.end(), v2.begin(), v3.begin(), std::plus<>());
  }
}
BENCHMARK_REGISTER_F(VectorAdd, StlAdd);
BENCHMARK_MAIN();
