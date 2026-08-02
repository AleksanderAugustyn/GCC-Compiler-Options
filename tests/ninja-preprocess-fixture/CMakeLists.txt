cmake_minimum_required(VERSION 3.20)
project(ninja_preprocess_fixture LANGUAGES Fortran)

# GCC_OPTS_CMAKE_DIR is passed in by the driver script.
list(APPEND CMAKE_MODULE_PATH "${GCC_OPTS_CMAKE_DIR}")
include(GCCCompilerOptions/FortranCompilerOptions)

create_fortran_library_interface(TARGET fixture_flags WARNINGS_AS_ERRORS ON)

# Quadrant A: Fortran_PREPROCESS explicitly ON.
add_library(pp_on STATIC src/pp_on_mod.f08)
set_target_properties(pp_on PROPERTIES Fortran_PREPROCESS ON)
target_compile_definitions(pp_on PRIVATE FIXTURE_DEFINE)
target_link_libraries(pp_on PRIVATE fixture_flags)

# Quadrant B: Fortran_PREPROCESS never set — relies on gcc-opts for -cpp under
# Makefiles, and on CMake's scan pass under Ninja.
add_library(pp_unset STATIC src/pp_unset_mod.f08)
target_compile_definitions(pp_unset PRIVATE FIXTURE_DEFINE)
target_link_libraries(pp_unset PRIVATE fixture_flags)

add_executable(fixture_main src/main.f08)
target_link_libraries(fixture_main PRIVATE pp_on pp_unset fixture_flags)
