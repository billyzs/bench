#include <benchmark/benchmark.h>
#include <mlx/mlx.h>
#include <cassert>
#include <optional>
#include "tutorial.h"

using namespace mlx::core;

struct MlxFixture : public ::benchmark::Fixture {
  // once mlx arrays are included as data members of a subclass of Fixture
  // program will segfault on start; tried multiple inheritance, direct
  // inclusion of MlxVectorData, direct inclusion + rule of 5,
  // all no dice. So far this seems to be the only way that works
  // Maybe all data has to be decoupled from the fixture
  std::optional<MlxVectorData> dd{};
  void setup() {
    dd = std::make_optional<MlxVectorData>(numElements);
  }
  void SetUp(::benchmark::State&) override {
    setup();
  }
  void teardown() {
    dd.reset();
  }
  void TearDown(::benchmark::State&) override {
    teardown();
  }
  ~MlxFixture() {
    teardown();
  };
};

BENCHMARK_DEFINE_F(MlxFixture, MlxTrig)(::benchmark::State& st) {
  for (auto _ : st) {
    // dd->v3 = mlx::core::sin(dd->v1) + mlx::core::cos(dd->v2);
    // eval(dd->v3);
    dd->v3 = mlx::core::arctan2(dd->v1, dd->v2);
    eval(dd->v3);
  }
}
BENCHMARK_REGISTER_F(MlxFixture, MlxTrig);
BENCHMARK_DEFINE_F(MlxFixture, MlxAdd)(::benchmark::State& st) {
  for (auto _ : st) {
    dd->v3 = dd->v1 + dd->v2;
    eval(dd->v3);
  }
}
BENCHMARK_REGISTER_F(MlxFixture, MlxAdd);
void VectorAdd_Mlx(::benchmark::State& st, const mlx::core::Dtype dtype) {
  MlxVectorData d(numElements * st.range(0), dtype);
  for (auto _ : st) {
    ::benchmark::DoNotOptimize(d.v3);
    d.v3 = d.v1 + d.v2;
    d.v3.eval();
  }
}
BENCHMARK_CAPTURE(VectorAdd_Mlx, Bfloat16, mlx::core::bfloat16)
    ->DenseRange(1, 4, 1);
BENCHMARK_CAPTURE(VectorAdd_Mlx, Float32, mlx::core::float32)
    ->DenseRange(1, 2, 1);
