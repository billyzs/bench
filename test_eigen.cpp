#include <benchmark/benchmark.h>

#include <Eigen/Dense>
#include <algorithm>
#include <cassert>

#include "config.h"

struct EigenVector : public ::benchmark::Fixture {
  Eigen::VectorXd v1{numElements};
  Eigen::VectorXd v2{numElements};
  Eigen::VectorXd v3{numElements};
  void SetUp(::benchmark::State&) {
    v1.setRandom();
    v2.setRandom();
    assert(v1.size() == numElements);
    assert(v1.size() == v2.size());
    assert(v2.size() == v3.size());
  }
  void TearDown(::benchmark::State&) {}
};

BENCHMARK_DEFINE_F(EigenVector, EigenAdd)(benchmark::State& st) {
  for (auto _ : st) {
    // somehow this doesn't need the DoNotOptimize directive, but valarray needs
    // it
    v3 = v2 + v1;
  }
}
BENCHMARK_REGISTER_F(EigenVector, EigenAdd);

BENCHMARK_DEFINE_F(EigenVector, RawLoopAdd)(benchmark::State& st) {
  // this measures mainly the efficiency of operator[] on Eigen Matrix
  // the Eigen operator[] probably does more complex things than
  // std::vector's operator[] and as expected , this performs miserably
  for (auto _ : st) {
    for (auto x = 0; x < v1.size(); ++x) {
      v3[x] = v1[x] + v2[x];
    }
  }
}
BENCHMARK_REGISTER_F(EigenVector, RawLoopAdd);

BENCHMARK_DEFINE_F(EigenVector, StlAdd)(benchmark::State& st) {
  // runs at about the same speed as EigenAdd
  // we are probably lucky here because std::plus<>() resolved to
  // Eigen's efficient version of add
  for (auto _ : st) {
    std::transform(v1.begin(), v1.end(), v2.begin(), v3.begin(), std::plus<>());
  }
}
BENCHMARK_REGISTER_F(EigenVector, StlAdd);
