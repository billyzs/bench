set(cmake_version
    $ENV{CMAKE_VERSION}
)
set(ninja_version
    $ENV{NINJA_VERSION}
)
set(ccache_desired_version
    $ENV{CCACHE_VERSION}
)
if(NOT
   CWD
)
  set(CWD
      $ENV{CWD}
  )
endif()

set(BIN
    "${CWD}/bin"
)
set(TMP
    "${CWD}/tmp"
)

message(
  WARNING
    "Using host CMake version: ${CMAKE_VERSION} on architecture ${CMAKE_SYSTEM_PROCESSOR}"
)

if(${CMAKE_HOST_SYSTEM_NAME}
   STREQUAL
   "Windows"
)
  set(ninja_suffix
      "win.zip"
  )
  set(cmake_suffix
      "windows-x86_64.zip"
  )
  set(cmake_dir
      "cmake-${cmake_version}-windows-x86_64/bin"
  )
  set(ccache_dir
      "ccache-${ccache_desired_version}-windows-x86_64"
  )
  set(ccache_archive
      "${ccache_dir}.zip"
  )
elseif(
  ${CMAKE_HOST_SYSTEM_NAME}
  STREQUAL
  "Linux"
)
  set(ninja_suffix
      "linux.zip"
  )
  set(cmake_suffix
      "linux-x86_64.tar.gz"
  )
  set(cmake_dir
      "cmake-${cmake_version}-linux-x86_64/bin"
  )
  set(ccache_dir
      "ccache-$ENV{ccache_desired_version}-linux-x86_64"
  )
  set(ccache_archive
      "${ccache_dir}.tar.xz"
  )
elseif(
  ${CMAKE_HOST_SYSTEM_NAME}
  STREQUAL
  "Darwin"
)
  set(ninja_suffix
      "mac.zip"
  )
  set(cmake_suffix
      "macos-universal.tar.gz"
  )
  set(cmake_dir
      "cmake-${cmake_version}-macos-universal/CMake.app/Contents/bin"
  )
  set(ccache_dir
      "ccache-${ccache_desired_version}-darwin"
  )
  set(ccache_archive
      "${ccache_dir}.tar.gz"
  )
endif()

set(cmake_url
    "https://github.com/Kitware/CMake/releases/download/v${cmake_version}/cmake-${cmake_version}-${cmake_suffix}"
)
execute_process(
  COMMAND
    "${BIN}/${cmake_dir}/cmake" "--version"
  OUTPUT_VARIABLE
    cmake_curr_version
)
if(cmake_curr_version
   MATCHES
   ${cmake_version}
)
  message(WARNING
            "using cached cmake\n${cmake_curr_version}"
  )
else()
  message(WARNING
            "downloading from ${cmake_url}"
  )
  file(
    DOWNLOAD
    "${cmake_url}"
    "${TMP}/cmake.zip"
  )
  file(
    # cmake needs its particular layout and aux files (Findxyz.cmake modules)
    ARCHIVE_EXTRACT
    INPUT
    "${TMP}/cmake.zip"
    DESTINATION
    ${BIN}
    TOUCH
  )
  if(EXISTS
     "${BIN}/${cmake_dir}/cmake"
  )
    message(WARNING
              "cmake downloaded at ${BIN}/${cmake_dir}/cmake"
    )
    file(
      REMOVE
      "${BIN}/${cmake_dir}/cmake-gui"
    )
  else()
    message(FATAL_ERROR
              "cmake download or extract error"
    )
  endif()
endif()

set(ninja_url
    "https://github.com/ninja-build/ninja/releases/download/v${ninja_version}/ninja-${ninja_suffix}"
)
execute_process(
  COMMAND
    "${BIN}/ninja" "--version"
  OUTPUT_VARIABLE
    ninja_curr_version
)
if(ninja_curr_version
   MATCHES
   ${ninja_version}
)
  message(WARNING
            "using cached ninja ${ninja_curr_version}"
  )
else()
  message(WARNING
            "downloading from ${ninja_url}"
  )
  file(
    DOWNLOAD
    "${ninja_url}"
    "${TMP}/ninja.zip"
  )
  file(
    ARCHIVE_EXTRACT
    INPUT
    "${TMP}/ninja.zip"
    DESTINATION
    "${TMP}"
    TOUCH
  )
  file(
    COPY_FILE
    "${TMP}/ninja"
    "${BIN}/ninja"
    ONLY_IF_DIFFERENT
  )
  if(EXISTS
     "${BIN}/ninja"
  )
    message(WARNING
              "downloaded ninja at ${BIN}/ninja"
    )
  else()
    message(FATAL_ERROR
              "ninja download or extract error"
    )
  endif()
endif()

set(ccache_url
    "https://github.com/ccache/ccache/releases/download/v$ENV{CCACHE_VERSION}/${ccache_archive}"
)
execute_process(
  COMMAND
    "${BIN}/ccache" "--version"
  OUTPUT_VARIABLE
    ccache_curr_version
)
if(ccache_curr_version
   MATCHES
   ${ccache_desired_version}
)
  message(WARNING
            "using cached ccache\n${ccache_curr_version}"
  )
else()
  file(
    DOWNLOAD
    "${ccache_url}"
    "${TMP}/${ccache_archive}"
  )
  file(
    ARCHIVE_EXTRACT
    INPUT
    "${TMP}/${ccache_archive}"
    DESTINATION
    ${TMP}
    PATTERNS
    "${ccache_dir}/ccache"
    TOUCH
  )

  file(
    RENAME
    "${TMP}/${ccache_dir}/ccache"
    "${BIN}/ccache"
  )
endif()

# make everything executable
file(
  CHMOD_RECURSE
  "${BIN}"
  "${BIN}/${cmake_dir}"
  PERMISSIONS
  OWNER_READ
  OWNER_WRITE
  OWNER_EXECUTE
  GROUP_READ
  GROUP_EXECUTE
  WORLD_READ
  WORLD_EXECUTE
)

message(
  WARNING
    "removing ${TMP}"
)
file(
  REMOVE_RECURSE
  ${TMP}
)
message(
  WARNING
    "removed ${TMP}"
)

# Add to PATH environment variable cmake_path(CONVERT "$ENV{GITHUB_PATH}"
# TO_CMAKE_PATH_LIST curr_sys_path NORMALIZE) cmake_path(CONVERT
# "${curr_sys_path}/$ENV{GITHUB_WORKSPACE}" TO_NATIVE_PATH_LIST curr_sys_path
# NORMALIZE)
file(
  TO_CMAKE_PATH
  "${BIN}/${cmake_dir}"
  cmake_dir
)
set(path_separator
    ":"
)
if(${CMAKE_HOST_SYSTEM_NAME}
   STREQUAL
   "Windows"
)
  set(path_separator
      ";"
  )
endif()

if($ENV{GITHUB_ACTIONS}
   STREQUAL
   "true"
)
  file(
    APPEND
    "$ENV{GITHUB_PATH}"
    "${BIN}${path_separator}${cmake_dir}"
  )
  # on CI, set some other paths in case it's useful
  file(
    TO_NATIVE_PATH
    "${BIN}/ccache\n"
    ccache_bin
  )
  file(
    CONFIGURE
    OUTPUT
    "$ENV{GITHUB_OUTPUT}"
    CONTENT
    "ccache-bin=${ccache_bin}"
  )
endif()
