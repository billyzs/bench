function(set_project_compile_options)
  add_library(
    bench_compile_opts
    INTERFACE
  )
  add_library(
    bench::compile_opts
    ALIAS
    bench_compile_opts
  )
  target_compile_definitions(
    bench_compile_opts
    INTERFACE
      $<$<AND:$<COMPILE_LANG_AND_ID:CXX,AppleClang,Clang>,$<CONFIG:Debug>>:
      _LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_DEBUG
      _LIBCPP_ENABLE_DEBUG_MODE=1 _LIBCPP_DEBUG_RANDOMIZE_UNSPECIFIED_STABILITY
      _LIBCPP_DEBUG_STRICT_WEAK_ORDERING_CHECK >
      $<$<AND:$<COMPILE_LANG_AND_ID:CXX,AppleClang,Clang>,$<CONFIG:Release>>:
      _LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_EXTENSIVE >
      $<$<CONFIG:RelWithDebInfo>:> $<$<CONFIG:MinSizeRel>:>
  )

  if("${GCC_WARNINGS}"
     STREQUAL
     ""
  )
    set(GCC_WARNINGS
        ${CLANG_WARNINGS}
        -Wmisleading-indentation # warn if indentation implies blocks where
                                 # blocks do not exist
        -Wduplicated-cond # warn if if / else chain has duplicated conditions
        -Wduplicated-branches # warn if if / else branches have duplicated code
        -Wlogical-op # warn about logical operations being used where bitwise
                     # were probably wanted
        -Wuseless-cast # warn if you perform a cast to the same type
        -Wsuggest-override # warn if an overridden member function is not marked
                           # 'override' or 'final'
    )
  endif()

  if("${CLANG_WARNINGS}"
     STREQUAL
     ""
  )
    set(CLANG_WARNINGS
        -Wall
        -Wextra # reasonable and standard
        -Wshadow # warn the user if a variable declaration shadows one from a
                 # parent context
        -Wnon-virtual-dtor # warn the user if a class with virtual functions has
                           # a non-virtual destructor. This helps
        # catch hard to track down memory errors
        -Wold-style-cast # warn for c-style casts
        -Wcast-align # warn for potential performance problem casts
        -Wunused # warn on anything being unused
        -Woverloaded-virtual # warn if you overload (not override) a virtual
                             # function
        -Wpedantic # warn if non-standard C++ is used
        -Wconversion # warn on type conversions that may lose data
        -Wsign-conversion # warn on sign conversions
        -Wnull-dereference # warn if a null dereference is detected
        -Wdouble-promotion # warn if float is implicit promoted to double
        -Wformat=2 # warn on security issues around functions that format output
                   # (ie printf)
        -Wimplicit-fallthrough # warn on statements that fallthrough without an
                               # explicit annotation
        -Wmissing-field-initializers
    )
  endif()
  if(CMAKE_CXX_COMPILER_ID
     MATCHES
     ".*Clang"
  )
    set(PROJECT_WARNINGS_CXX
        ${CLANG_WARNINGS}
    )
  elseif(
    CMAKE_CXX_COMPILER_ID
    STREQUAL
    "GNU"
  )
    set(PROJECT_WARNINGS_CXX
        ${GCC_WARNINGS}
    )
  endif()

  target_compile_options(
    bench_compile_opts
    INTERFACE
      $<$<CONFIG:Debug>: -Og > $<$<COMPILE_LANGUAGE:CXX>:
      ${PROJECT_WARNINGS_CXX} >
      $<$<AND:$<CXX_COMPILER_ID:AppleClang,Clang>,$<CONFIG:Debug,RelWithDebInfo>>:
      -glldb >
      # $<$<CONFIG:Debug>:-fsanitize=address -fsanitize=undefined
      # -fsanitize-trap>
      $<$<CONFIG:Release,RelWithDebInfo>:-O3>
      $<$<CXX_COMPILER_ID:AppleClang,Clang>:-fcolor-diagnostics> -march=native
  )

  target_compile_features(
    bench_compile_opts
    INTERFACE
      cxx_std_${CMAKE_CXX_STANDARD}
  )
endfunction()
