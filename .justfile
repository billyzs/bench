alias b := build
alias bat := build_and_test
alias c := configure
alias cbt := check_build_type
alias lt := list_tests
alias s := sync
alias t := run_tests

# BUILD_TYPE Can either be specified inline e.g. 'BUILD_TYPE=Debug just c b',
# or exported to the current shell interpreter by
# export BUILD_TYPE=Release
# just c 'ON'
# just b # <- will also use BUILD_TYPE=Debug
# The former sets the variable for the current invocation of just
# whereas the latter sets the variable for all subsequent commands in the current
# shell interpreter
# Notice that 'BUILD_TYPE=Release just c; just b' will cause 'just b' to have
# different value for BUILD_TYPE, since the inline definition of BUILD_TYPE does
# not live past the ';'

BUILD_TYPE := env("BUILD_TYPE", "Debug")

default:
    @just --choose

# in the body of a recipe, every line is executed on a new shell. Multiline
# recipes needs to use \ to join lines

# print a brief description
help:
    @echo \
    "just is a command runner similar too make.\n\
     The equivalent of Makefile for just is ./.justfile, which contains recipes \
     that can be invoked as 'just <recipe-name>'.\n\
     Run 'just --list' to get available recipes and a brief description.\n\
     There are several hidden recipes such as _build that may be useful too, \
     see .justfile for all recipes and examples of advanced usages"

# check if just is using one of the config types specified in CMakePresets.json
[no-exit-message]
check_build_type:
    #!/usr/bin/env python3
    import json
    with open("./CMakePresets.json") as f:
        p = json.load(f)
    build_type = "{{ BUILD_TYPE }}"
    known_build_types = set([c['name'] for c in p['configurePresets']])
    if build_type not in known_build_types:
        raise ValueError(f"{build_type=} is not one of the {known_build_types=}")

# check built type for environments that do not have python
[no-exit-message]
_check_build_type:
    #!/usr/bin/env sh -eu
    known_build_types="Debug,Release,RelWithDebInfo,MinSizeRel"
    IFS=',' read -r -a valid_values <<< "$known_build_types"
    BUILD_TYPE="{{ BUILD_TYPE }}"
    match_found=0
    for value in "${valid_values[@]}"; do
        if [ "$value" == "$BUILD_TYPE" ]; then
            match_found=1
            break
        fi
    done
    if [ $match_found -eq 1 ]; then
        echo "just configured to use ${BUILD_TYPE}"
        exit 0
    else
        echo "NO - '$BUILD_TYPE' is not one of ${known_build_types}"
        exit 1
    fi

# E.g. just configure 'ON' -DCMAKE_OSX_ARCHITECTURES='arm64\;x86_64'

# run cmake configure step based on CMakePresets.json
configure +ADDITIONAL_ARGS='': check_build_type
    cmake \
    --preset {{ BUILD_TYPE }} \
    {{ ADDITIONAL_ARGS }} \
    -S ./

# configure with testing enabled even if testing is disabled in CMakePresets.json
configure_with_tests: (configure "-DBUILD_TESTING='ON'")

# command can be passed e.g. just _build --verbose -t clean

# the quick version of build; assume the configure and build have been run manually
_build +ADDITIONAL_ARGS="--verbose -t all":
    cmake --build --preset={{ BUILD_TYPE }} {{ ADDITIONAL_ARGS }}

# can specify additional args as such: 'BUILD_TYPE=Release just b -t <tgt_name>'

# by default, build all targets
build +ADDITIONAL_ARGS="-t all": configure (_build ADDITIONAL_ARGS)

# clean the current build type
clean: (_build '--verbose -t clean')

# E.g. just t -R smoke_test -VV --debug

# run all tests by default; skip building. E.g. 'just t -E Trig' excludes all tests with 'Trig' in name
[no-exit-message]
run_tests +TEST_ARGS="-R .*":
    ctest -F --parallel --progress --output-on-failure \
    --preset {{ BUILD_TYPE }} \
    --schedule-random --no-tests=error \
    {{ TEST_ARGS }} \
    --test-dir build/{{ BUILD_TYPE }}/tests

# E.g. just bat '-t bench_main' -E Trig --interactive-debug-mode 1
# (notice the '' around the first argument, which is given to cmake --build)

# by default build everything and run all tests; supply relevant arguments to build and run a specific test
build_and_test BUILD_ARGS="-t all" +TEST_ARGS="-R .*": configure_with_tests (_build BUILD_ARGS) (run_tests TEST_ARGS)

# the unsafe version of list_tests; assume the configure step has been run manually
[no-exit-message]
_list_tests _BUILD_TYPE=BUILD_TYPE +ADDITIONAL_ARGS="-R .*":
    @ctest --preset {{ _BUILD_TYPE }} -N {{ ADDITIONAL_ARGS }}

# print name of tests
list_tests +ADDITIONAL_ARGS="-R .*": configure_with_tests (_list_tests BUILD_TYPE ADDITIONAL_ARGS)

# fancy version of git pull with some sane defaults
[no-exit-message]
sync REPO='origin' REFSPEC='main' +ADDITIONAL_ARGS="":
    git pull \
    --rebase --set-upstream --progress --autostash --recurse-submodules \
    -t -j{{ num_cpus() }} \
    {{ ADDITIONAL_ARGS }} \
    {{ REPO }} {{ REFSPEC }}

# format all changed lines in c++ files (source and header)
[no-exit-message]
format_cxx:
    git diff -U0 --no-color --relative HEAD^ | scripts/clang-format-diff -p1 -i

# format the justfile itself
[no-exit-message]
format_just:
    just --fmt --unstable

# format cmake files in place
[no-exit-message]
format_cmake:
    #!/usr/bin/env sh -eu
    c=`git diff --name-only | rg "CMakeLists\.txt$|\.cmake$"`
    s="${c//$'\n'/ }"
    cmake-format -i ${s}

[no-exit-message]
fmt: format_cxx format_just format_cmake
