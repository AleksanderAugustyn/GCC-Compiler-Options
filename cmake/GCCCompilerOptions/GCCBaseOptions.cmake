# GCCBaseOptions.cmake - Shared GCC backend flags for gcc/g++/gfortran
#
# This is a helper module — not called directly from CMakeLists.txt.
# The language-specific modules (CXXCompilerOptions, FortranCompilerOptions)
# call gcc_base_apply_options() internally.
#
# Covers: optimization tiers, debug flags, LTO, PGO, sanitizers, coverage,
# dead code elimination, hardening, diagnostics, vectorization reports,
# OpenMP, -fPIE/-fPIC gating.
#
# GCC-only by design. No abstraction for other compilers.
include_guard(GLOBAL)

# -march for the optimized configs. Default keeps historical behavior (tune to
# the build host); portable artifact builds (manylinux wheels) pin an ISA
# level instead, e.g. -DGCC_OPTS_MARCH=x86-64-v2.
set(GCC_OPTS_MARCH "native" CACHE STRING
        "-march= value for Release and RelWithDebInfo builds")

function(gcc_base_apply_options)
    set(options "")
    set(oneValueArgs
            TARGET TARGET_TYPE
            LTO PGO_GENERATE PGO_USE
            SANITIZERS COVERAGE DEAD_CODE_ELIMINATION
            GDB_OPTIMIZATION VECTORIZATION_REPORT OPENMP
            PROFILING_SYMBOLS
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
    if (NOT DEFINED BASE_PROFILING_SYMBOLS)
        set(BASE_PROFILING_SYMBOLS OFF)
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
    # (-fdiagnostics-show-caret and -fdiagnostics-show-option are GCC 13 defaults)
    target_compile_options(${BASE_TARGET} INTERFACE
            -fdiagnostics-color=auto
    )

    # =========================================================================
    # Debug build flags
    # Reference: https://gcc.gnu.org/onlinedocs/gcc/Debugging-Options.html
    # =========================================================================
    # (-ggdb3 subsumes -g3; -Og moves to the if/else below)
    target_compile_options(${BASE_TARGET} INTERFACE
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
    # Debug optimization level: -Og normally; -O0 -fno-inline for GDB stepping.
    # Explicit if/else — never rely on last-wins flag ordering.
    # =========================================================================
    if (BASE_GDB_OPTIMIZATION)
        target_compile_options(${BASE_TARGET} INTERFACE
                $<$<CONFIG:Debug>:-O0>
                $<$<CONFIG:Debug>:-fno-inline>
        )
    else ()
        target_compile_options(${BASE_TARGET} INTERFACE
                $<$<CONFIG:Debug>:-Og>
        )
    endif ()

    # =========================================================================
    # RelWithDebInfo build flags
    # Reference: https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html
    # =========================================================================
    # (-ggdb3 subsumes -g3; -mtune is implied by -march only for the native default)
    target_compile_options(${BASE_TARGET} INTERFACE
            $<$<CONFIG:RelWithDebInfo>:-O2>
            $<$<CONFIG:RelWithDebInfo>:-ggdb3>
            $<$<CONFIG:RelWithDebInfo>:-fno-omit-frame-pointer>
            $<$<CONFIG:RelWithDebInfo>:-march=${GCC_OPTS_MARCH}>
            $<$<CONFIG:RelWithDebInfo>:-funroll-loops>
    )

    # RelWithDebInfo math optimizations (partial fast-math)
    target_compile_options(${BASE_TARGET} INTERFACE
            $<$<CONFIG:RelWithDebInfo>:-fno-math-errno>
            $<$<CONFIG:RelWithDebInfo>:-freciprocal-math>
    )

    # RelWithDebInfo vectorization. -ftree-vectorize, -ftree-slp-vectorize and
    # -finline-functions are already default at -O2 on GCC 13;
    # -ftree-loop-distribution is not — keep it.
    target_compile_options(${BASE_TARGET} INTERFACE
            $<$<CONFIG:RelWithDebInfo>:-ftree-loop-distribution>
    )

    # =========================================================================
    # Release build flags (maximum optimization)
    # Reference: https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html
    # =========================================================================
    # Frame pointers stay ON in Release: perf profiling then measures
    # byte-identical production code (cost: one reserved register, <1%).
    # (-mtune is implied by -march only for the native default)
    target_compile_options(${BASE_TARGET} INTERFACE
            $<$<CONFIG:Release>:-O3>
            $<$<CONFIG:Release>:-fno-omit-frame-pointer>
            $<$<CONFIG:Release>:-march=${GCC_OPTS_MARCH}>
            $<$<CONFIG:Release>:-funroll-loops>
    )

    # Release fast-math. The umbrella already enables -ffinite-math-only,
    # -fno-signed-zeros, -fno-trapping-math, -freciprocal-math,
    # -fassociative-math, -fno-signaling-nans and -fno-math-errno.
    target_compile_options(${BASE_TARGET} INTERFACE
            $<$<CONFIG:Release>:-ffast-math>
    )

    # Release vectorization. -ftree-vectorize, -ftree-slp-vectorize,
    # -ftree-loop-vectorize, -ftree-loop-distribution, -ftree-loop-im and
    # -fivopts are already default at -O3 on GCC 13.
    target_compile_options(${BASE_TARGET} INTERFACE
            $<$<CONFIG:Release>:-fprefetch-loop-arrays>
    )

    # Release inlining (-finline-functions is default at -O2 and above)
    target_compile_options(${BASE_TARGET} INTERFACE
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
        # (-fuse-linker-plugin is default with -flto and a plugin-capable linker)
        target_link_options(${BASE_TARGET} INTERFACE
                $<$<CONFIG:Release>:-flto=auto>
        )
    endif ()

    # =========================================================================
    # Target type: EXECUTABLE vs LIBRARY
    # =========================================================================
    if (BASE_TARGET_TYPE STREQUAL "EXECUTABLE")
        target_compile_options(${BASE_TARGET} INTERFACE -fPIE)
        target_link_options(${BASE_TARGET} INTERFACE -pie)
    elseif (BASE_TARGET_TYPE STREQUAL "LIBRARY")
        target_compile_options(${BASE_TARGET} INTERFACE -fPIC)
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
        # LeakSanitizer is built into ASan — listing leak is redundant
        target_compile_options(${BASE_TARGET} INTERFACE
                $<$<CONFIG:Debug>:-fsanitize=address,undefined>
        )
        target_link_options(${BASE_TARGET} INTERFACE
                $<$<CONFIG:Debug>:-fsanitize=address,undefined>
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

    # =========================================================================
    # Profiling symbols (Release only) — appended after every other base flag
    # so they win any last-wins interaction; -g does not change codegen, so
    # the profiled binary stays production-as-built (LTO included).
    # Release-gated on purpose: Debug/RelWithDebInfo already carry -ggdb3 and
    # a later plain -g would downgrade debug info from level 3 to 2.
    # =========================================================================
    if (BASE_PROFILING_SYMBOLS)
        target_compile_options(${BASE_TARGET} INTERFACE
                $<$<CONFIG:Release>:-g>
                $<$<CONFIG:Release>:-fno-omit-frame-pointer>
        )
    endif ()

endfunction()
