alias b := build
alias bat := build_and_test
alias c := configure_no_tests
alias lt := list_tests
alias t := run_tests

cpm_source_cache := "build./CPM_modules"
build_generator := "Ninja"

# Can either be specified inline as in 'BUILD_TYPE=Debug just c b',
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

BUILD_TYPE := env_var_or_default("BUILD_TYPE", "Debug")
_known_build_types := "Debug,Release,RelWithDebInfo,MinSizeRel"

default:
    @just --choose

check_build_type:
    #!/usr/bin/env sh -eu
    echo "just configured to use BUILD_TYPE={{ BUILD_TYPE }}"
    IFS=',' read -ra valid_values <<< {{ _known_build_types }}

    case "${valid_values[@]}" in 
    *"$BUILD_TYPE"*)
        exit 0
        ;;
    *)
        echo "BUILD_TYPE={{ BUILD_TYPE }} is not valid"
        exit 1
        ;;
    esac

configure BUILD_TESTING="OFF": check_build_type
    cmake \
    -G{{ build_generator }} \
    -DBUILD_TESTING={{ BUILD_TESTING }} \
    -DCMAKE_BUILD_TYPE={{ BUILD_TYPE }} \
    -DCPM_SOURCE_CACHE={{ cpm_source_cache }} \
    -S ./ \
    -B ./build/{{ BUILD_TYPE }}

configure_no_tests: (configure "OFF")

configure_with_tests: (configure "ON")

# the quick version of build; assume the configure and build have been run manually
_build +ADDITIONAL_ARGS="--verbose -t all":
    cmake --build ./build/{{ BUILD_TYPE }} {{ ADDITIONAL_ARGS }}

# by default, build all targets excluding tests; can specify additional args as such: 'BUILD_TYPE=Release just b -t <tgt_name>'
build +ADDITIONAL_ARGS="-t all": configure_no_tests (_build ADDITIONAL_ARGS)

# run all tests by default; skip building
run_tests TEST_ARGS="-R .*":
    ctest -F --parallel --progress --output-on-failure \
    --schedule-random --no-tests=error \
    {{ TEST_ARGS }} \
    --test-dir build/{{ BUILD_TYPE }}/tests

# by default build everything and run all tests; supply relevant arguments to build and run a specific test
build_and_test BUILD_ARGS="-t all" TEST_ARGS="-R .*": configure_with_tests (_build BUILD_ARGS) (run_tests TEST_ARGS)

# the unsafe version of list_tests; assume the configure step has been run manually
[no-exit-message]
_list_tests +ADDITIONAL_ARGS="-R .*":
    @ctest --test-dir ./build/{{ BUILD_TYPE }}/tests -N {{ ADDITIONAL_ARGS }}

# print name of tests
list_tests +ADDITIONAL_ARGS="-R .*": configure_with_tests (_list_tests BUILD_TYPE ADDITIONAL_ARGS)

# print a brief description
help:
    @echo \
    "just is a command runner similar too make.\n\
     The equivalent of Makefile for just is ./.justfile, which contains recipes \
     that can be invoked as 'just <recipe-name>'.\n\
     Run 'just --list' to get available recipes and a brief description.\n\
     There are several hidden recipes such as _build that may be useful too, \
     see .justfile for all recipes"
