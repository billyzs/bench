#pragma once
#include <mlx/mlx.h>
#include "config.h"
void array_basics();
void automatic_differentiation();
struct MlxVectorData {
  mlx::core::array v1{3.14, mlx::core::complex64};
  mlx::core::array v2{3.14, mlx::core::complex64};
  mlx::core::array v3{3.14, mlx::core::complex64};
  MlxVectorData() = default;
  explicit MlxVectorData(int, mlx::core::Dtype dtype = mlx::core::float32);
};
int tut_main();
