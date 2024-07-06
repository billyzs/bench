include(FetchContent)
set(BUILD_TESTING OFF)
set(MLX_BUILD_TESTS OFF)
set(MLX_BUILD_EXAMPLES OFF)
set(MLX_BUILD_BENCHMARKS OFF)
set(MLX_BUILD_METAL ON)
set(MLX_METAL_JIT ON)
set(_MLX_VERSION 0.15.2)
FetchContent_Declare(
    mlx
    GIT_REPOSITORY https://github.com/ml-explore/mlx.git
    GIT_TAG        v${_MLX_VERSION}
    GIT_SHALLOW    TRUE
    GIT_PROGRESS   TURE
    # this makes FetchContent try find_package() with the supplied arguments first;
    # since we are requiring a version that is not available in brew, it will fall
    # back to building from source
    EXCLUDE_FROM_ALL
    FIND_PACKAGE_ARGS ${_MLX_VERSION} EXACT NAMES mlx 
)
FetchContent_MakeAvailable(mlx)
