# check_flag_contradictions.cmake — CTest script.
# Scans per-config resolved compile-option dumps for -fX / -fno-X pairs
# (the later occurrence silently wins on the GCC command line — the bug class
# behind the 1.4.x Release frame-pointer defect) and asserts Release
# invariants.
#
# Usage:
#   cmake -DFLAGS_DIR=<dir> -DCONFIG=<config> [-DEXPECT_PROFILING_G=ON]
#         [-DEXPECT_MARCH=<arch>] -DEXPECT_PROFILE=<portable|performance>
#         -DEXPECT_GCC_VERSION=<ver> -DEXPECT_SYSTEM_PROCESSOR=<proc>
#         -P check_flag_contradictions.cmake

if (NOT DEFINED FLAGS_DIR OR NOT DEFINED CONFIG)
    message(FATAL_ERROR "FLAGS_DIR and CONFIG are required")
endif ()

file(GLOB flag_files "${FLAGS_DIR}/*-${CONFIG}.txt")
if (NOT flag_files)
    message(FATAL_ERROR "No resolved-flag dumps matching *-${CONFIG}.txt in ${FLAGS_DIR}")
endif ()

foreach (flag_file IN LISTS flag_files)
    file(STRINGS "${flag_file}" flags)

    set(positive "")
    set(negative "")
    foreach (flag IN LISTS flags)
        if (flag MATCHES "^-fno-(.+)$")
            list(APPEND negative "${CMAKE_MATCH_1}")
        elseif (flag MATCHES "^-f(.+)$")
            list(APPEND positive "${CMAKE_MATCH_1}")
        endif ()
    endforeach ()

    foreach (feature IN LISTS negative)
        if ("${feature}" IN_LIST positive)
            message(FATAL_ERROR
                    "${flag_file}: contradictory pair -f${feature} / -fno-${feature} "
                    "in one flag set — the later occurrence silently wins")
        endif ()
    endforeach ()

    if (CONFIG STREQUAL "Release")
        if (NOT "omit-frame-pointer" IN_LIST negative)
            message(FATAL_ERROR
                    "${flag_file}: Release must carry -fno-omit-frame-pointer")
        endif ()
        if (EXPECT_PROFILING_G AND NOT "-g" IN_LIST flags)
            message(FATAL_ERROR
                    "${flag_file}: profiling build must carry -g in Release")
        endif ()
    endif ()

    # --- ISA/tuning guard (optimized configs only) ---
    if (CONFIG STREQUAL "Release" OR CONFIG STREQUAL "RelWithDebInfo")
        # Collect, don't substring-match: "-march=haswell -march=native" would
        # satisfy any single is-X-present check while ignoring the pin.
        set(march_values "")
        set(mtune_values "")
        foreach (flag IN LISTS flags)
            if (flag MATCHES "^-march=(.+)$")
                list(APPEND march_values "${CMAKE_MATCH_1}")
            elseif (flag MATCHES "^-mtune=(.+)$")
                list(APPEND mtune_values "${CMAKE_MATCH_1}")
            endif ()
        endforeach ()
        list(LENGTH march_values n_march)
        list(LENGTH mtune_values n_mtune)

        if (n_march GREATER 1)
            message(FATAL_ERROR
                    "${flag_file}: ${n_march} -march= flags (${march_values}) — "
                    "the last one silently wins")
        endif ()
        if (n_mtune GREATER 1)
            message(FATAL_ERROR
                    "${flag_file}: ${n_mtune} -mtune= flags (${mtune_values}) — "
                    "the last one silently wins")
        endif ()

        if (EXPECT_MARCH)
            # Explicit override: exactly the requested arch, and no profile
            # -mtune, because -march=<cpu> already implies -mtune=<cpu>.
            if (NOT march_values STREQUAL "${EXPECT_MARCH}")
                message(FATAL_ERROR
                        "${flag_file}: expected -march=${EXPECT_MARCH}, got "
                        "'${march_values}'")
            endif ()
            if (mtune_values)
                message(FATAL_ERROR
                        "${flag_file}: explicit GCC_OPTS_MARCH must not carry a "
                        "profile -mtune, got '${mtune_values}'")
            endif ()
        elseif (EXPECT_PROFILE STREQUAL "performance")
            if (NOT march_values STREQUAL "native")
                message(FATAL_ERROR
                        "${flag_file}: performance profile expects -march=native, "
                        "got '${march_values}'")
            endif ()
            if (mtune_values)
                message(FATAL_ERROR
                        "${flag_file}: performance profile must not set -mtune, "
                        "got '${mtune_values}'")
            endif ()
        elseif (EXPECT_PROFILE STREQUAL "portable")
            if (NOT EXPECT_SYSTEM_PROCESSOR MATCHES "^(x86_64|AMD64)$")
                if (march_values OR mtune_values)
                    message(FATAL_ERROR
                            "${flag_file}: portable profile on "
                            "${EXPECT_SYSTEM_PROCESSOR} must emit no -march/-mtune, "
                            "got '${march_values}' '${mtune_values}'")
                endif ()
            elseif (EXPECT_GCC_VERSION AND EXPECT_GCC_VERSION VERSION_GREATER_EQUAL 11)
                # Accepting either spelling regardless of version would let an
                # implementation that always emits nehalem pass on GCC 13.
                if (NOT march_values STREQUAL "x86-64-v2")
                    message(FATAL_ERROR
                            "${flag_file}: portable profile on GCC "
                            "${EXPECT_GCC_VERSION} expects -march=x86-64-v2, got "
                            "'${march_values}'")
                endif ()
                if (mtune_values)
                    message(FATAL_ERROR
                            "${flag_file}: -march=x86-64-v2 already implies "
                            "-mtune=generic, got redundant '${mtune_values}'")
                endif ()
            else ()
                if (NOT march_values STREQUAL "nehalem")
                    message(FATAL_ERROR
                            "${flag_file}: portable profile on GCC "
                            "${EXPECT_GCC_VERSION} expects -march=nehalem, got "
                            "'${march_values}'")
                endif ()
                if (NOT mtune_values STREQUAL "generic")
                    message(FATAL_ERROR
                            "${flag_file}: -march=nehalem implies -mtune=nehalem; "
                            "portable must restore -mtune=generic, got "
                            "'${mtune_values}'")
                endif ()
            endif ()
        else ()
            message(FATAL_ERROR
                    "${flag_file}: EXPECT_PROFILE must be 'portable' or "
                    "'performance', got '${EXPECT_PROFILE}'")
        endif ()
    endif ()
endforeach ()

list(LENGTH flag_files n_files)
message(STATUS "Flag guard OK: ${n_files} flag sets clean for config ${CONFIG}")
