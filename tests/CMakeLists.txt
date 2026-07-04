# Compile tests for GCCCompilerOptions
# Verifies that the modules load and produce valid compiler flags.
cmake_minimum_required(VERSION 3.14)

enable_language(Fortran CXX)

include(GCCCompilerOptions/FortranCompilerOptions)
include(GCCCompilerOptions/CXXCompilerOptions)
include(GCCCompilerOptions/CompilerFlagSummary)

# --- Fortran targets ---
create_fortran_library_interface(TARGET test_fortran_lib_flags WARNINGS_AS_ERRORS OFF)
create_fortran_executable_interface(TARGET test_fortran_exe_flags WARNINGS_AS_ERRORS OFF)
create_fortran_optimization_only_interface(TARGET test_fortran_legacy_flags)

# --- C++ target ---
create_cxx_executable_interface(TARGET test_cxx_exe_flags STANDARD 17 WARNINGS_AS_ERRORS OFF)

# --- Flag summary ---
print_compiler_flag_summary(
        TARGETS test_fortran_lib_flags test_fortran_exe_flags test_fortran_legacy_flags test_cxx_exe_flags
        LABELS "Fortran library" "Fortran executable" "Legacy F77" "C++ executable"
)

# --- Compile dummy sources to verify flags are valid ---
add_executable(test_fortran_dummy dummy.f90)
target_link_libraries(test_fortran_dummy PRIVATE test_fortran_exe_flags)

add_executable(test_cxx_dummy dummy.cpp)
target_link_libraries(test_cxx_dummy PRIVATE test_cxx_exe_flags)

# --- CTest entries ---
add_test(NAME fortran_compiles COMMAND test_fortran_dummy)
add_test(NAME cxx_compiles COMMAND test_cxx_dummy)

# --- Resolved-flag dumps + contradiction guard ---
# file(GENERATE) collapses generator expressions to the active config, giving
# exactly the per-config flag list consumers will see on the command line.
foreach (flags_target IN ITEMS
        test_fortran_lib_flags test_fortran_exe_flags
        test_fortran_legacy_flags test_cxx_exe_flags)
    file(GENERATE
            OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/resolved-flags/${flags_target}-$<CONFIG>.txt
            CONTENT "$<JOIN:$<TARGET_PROPERTY:${flags_target},INTERFACE_COMPILE_OPTIONS>,\n>"
    )
endforeach ()

add_test(NAME flag_contradiction_guard
        COMMAND ${CMAKE_COMMAND}
        -DFLAGS_DIR=${CMAKE_CURRENT_BINARY_DIR}/resolved-flags
        -DCONFIG=$<CONFIG>
        -P ${CMAKE_CURRENT_SOURCE_DIR}/check_flag_contradictions.cmake
)
