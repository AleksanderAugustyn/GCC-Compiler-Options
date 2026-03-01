# GCCBaseOptions.cmake - Shared GCC backend flags for gcc/g++/gfortran
#
# This is a helper module — not called directly from CMakeLists.txt.
# The language-specific modules (CXXCompilerOptions, FortranCompilerOptions)
# call gcc_base_apply_options() internally.
#
# Covers: optimization tiers, debug flags, LTO, PGO, sanitizers, coverage,
# dead code elimination, hardening, diagnostics, vectorization reports,
# OpenMP, -fwhole-program/-fPIC gating.
#
# GCC-only by design. No abstraction for other compilers.
include_guard(GLOBAL)

function(gcc_base_apply_options)
    set(options "")
    set(oneValueArgs
            TARGET TARGET_TYPE
            LTO PGO_GENERATE PGO_USE
            SANITIZERS COVERAGE DEAD_CODE_ELIMINATION
            GDB_OPTIMIZATION VECTORIZATION_REPORT OPENMP
    )
    set(multiValueArgs "")
    cmake_parse_arguments(BASE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # --- Validate required args ---
    if (NOT BASE_TARGET)
        message(FATAL_ERROR "GCCBaseOptions: TARGET is required")
    endif ()
    if (NOT TARGET ${BASE_TARGET})
        message(FATAL_ERROR "GCCBaseOptions: Target '${BASE_TARGET}' does not exist")
    endif ()

    # --- Defaults ---
    if (NOT BASE_TARGET_TYPE)
        set(BASE_TARGET_TYPE EXECUTABLE)
    endif ()
    if (NOT DEFINED BASE_LTO)
        set(BASE_LTO ON)
    endif ()
    if (NOT DEFINED BASE_PGO_GENERATE)
        set(BASE_PGO_GENERATE OFF)
    endif ()
    if (NOT DEFINED BASE_PGO_USE)
        set(BASE_PGO_USE OFF)
    endif ()
    if (NOT DEFINED BASE_SANITIZERS)
        set(BASE_SANITIZERS OFF)
    endif ()
    if (NOT DEFINED BASE_COVERAGE)
        set(BASE_COVERAGE OFF)
    endif ()
    if (NOT DEFINED BASE_DEAD_CODE_ELIMINATION)
        set(BASE_DEAD_CODE_ELIMINATION OFF)
    endif ()
    if (NOT DEFINED BASE_GDB_OPTIMIZATION)
        set(BASE_GDB_OPTIMIZATION OFF)
    endif ()
    if (NOT DEFINED BASE_VECTORIZATION_REPORT)
        set(BASE_VECTORIZATION_REPORT OFF)
    endif ()
    if (NOT DEFINED BASE_OPENMP)
        set(BASE_OPENMP OFF)
    endif ()

    # --- PGO mutual exclusion ---
    if (BASE_PGO_GENERATE AND BASE_PGO_USE)
        message(FATAL_ERROR
                "GCCBaseOptions: Cannot enable both PGO_GENERATE and PGO_USE simultaneously.\n"
                "First build with PGO_GENERATE, run the binary, then rebuild with PGO_USE."
        )
    endif ()

    # =========================================================================
    # Diagnostics (all build types)
    # =========================================================================
    target_compile_options(${BASE_TARGET} INTERFACE
            -fdiagnostics-color=auto
            -fdiagnostics-show-caret
            -fdiagnostics-show-option
    )

    # =========================================================================
    # Debug build flags
    # Reference: https://gcc.gnu.org/onlinedocs/gcc/Debugging-Options.html
    # =========================================================================
    target_compile_options(${BASE_TARGET} INTERFACE
            $<$<CONFIG:Debug>:-Og>
            $<$<CONFIG:Debug>:-g3>
            $<$<CONFIG:Debug>:-ggdb3>
            $<$<CONFIG:Debug>:-fno-omit-frame-pointer>
            $<$<CONFIG:Debug>:-fvar-tracking>
            $<$<CONFIG:Debug>:-fvar-tracking-assignments>
    )

    # Hardening (Debug)
    target_compile_options(${BASE_TARGET} INTERFACE
            $<$<CONFIG:Debug>:-fstack-protector-strong>
    )

    # Hardening linker flags (Debug + RelWithDebInfo)
    target_link_options(${BASE_TARGET} INTERFACE
            $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:-Wl,-z,relro>
            $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:-Wl,-z,now>
    )

    # =========================================================================
    # GDB-friendly optimization override (Debug only)
    # =========================================================================
    if (BASE_GDB_OPTIMIZATION)
        target_compile_options(${BASE_TARGET} INTERFACE
                $<$<CONFIG:Debug>:-O0>
                $<$<CONFIG:Debug>:-fno-inline>
        )
    endif ()

    # =========================================================================
    # RelWithDebInfo build flags
    # Reference: https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html
    # =========================================================================
    target_compile_options(${BASE_TARGET} INTERFACE
            $<$<CONFIG:RelWithDebInfo>:-O2>
            $<$<CONFIG:RelWithDebInfo>:-g3>
            $<$<CONFIG:RelWithDebInfo>:-ggdb3>
            $<$<CONFIG:RelWithDebInfo>:-fno-omit-frame-pointer>
            $<$<CONFIG:RelWithDebInfo>:-march=native>
            $<$<CONFIG:RelWithDebInfo>:-mtune=native>
            $<$<CONFIG:RelWithDebInfo>:-funroll-loops>
    )

    # RelWithDebInfo math optimizations (partial fast-math)
    target_compile_options(${BASE_TARGET} INTERFACE
            $<$<CONFIG:RelWithDebInfo>:-fno-math-errno>
            $<$<CONFIG:RelWithDebInfo>:-freciprocal-math>
    )

    # RelWithDebInfo vectorization
    target_compile_options(${BASE_TARGET} INTERFACE
            $<$<CONFIG:RelWithDebInfo>:-ftree-vectorize>
            $<$<CONFIG:RelWithDebInfo>:-ftree-slp-vectorize>
            $<$<CONFIG:RelWithDebInfo>:-ftree-loop-distribution>
            $<$<CONFIG:RelWithDebInfo>:-finline-functions>
    )

    # =========================================================================
    # Release build flags (maximum optimization)
    # Reference: https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html
    # =========================================================================
    target_compile_options(${BASE_TARGET} INTERFACE
            $<$<CONFIG:Release>:-O3>
            $<$<CONFIG:Release>:-fno-omit-frame-pointer>
            $<$<CONFIG:Release>:-march=native>
            $<$<CONFIG:Release>:-mtune=native>
            $<$<CONFIG:Release>:-funroll-loops>
            $<$<CONFIG:Release>:-fomit-frame-pointer>
    )

    # Release fast-math
    target_compile_options(${BASE_TARGET} INTERFACE
            $<$<CONFIG:Release>:-ffast-math>
            $<$<CONFIG:Release>:-ffinite-math-only>
            $<$<CONFIG:Release>:-fno-signed-zeros>
            $<$<CONFIG:Release>:-fno-trapping-math>
            $<$<CONFIG:Release>:-freciprocal-math>
            $<$<CONFIG:Release>:-fassociative-math>
            $<$<CONFIG:Release>:-fno-signaling-nans>
            $<$<CONFIG:Release>:-fno-math-errno>
    )

    # Release vectorization
    target_compile_options(${BASE_TARGET} INTERFACE
            $<$<CONFIG:Release>:-ftree-vectorize>
            $<$<CONFIG:Release>:-ftree-slp-vectorize>
            $<$<CONFIG:Release>:-ftree-loop-vectorize>
            $<$<CONFIG:Release>:-ftree-loop-distribution>
            $<$<CONFIG:Release>:-ftree-loop-im>
            $<$<CONFIG:Release>:-fivopts>
            $<$<CONFIG:Release>:-fprefetch-loop-arrays>
    )

    # Release inlining
    target_compile_options(${BASE_TARGET} INTERFACE
            $<$<CONFIG:Release>:-finline-functions>
            $<$<CONFIG:Release>:-finline-limit=1000>
    )

    # Release alignment
    target_compile_options(${BASE_TARGET} INTERFACE
            $<$<CONFIG:Release>:-malign-data=cacheline>
    )

    # =========================================================================
    # LTO (Release only)
    # =========================================================================
    if (BASE_LTO)
        target_compile_options(${BASE_TARGET} INTERFACE
                $<$<CONFIG:Release>:-flto=auto>
        )
        target_link_options(${BASE_TARGET} INTERFACE
                $<$<CONFIG:Release>:-flto=auto>
                $<$<CONFIG:Release>:-fuse-linker-plugin>
        )
    endif ()

    # =========================================================================
    # Target type: EXECUTABLE vs LIBRARY
    # =========================================================================
    if (BASE_TARGET_TYPE STREQUAL "EXECUTABLE")
        target_compile_options(${BASE_TARGET} INTERFACE
                $<$<CONFIG:Release>:-fwhole-program>
        )
        target_link_options(${BASE_TARGET} INTERFACE
                $<$<CONFIG:Release>:-fwhole-program>
        )
    elseif (BASE_TARGET_TYPE STREQUAL "LIBRARY")
        target_compile_options(${BASE_TARGET} INTERFACE
                -fPIC
        )
    endif ()

    # =========================================================================
    # OpenMP
    # =========================================================================
    if (BASE_OPENMP)
        target_compile_options(${BASE_TARGET} INTERFACE
                -fopenmp
                -foffload=disable
        )
        target_link_options(${BASE_TARGET} INTERFACE
                -fopenmp
                -foffload=disable
        )
    endif ()

    # =========================================================================
    # PGO (Profile-Guided Optimization)
    # =========================================================================
    if (BASE_PGO_GENERATE)
        target_compile_options(${BASE_TARGET} INTERFACE -fprofile-generate)
        target_link_options(${BASE_TARGET} INTERFACE -fprofile-generate)
    elseif (BASE_PGO_USE)
        target_compile_options(${BASE_TARGET} INTERFACE
                -fprofile-use
                -fprofile-correction
        )
        target_link_options(${BASE_TARGET} INTERFACE -fprofile-use)
    endif ()

    # =========================================================================
    # Sanitizers (Debug only)
    # =========================================================================
    if (BASE_SANITIZERS)
        target_compile_options(${BASE_TARGET} INTERFACE
                $<$<CONFIG:Debug>:-fsanitize=address,undefined,leak>
        )
        target_link_options(${BASE_TARGET} INTERFACE
                $<$<CONFIG:Debug>:-fsanitize=address,undefined,leak>
        )
    endif ()

    # =========================================================================
    # Coverage
    # =========================================================================
    if (BASE_COVERAGE)
        target_compile_options(${BASE_TARGET} INTERFACE --coverage)
        target_link_options(${BASE_TARGET} INTERFACE --coverage)
    endif ()

    # =========================================================================
    # Dead code elimination (Release + RelWithDebInfo)
    # =========================================================================
    if (BASE_DEAD_CODE_ELIMINATION)
        target_compile_options(${BASE_TARGET} INTERFACE
                $<$<OR:$<CONFIG:Release>,$<CONFIG:RelWithDebInfo>>:-ffunction-sections>
                $<$<OR:$<CONFIG:Release>,$<CONFIG:RelWithDebInfo>>:-fdata-sections>
        )
        target_link_options(${BASE_TARGET} INTERFACE
                $<$<OR:$<CONFIG:Release>,$<CONFIG:RelWithDebInfo>>:-Wl,--gc-sections>
        )
    endif ()

    # =========================================================================
    # Vectorization report (Release + RelWithDebInfo)
    # =========================================================================
    if (BASE_VECTORIZATION_REPORT)
        target_compile_options(${BASE_TARGET} INTERFACE
                $<$<OR:$<CONFIG:Release>,$<CONFIG:RelWithDebInfo>>:-fopt-info-vec-optimized>
                $<$<OR:$<CONFIG:Release>,$<CONFIG:RelWithDebInfo>>:-fopt-info-vec-missed>
                $<$<OR:$<CONFIG:Release>,$<CONFIG:RelWithDebInfo>>:-fopt-info-loop-optimized>
        )
    endif ()

endfunction()
