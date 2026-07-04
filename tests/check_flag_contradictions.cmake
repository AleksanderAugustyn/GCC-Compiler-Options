# check_flag_contradictions.cmake — CTest script.
# Scans per-config resolved compile-option dumps for -fX / -fno-X pairs
# (the later occurrence silently wins on the GCC command line — the bug class
# behind the 1.4.x Release frame-pointer defect) and asserts Release
# invariants.
#
# Usage:
#   cmake -DFLAGS_DIR=<dir> -DCONFIG=<config> [-DEXPECT_PROFILING_G=ON]
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
endforeach ()

list(LENGTH flag_files n_files)
message(STATUS "Flag guard OK: ${n_files} flag sets clean for config ${CONFIG}")
