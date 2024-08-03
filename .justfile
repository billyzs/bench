alias b := build
alias bat := build_and_test
alias c := configure_no_tests
alias lt := list_tests
alias s := sync
alias t := run_tests

cpm_source_cache := "build./CPM_modules"
build_generator := "Ninja"

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
_known_build_types := "Debug,Release,RelWithDebInfo,MinSizeRel"

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

check_build_type:
    #!/usr/bin/env sh -eu
    echo "just configured to use BUILD_TYPE={{ BUILD_TYPE }}"
    IFS=',' read -ra valid_values <<< {{ _known_build_types }}

    case "${valid_values[@]}" in 
    *"{{ BUILD_TYPE }}"*)
        exit 0
        ;;
    *)
        echo "BUILD_TYPE={{ BUILD_TYPE }} is not valid"
        exit 1
        ;;
    esac

# E.g. just configure 'ON' -DCMAKE_OSX_ARCHITECTURES='arm64\;x86_64'

# run cmake configure step with Ninja and caching CPM
configure BUILD_TESTING="OFF" +ADDITIONAL_ARGS='': check_build_type
    cmake \
    -G{{ build_generator }} \
    -DBUILD_TESTING={{ BUILD_TESTING }} \
    -DCMAKE_BUILD_TYPE={{ BUILD_TYPE }} \
    -DCPM_SOURCE_CACHE={{ cpm_source_cache }} \
    {{ ADDITIONAL_ARGS }} \
    -S ./ \
    -B ./build/{{ BUILD_TYPE }}

configure_no_tests: (configure "OFF")

configure_with_tests: (configure "ON")

# command can be passed e.g. just _build --verbose -t clean

# the quick version of build; assume the configure and build have been run manually
_build +ADDITIONAL_ARGS="--verbose -t all":
    cmake --build ./build/{{ BUILD_TYPE }} {{ ADDITIONAL_ARGS }}

# can specify additional args as such: 'BUILD_TYPE=Release just b -t <tgt_name>'

# by default, build all targets excluding tests;
build +ADDITIONAL_ARGS="-t all": configure_no_tests (_build ADDITIONAL_ARGS)

# clean the current build type
clean: (_build '--verbose -t clean')

# E.g. just -t -R smoke_test -VV --debug

# run all tests by default; skip building. E.g. 'just t -E Trig' excludes all tests with 'Trig' in name
[no-exit-message]
run_tests +TEST_ARGS="-R .*":
    ctest -F --parallel --progress --output-on-failure \
    --schedule-random --no-tests=error \
    {{ TEST_ARGS }} \
    --test-dir build/{{ BUILD_TYPE }}/tests

# E.g. just bat '-t bench_main' -E Trig --interactive-debug-mode 1
# (notice the '' around the first argument, which is given to cmake --build)

# by default build everything and run all tests; supply relevant arguments to build and run a specific test
build_and_test BUILD_ARGS="-t all" +TEST_ARGS="-R .*":
    configure_with_tests (_build BUILD_ARGS) (run_tests TEST_ARGS)

# the unsafe version of list_tests; assume the configure step has been run manually
[no-exit-message]
_list_tests +ADDITIONAL_ARGS="-R .*":
    @ctest --test-dir ./build/{{ BUILD_TYPE }}/tests -N {{ ADDITIONAL_ARGS }}

# print name of tests
list_tests +ADDITIONAL_ARGS="-R .*":
    configure_with_tests (_list_tests BUILD_TYPE ADDITIONAL_ARGS)

[no-exit-message]
sync REPO='origin' REFSPEC='main' +ADDITIONAL_ARGS="":
    git pull \
    --rebase --set-upstream --progress --autostash --recurse-submodules \
    -t -j{{ num_cpus() }} \
    {{ ADDITIONAL_ARGS }} \
    {{ REPO }} {{ REFSPEC }}

[no-exit-message]
format_cxx:
    git diff -U0 --no-color --relative HEAD^ | scripts/clang-format-diff -p1 -i

[no-exit-message]
format_just:
    just --fmt --unstable

[no-exit-message]
fmt: format_cxx format_just
