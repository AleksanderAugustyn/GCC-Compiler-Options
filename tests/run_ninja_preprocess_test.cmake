# run_ninja_preprocess_test.cmake — nested-CMake regression test for the
# -cpp / -fpreprocessed interaction (agenda item 10).
#
# Usage: cmake -DFIXTURE_DIR=<dir> -DWORK_DIR=<dir> -DGCC_OPTS_CMAKE_DIR=<dir>
#              [-DREQUIRE_NINJA=ON] -P run_ninja_preprocess_test.cmake

foreach (required FIXTURE_DIR WORK_DIR GCC_OPTS_CMAKE_DIR)
    if (NOT DEFINED ${required})
        message(FATAL_ERROR "${required} is required")
    endif ()
endforeach ()

find_program(NINJA_EXE ninja)
if (NOT NINJA_EXE)
    if (REQUIRE_NINJA)
        message(FATAL_ERROR
                "ninja not found and REQUIRE_NINJA=ON: this test is the only "
                "coverage of the -cpp/-fpreprocessed bug and must not be skipped "
                "in CI")
    endif ()
    message(STATUS "SKIPPED: ninja not found; set REQUIRE_NINJA=ON to make this fatal")
    return()
endif ()

# Fresh tree every run — a stale cache would hide a configure-time regression.
file(REMOVE_RECURSE "${WORK_DIR}")
file(MAKE_DIRECTORY "${WORK_DIR}")

execute_process(
        COMMAND ${CMAKE_COMMAND} -S "${FIXTURE_DIR}" -B "${WORK_DIR}" -G Ninja
        -DCMAKE_BUILD_TYPE=Release
        -DGCC_OPTS_CMAKE_DIR=${GCC_OPTS_CMAKE_DIR}
        RESULT_VARIABLE configure_result
        OUTPUT_VARIABLE configure_output
        ERROR_VARIABLE configure_output
)
if (NOT configure_result EQUAL 0)
    message(FATAL_ERROR "fixture configure failed:\n${configure_output}")
endif ()

execute_process(
        COMMAND ${CMAKE_COMMAND} --build "${WORK_DIR}"
        RESULT_VARIABLE build_result
        OUTPUT_VARIABLE build_output
        ERROR_VARIABLE build_output
)
if (NOT build_result EQUAL 0)
    message(FATAL_ERROR
            "fixture build failed under Ninja — this is the -cpp/-fpreprocessed "
            "regression:\n${build_output}")
endif ()

execute_process(
        COMMAND "${WORK_DIR}/fixture_main"
        RESULT_VARIABLE run_result
        OUTPUT_VARIABLE run_output
        ERROR_VARIABLE run_output
)
if (NOT run_result EQUAL 0)
    message(FATAL_ERROR "fixture ran but reported wrong values:\n${run_output}")
endif ()

message(STATUS "Ninja preprocess guard OK: ${run_output}")
