# FortranCompilerOptions.cmake - gfortran dialect, warnings, and runtime checks
#
# Calls gcc_base_apply_options() from GCCBaseOptions.cmake for shared backend flags.
# This module owns only Fortran-specific flags.
#
# Public functions:
#   create_fortran_interface(...)
#   create_fortran_library_interface(...)
#   create_fortran_executable_interface(...)
#   create_fortran_optimization_only_interface(...)
#
# GCC-only by design.
include_guard(GLOBAL)
include(GCCCompilerOptions/GCCBaseOptions)

if (NOT CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
    message(WARNING "FortranCompilerOptions: Designed for GNU Fortran. Current: ${CMAKE_Fortran_COMPILER_ID}")
endif ()

# =============================================================================
# create_fortran_interface — Full Fortran interface target
# =============================================================================
function(create_fortran_interface)
    set(options "")
    set(oneValueArgs
            TARGET TARGET_TYPE STANDARD
            PEDANTIC_WARNINGS WARNINGS_AS_ERRORS
            INITIALIZE_DEBUG PREPROCESSOR FREE_FORM
            LTO PGO_GENERATE PGO_USE
            SANITIZERS COVERAGE DEAD_CODE_ELIMINATION
            GDB_OPTIMIZATION VECTORIZATION_REPORT OPENMP
    )
    set(multiValueArgs "")
    cmake_parse_arguments(FORT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # --- Defaults ---
    if (NOT FORT_TARGET)
        set(FORT_TARGET fortran_options)
    endif ()
    if (NOT FORT_TARGET_TYPE)
        set(FORT_TARGET_TYPE EXECUTABLE)
    endif ()
    if (NOT FORT_STANDARD)
        set(FORT_STANDARD 2018)
    endif ()
    if (NOT DEFINED FORT_PEDANTIC_WARNINGS)
        set(FORT_PEDANTIC_WARNINGS ON)
    endif ()
    if (NOT DEFINED FORT_WARNINGS_AS_ERRORS)
        set(FORT_WARNINGS_AS_ERRORS ON)
    endif ()
    if (NOT DEFINED FORT_INITIALIZE_DEBUG)
        set(FORT_INITIALIZE_DEBUG OFF)
    endif ()
    if (NOT DEFINED FORT_PREPROCESSOR)
        set(FORT_PREPROCESSOR ON)
    endif ()
    if (NOT DEFINED FORT_FREE_FORM)
        set(FORT_FREE_FORM ON)
    endif ()
    if (NOT DEFINED FORT_LTO)
        set(FORT_LTO ON)
    endif ()
    if (NOT DEFINED FORT_PGO_GENERATE)
        set(FORT_PGO_GENERATE OFF)
    endif ()
    if (NOT DEFINED FORT_PGO_USE)
        set(FORT_PGO_USE OFF)
    endif ()
    if (NOT DEFINED FORT_SANITIZERS)
        set(FORT_SANITIZERS OFF)
    endif ()
    if (NOT DEFINED FORT_COVERAGE)
        set(FORT_COVERAGE OFF)
    endif ()
    if (NOT DEFINED FORT_DEAD_CODE_ELIMINATION)
        set(FORT_DEAD_CODE_ELIMINATION OFF)
    endif ()
    if (NOT DEFINED FORT_GDB_OPTIMIZATION)
        set(FORT_GDB_OPTIMIZATION OFF)
    endif ()
    if (NOT DEFINED FORT_VECTORIZATION_REPORT)
        set(FORT_VECTORIZATION_REPORT OFF)
    endif ()
    if (NOT DEFINED FORT_OPENMP)
        set(FORT_OPENMP OFF)
    endif ()

    # --- Create interface library ---
    if (NOT TARGET ${FORT_TARGET})
        add_library(${FORT_TARGET} INTERFACE)
    endif ()

    # --- Apply shared GCC backend flags ---
    gcc_base_apply_options(
            TARGET ${FORT_TARGET}
            TARGET_TYPE ${FORT_TARGET_TYPE}
            LTO ${FORT_LTO}
            PGO_GENERATE ${FORT_PGO_GENERATE}
            PGO_USE ${FORT_PGO_USE}
            SANITIZERS ${FORT_SANITIZERS}
            COVERAGE ${FORT_COVERAGE}
            DEAD_CODE_ELIMINATION ${FORT_DEAD_CODE_ELIMINATION}
            GDB_OPTIMIZATION ${FORT_GDB_OPTIMIZATION}
            VECTORIZATION_REPORT ${FORT_VECTORIZATION_REPORT}
            OPENMP ${FORT_OPENMP}
    )

    # =========================================================================
    # Fortran dialect flags (all build types)
    # Reference: https://gcc.gnu.org/onlinedocs/gfortran/Fortran-Dialect-Options.html
    # =========================================================================
    target_compile_options(${FORT_TARGET} INTERFACE
            -std=f${FORT_STANDARD}
            -fimplicit-none
            -fmodule-private
    )

    if (FORT_FREE_FORM)
        target_compile_options(${FORT_TARGET} INTERFACE
                -ffree-form
                -ffree-line-length-none
        )
    endif ()

    if (FORT_PREPROCESSOR)
        target_compile_options(${FORT_TARGET} INTERFACE -cpp)
    endif ()

    # =========================================================================
    # Exception handling (Debug only for Fortran — useful for backtraces)
    # =========================================================================
    target_compile_options(${FORT_TARGET} INTERFACE
            $<$<CONFIG:Debug>:-fexceptions>
            $<$<CONFIG:Debug>:-fasynchronous-unwind-tables>
    )

    # =========================================================================
    # Fortran warnings
    # Reference: https://gcc.gnu.org/onlinedocs/gfortran/Warning-Options.html
    # =========================================================================
    target_compile_options(${FORT_TARGET} INTERFACE
            -Wall
            -Wextra
            -Wpedantic
            -Waliasing
            -Wampersand
            $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:-Warray-temporaries>
            -Wc-binding-type
            -Wcharacter-truncation
            -Wline-truncation
            -Wconversion
            -Wconversion-extra
            -Wfrontend-loop-interchange
            -Wimplicit-interface
            -Wimplicit-procedure
            -Winteger-division
            -Wintrinsics-std
            -Wreal-q-constant
            -Wsurprising
            -Wtabs
            -Wundefined-do-loop
            -Wunderflow
            -Wintrinsic-shadow
            -Wuse-without-only
            -Wunused
            -Wunused-dummy-argument
            -Wunused-parameter
            -Wunused-variable
            -Wunused-function
            -Wunused-label
            -Walign-commons
            -Wfunction-elimination
            -Wrealloc-lhs
            -Wrealloc-lhs-all
            -Wcompare-reals
            -Wtarget-lifetime
            -Wzerotrip
            -Wdo-subscript
            -Wmaybe-uninitialized
            -Wuninitialized
    )

    # Warnings as errors
    if (FORT_WARNINGS_AS_ERRORS)
        target_compile_options(${FORT_TARGET} INTERFACE
                -Werror
                -fmax-errors=1
        )
    endif ()

    # =========================================================================
    # Fortran runtime checks (Debug only)
    # Reference: https://gcc.gnu.org/onlinedocs/gfortran/Code-Gen-Options.html
    # =========================================================================
    target_compile_options(${FORT_TARGET} INTERFACE
            $<$<CONFIG:Debug>:-fcheck=all>
            $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:-frealloc-lhs>
    )

    # FPE trapping (Debug)
    target_compile_options(${FORT_TARGET} INTERFACE
            $<$<CONFIG:Debug>:-fbacktrace>
            $<$<CONFIG:Debug>:-ffpe-trap=invalid,zero,overflow,underflow>
            $<$<CONFIG:Debug>:-ffpe-summary=all>
            $<$<CONFIG:Debug>:-fdump-core>
    )

    # =========================================================================
    # Debug initialization (optional — interferes with -Wmaybe-uninitialized)
    # =========================================================================
    if (FORT_INITIALIZE_DEBUG)
        target_compile_options(${FORT_TARGET} INTERFACE
                $<$<CONFIG:Debug>:-finit-local-zero>
                $<$<CONFIG:Debug>:-finit-integer=2147483647>
                $<$<CONFIG:Debug>:-finit-real=snan>
                $<$<CONFIG:Debug>:-finit-logical=false>
                $<$<CONFIG:Debug>:-finit-character=33>
        )
    endif ()

    # =========================================================================
    # GDB extras for Fortran (supplements base -O0 -fno-inline)
    # =========================================================================
    if (FORT_GDB_OPTIMIZATION)
        target_compile_options(${FORT_TARGET} INTERFACE
                $<$<CONFIG:Debug>:-fno-frontend-optimize>
                $<$<CONFIG:Debug>:-fno-inline-small-functions>
        )
    endif ()

    # =========================================================================
    # Fortran-specific optimizations (RelWithDebInfo)
    # =========================================================================
    target_compile_options(${FORT_TARGET} INTERFACE
            $<$<CONFIG:RelWithDebInfo>:-fbacktrace>
            $<$<CONFIG:RelWithDebInfo>:-frepack-arrays>
            $<$<CONFIG:RelWithDebInfo>:-ffrontend-optimize>
            $<$<CONFIG:RelWithDebInfo>:-ffrontend-loop-interchange>
    )

    # =========================================================================
    # Fortran-specific optimizations (Release)
    # =========================================================================
    target_compile_options(${FORT_TARGET} INTERFACE
            # Array handling
            $<$<CONFIG:Release>:-fstack-arrays>
            $<$<CONFIG:Release>:-frepack-arrays>
            $<$<CONFIG:Release>:-fno-realloc-lhs>
            # Procedure optimizations
            $<$<CONFIG:Release>:-faggressive-function-elimination>
            $<$<CONFIG:Release>:-ffrontend-optimize>
            $<$<CONFIG:Release>:-ffrontend-loop-interchange>
    )

    # =========================================================================
    # Fortran standard property
    # =========================================================================
    set_target_properties(${FORT_TARGET} PROPERTIES
            INTERFACE_Fortran_STANDARD ${FORT_STANDARD}
            INTERFACE_Fortran_STANDARD_REQUIRED ON
            INTERFACE_Fortran_EXTENSIONS OFF
    )

    message(STATUS "FortranCompilerOptions: Created '${FORT_TARGET}' (F${FORT_STANDARD}, ${FORT_TARGET_TYPE})")
endfunction()

# =============================================================================
# create_fortran_library_interface — Forces TARGET_TYPE=LIBRARY, adds -fPIC
# =============================================================================
function(create_fortran_library_interface)
    set(options "")
    set(oneValueArgs
            TARGET STANDARD
            PEDANTIC_WARNINGS WARNINGS_AS_ERRORS
            INITIALIZE_DEBUG PREPROCESSOR FREE_FORM
            LTO PGO_GENERATE PGO_USE
            SANITIZERS COVERAGE DEAD_CODE_ELIMINATION
            GDB_OPTIMIZATION VECTORIZATION_REPORT OPENMP
    )
    set(multiValueArgs "")
    cmake_parse_arguments(FORT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (NOT FORT_TARGET)
        set(FORT_TARGET fortran_library_options)
    endif ()

    # Forward all args with TARGET_TYPE forced to LIBRARY
    create_fortran_interface(
            TARGET ${FORT_TARGET}
            TARGET_TYPE LIBRARY
            STANDARD ${FORT_STANDARD}
            PEDANTIC_WARNINGS ${FORT_PEDANTIC_WARNINGS}
            WARNINGS_AS_ERRORS ${FORT_WARNINGS_AS_ERRORS}
            INITIALIZE_DEBUG ${FORT_INITIALIZE_DEBUG}
            PREPROCESSOR ${FORT_PREPROCESSOR}
            FREE_FORM ${FORT_FREE_FORM}
            LTO ${FORT_LTO}
            PGO_GENERATE ${FORT_PGO_GENERATE}
            PGO_USE ${FORT_PGO_USE}
            SANITIZERS ${FORT_SANITIZERS}
            COVERAGE ${FORT_COVERAGE}
            DEAD_CODE_ELIMINATION ${FORT_DEAD_CODE_ELIMINATION}
            GDB_OPTIMIZATION ${FORT_GDB_OPTIMIZATION}
            VECTORIZATION_REPORT ${FORT_VECTORIZATION_REPORT}
            OPENMP ${FORT_OPENMP}
    )
endfunction()

# =============================================================================
# create_fortran_executable_interface — Forces TARGET_TYPE=EXECUTABLE
# =============================================================================
function(create_fortran_executable_interface)
    set(options "")
    set(oneValueArgs
            TARGET STANDARD
            PEDANTIC_WARNINGS WARNINGS_AS_ERRORS
            INITIALIZE_DEBUG PREPROCESSOR FREE_FORM
            LTO PGO_GENERATE PGO_USE
            SANITIZERS COVERAGE DEAD_CODE_ELIMINATION
            GDB_OPTIMIZATION VECTORIZATION_REPORT OPENMP
    )
    set(multiValueArgs "")
    cmake_parse_arguments(FORT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (NOT FORT_TARGET)
        set(FORT_TARGET fortran_executable_options)
    endif ()

    create_fortran_interface(
            TARGET ${FORT_TARGET}
            TARGET_TYPE EXECUTABLE
            STANDARD ${FORT_STANDARD}
            PEDANTIC_WARNINGS ${FORT_PEDANTIC_WARNINGS}
            WARNINGS_AS_ERRORS ${FORT_WARNINGS_AS_ERRORS}
            INITIALIZE_DEBUG ${FORT_INITIALIZE_DEBUG}
            PREPROCESSOR ${FORT_PREPROCESSOR}
            FREE_FORM ${FORT_FREE_FORM}
            LTO ${FORT_LTO}
            PGO_GENERATE ${FORT_PGO_GENERATE}
            PGO_USE ${FORT_PGO_USE}
            SANITIZERS ${FORT_SANITIZERS}
            COVERAGE ${FORT_COVERAGE}
            DEAD_CODE_ELIMINATION ${FORT_DEAD_CODE_ELIMINATION}
            GDB_OPTIMIZATION ${FORT_GDB_OPTIMIZATION}
            VECTORIZATION_REPORT ${FORT_VECTORIZATION_REPORT}
            OPENMP ${FORT_OPENMP}
    )
endfunction()

# =============================================================================
# create_fortran_optimization_only_interface — Legacy F77 (no warnings/dialect)
# =============================================================================
function(create_fortran_optimization_only_interface)
    set(options "")
    set(oneValueArgs
            TARGET TARGET_TYPE
            LTO PGO_GENERATE PGO_USE
            COVERAGE DEAD_CODE_ELIMINATION OPENMP
    )
    set(multiValueArgs "")
    cmake_parse_arguments(FORT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (NOT FORT_TARGET)
        set(FORT_TARGET fortran_optimization_only)
    endif ()
    if (NOT FORT_TARGET_TYPE)
        set(FORT_TARGET_TYPE EXECUTABLE)
    endif ()

    # Create interface library
    if (NOT TARGET ${FORT_TARGET})
        add_library(${FORT_TARGET} INTERFACE)
    endif ()

    # Apply only the shared backend — no dialect, no warnings
    gcc_base_apply_options(
            TARGET ${FORT_TARGET}
            TARGET_TYPE ${FORT_TARGET_TYPE}
            LTO ${FORT_LTO}
            PGO_GENERATE ${FORT_PGO_GENERATE}
            PGO_USE ${FORT_PGO_USE}
            COVERAGE ${FORT_COVERAGE}
            DEAD_CODE_ELIMINATION ${FORT_DEAD_CODE_ELIMINATION}
            OPENMP ${FORT_OPENMP}
    )

    message(STATUS "FortranCompilerOptions: Created optimization-only '${FORT_TARGET}' (${FORT_TARGET_TYPE})")
endfunction()
