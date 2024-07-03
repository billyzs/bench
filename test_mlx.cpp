#include <benchmark/benchmark.h>
#include <mlx/mlx.h>
#include <cassert>
#include <optional>
#include "tutorial.h"

using namespace mlx::core;

struct MlxVector : public ::benchmark::Fixture {
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
  ~MlxVector() {
    teardown();
  };
};

BENCHMARK_DEFINE_F(MlxVector, MlxAdd)(::benchmark::State& st) {
  for (auto _ : st) {
    dd->v3 = dd->v1 + dd->v2;
    eval(dd->v3);
  }
}
BENCHMARK_REGISTER_F(MlxVector, MlxAdd);
