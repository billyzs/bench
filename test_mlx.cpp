#include <benchmark/benchmark.h>
#include <mlx/mlx.h>
#include <cassert>

using namespace mlx::core;

struct MlxVector : public ::benchmark::Fixture {
  array v1{0.0, complex64};
  array v2{0.0, complex64};
  array v3{0.0, complex64};
  void SetUp(::benchmark::State&) {
    v1 = random::normal({128 * 1024 * 1024});
    v2 = random::normal({128 * 1024 * 1024});
    v3 = random::normal({128 * 1024 * 1024});
    assert(v1.size() == 128 * 1024 * 1024);
    assert(v2.size() == v1.size());
    eval(v1);
    eval(v2);
  }
  void TearDown(::benchmark::State&) {}
};

BENCHMARK_DEFINE_F(MlxVector, MlxAdd)(::benchmark::State& st) {
  for (auto _ : st) {
    v3 = v1 + v2;
    eval(v3);
  }
}
BENCHMARK_REGISTER_F(MlxVector, MlxAdd);
