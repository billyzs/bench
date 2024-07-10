# Enable cache if available
function(enable_cache)
  set(CACHE_OPTION
      "ccache"
      CACHE
        STRING "Compiler cache to be used"
  )
  set(CACHE_OPTION_VALUES
      "ccache"
      "sccache"
  )
  set_property(
    CACHE
      CACHE_OPTION
    PROPERTY
      STRINGS ${CACHE_OPTION_VALUES}
  )
  list(
    FIND
    CACHE_OPTION_VALUES
    ${CACHE_OPTION}
    CACHE_OPTION_INDEX
  )

  if(${CACHE_OPTION_INDEX}
     EQUAL
     -1
  )
    message(
      STATUS
        "Using custom compiler cache system: '${CACHE_OPTION}'; "
        "explicitly supported entries are ${CACHE_OPTION_VALUES}"
    )
  endif()
  if(IS_EXECUTABLE
     ${CMAKE_CXX_COMPILER_LAUNCHER}
  )
    set(CACHE_BINARY
        ${CMAKE_CXX_COMPILER_LAUNCHER}
    )
  elseif(
    IS_EXECUTABLE
    ${CMAKE_C_COMPILER_LAUNCHER}
  )
    set(CACHE_BINARY
        ${CMAKE_C_COMPILER_LAUNCHER}
    )
  else()

    find_program(
      CACHE_BINARY
      NAMES
        ${CACHE_OPTION_VALUES} ${CMAKE_CXX_COMPILER_LAUNCHER}
        ${CMAKE_C_COMPILER_LAUNCHER}
    )
  endif()
  if(CACHE_BINARY)
    set(CMAKE_CXX_COMPILER_LAUNCHER
        ${CACHE_BINARY}
        CACHE
          FILEPATH "CXX compiler cache used"
    )
    set(CMAKE_C_COMPILER_LAUNCHER
        ${CACHE_BINARY}
        CACHE
          FILEPATH "C compiler cache used"
    )
    execute_process(
      COMMAND
        ${CACHE_BINARY} --version
      OUTPUT_VARIABLE
        cache_cmd_ver
    )
    message(STATUS
              "${CACHE_BINARY} found and enabled; version\n${cache_cmd_ver}"
    )
  else()
    message(WARNING
              "${CACHE_OPTION} is enabled but was not found. Not using it"
    )
  endif()
endfunction()
