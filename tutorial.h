#pragma once
#include <mlx/mlx.h>
inline constexpr size_t numElements = 1 << 28;
void array_basics();
void automatic_differentiation();
struct MlxVectorData {
  mlx::core::array v1{3.14, mlx::core::complex64};
  mlx::core::array v2{3.14, mlx::core::complex64};
  mlx::core::array v3{3.14, mlx::core::complex64};
  MlxVectorData() = default;
  explicit MlxVectorData(int);
};
int tut_main();
