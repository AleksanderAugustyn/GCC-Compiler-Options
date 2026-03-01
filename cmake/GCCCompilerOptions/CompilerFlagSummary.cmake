# CompilerFlagSummary.cmake - Flag introspection and pretty-print reporting
#
# Introspects interface targets and prints the resolved compile/link flags
# for the current build type.
#
# Public function:
#   print_compiler_flag_summary(TARGETS <t1> <t2> ... LABELS <l1> <l2> ...)
#
include_guard(GLOBAL)

# =============================================================================
# filter_flags_for_build_type — Evaluate generator expressions for current config
# =============================================================================
function(filter_flags_for_build_type INPUT_FLAGS OUTPUT_VAR)
    # Only works for single-configuration generators where CMAKE_BUILD_TYPE is known
    if (CMAKE_CONFIGURATION_TYPES)
        message(WARNING "CompilerFlagSummary: Cannot display build-type specific flags for "
                "multi-configuration generators like '${CMAKE_GENERATOR}'. The summary will be incomplete.")
        set(${OUTPUT_VAR} "" PARENT_SCOPE)
        return()
    endif ()

    set(FILTERED_FLAGS "")
    foreach (FLAG ${INPUT_FLAGS})
        set(INCLUDE_FLAG FALSE)

        # Simple config-specific: $<$<CONFIG:Type>:flag>
        if (FLAG MATCHES "^\\$<\\$<CONFIG:([^>]+)>:(.+)>$")
            set(FLAG_CONFIG "${CMAKE_MATCH_1}")
            set(FLAG_VALUE "${CMAKE_MATCH_2}")
            if (FLAG_CONFIG STREQUAL CMAKE_BUILD_TYPE)
                set(INCLUDE_FLAG TRUE)
            endif ()
            # OR expression: $<$<OR:$<CONFIG:A>,$<CONFIG:B>>:flag>
        elseif (FLAG MATCHES "^\\$<\\$<OR:(.+)>:(.+)>$")
            set(OR_CONDITION "${CMAKE_MATCH_1}")
            set(FLAG_VALUE "${CMAKE_MATCH_2}")
            string(REGEX MATCHALL "\\$<CONFIG:([^>]+)>" CONFIG_MATCHES "${OR_CONDITION}")
            foreach (CONFIG_MATCH ${CONFIG_MATCHES})
                if (CONFIG_MATCH MATCHES "\\$<CONFIG:([^>]+)>")
                    set(FLAG_CONFIG "${CMAKE_MATCH_1}")
                    if (FLAG_CONFIG STREQUAL CMAKE_BUILD_TYPE)
                        set(INCLUDE_FLAG TRUE)
                        break()
                    endif ()
                endif ()
            endforeach ()
        else ()
            # Not config-specific — always include
            set(INCLUDE_FLAG TRUE)
            set(FLAG_VALUE "${FLAG}")
        endif ()

        if (INCLUDE_FLAG)
            list(APPEND FILTERED_FLAGS "${FLAG_VALUE}")
        endif ()
    endforeach ()

    set(${OUTPUT_VAR} ${FILTERED_FLAGS} PARENT_SCOPE)
endfunction()

# =============================================================================
# print_compiler_flag_summary — Report flags for multiple interface targets
# =============================================================================
function(print_compiler_flag_summary)
    set(options "")
    set(oneValueArgs "")
    set(multiValueArgs TARGETS LABELS)
    cmake_parse_arguments(SUMMARY "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    list(LENGTH SUMMARY_TARGETS TARGET_COUNT)
    list(LENGTH SUMMARY_LABELS LABEL_COUNT)

    if (NOT TARGET_COUNT EQUAL LABEL_COUNT)
        message(FATAL_ERROR "CompilerFlagSummary: TARGETS and LABELS lists must have the same length "
                "(got ${TARGET_COUNT} targets and ${LABEL_COUNT} labels)")
    endif ()

    message(STATUS "")
    message(STATUS "========================================")
    message(STATUS "Compiler Flags Summary for ${CMAKE_BUILD_TYPE}")
    message(STATUS "========================================")

    math(EXPR LAST_INDEX "${TARGET_COUNT} - 1")
    foreach (IDX RANGE ${LAST_INDEX})
        list(GET SUMMARY_TARGETS ${IDX} CURRENT_TARGET)
        list(GET SUMMARY_LABELS ${IDX} CURRENT_LABEL)

        get_target_property(COMPILE_FLAGS ${CURRENT_TARGET} INTERFACE_COMPILE_OPTIONS)
        get_target_property(LINK_FLAGS ${CURRENT_TARGET} INTERFACE_LINK_OPTIONS)

        if (NOT COMPILE_FLAGS)
            set(COMPILE_FLAGS "")
        endif ()
        if (NOT LINK_FLAGS)
            set(LINK_FLAGS "")
        endif ()

        filter_flags_for_build_type("${COMPILE_FLAGS}" FILTERED_COMPILE)
        filter_flags_for_build_type("${LINK_FLAGS}" FILTERED_LINK)

        message(STATUS "")
        message(STATUS "${CURRENT_LABEL} [${CURRENT_TARGET}]:")
        message(STATUS "  Compiler flags:")
        if (FILTERED_COMPILE)
            foreach (FLAG ${FILTERED_COMPILE})
                message(STATUS "    ${FLAG}")
            endforeach ()
        else ()
            message(STATUS "    (none)")
        endif ()

        message(STATUS "  Linker flags:")
        if (FILTERED_LINK)
            foreach (FLAG ${FILTERED_LINK})
                message(STATUS "    ${FLAG}")
            endforeach ()
        else ()
            message(STATUS "    (none)")
        endif ()
    endforeach ()

    message(STATUS "")
    message(STATUS "========================================")
    message(STATUS "")
endfunction()
