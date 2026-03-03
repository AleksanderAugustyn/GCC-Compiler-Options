# CXXCompilerOptions.cmake - C++ dialect, warnings, and features
#
# Calls gcc_base_apply_options() from GCCBaseOptions.cmake for shared backend flags.
# This module owns only C++-specific flags.
#
# Public functions:
#   create_cxx_interface(...)
#   create_cxx_library_interface(...)
#   create_cxx_executable_interface(...)
#
# GCC-only by design.
include_guard(GLOBAL)
include(GCCCompilerOptions/GCCBaseOptions)

if (NOT CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    message(WARNING "CXXCompilerOptions: Designed for GNU C++. Current: ${CMAKE_CXX_COMPILER_ID}")
endif ()

# =============================================================================
# create_cxx_interface — Full C++ interface target
# =============================================================================
function(create_cxx_interface)
    set(options "")
    set(oneValueArgs
            TARGET TARGET_TYPE STANDARD
            PEDANTIC_WARNINGS WARNINGS_AS_ERRORS
            RTTI
            LTO PGO_GENERATE PGO_USE
            SANITIZERS COVERAGE DEAD_CODE_ELIMINATION
            GDB_OPTIMIZATION VECTORIZATION_REPORT OPENMP
    )
    set(multiValueArgs "")
    cmake_parse_arguments(CXX "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # --- Defaults ---
    if (NOT CXX_TARGET)
        set(CXX_TARGET cxx_options)
    endif ()
    if (NOT CXX_TARGET_TYPE)
        set(CXX_TARGET_TYPE EXECUTABLE)
    endif ()
    if (NOT CXX_STANDARD)
        set(CXX_STANDARD 20)
    endif ()
    if (NOT DEFINED CXX_PEDANTIC_WARNINGS)
        set(CXX_PEDANTIC_WARNINGS ON)
    endif ()
    if (NOT DEFINED CXX_WARNINGS_AS_ERRORS)
        set(CXX_WARNINGS_AS_ERRORS ON)
    endif ()
    if (NOT DEFINED CXX_RTTI)
        set(CXX_RTTI ON)
    endif ()
    if (NOT DEFINED CXX_LTO)
        set(CXX_LTO ON)
    endif ()
    if (NOT DEFINED CXX_PGO_GENERATE)
        set(CXX_PGO_GENERATE OFF)
    endif ()
    if (NOT DEFINED CXX_PGO_USE)
        set(CXX_PGO_USE OFF)
    endif ()
    if (NOT DEFINED CXX_SANITIZERS)
        set(CXX_SANITIZERS OFF)
    endif ()
    if (NOT DEFINED CXX_COVERAGE)
        set(CXX_COVERAGE OFF)
    endif ()
    if (NOT DEFINED CXX_DEAD_CODE_ELIMINATION)
        set(CXX_DEAD_CODE_ELIMINATION OFF)
    endif ()
    if (NOT DEFINED CXX_GDB_OPTIMIZATION)
        set(CXX_GDB_OPTIMIZATION OFF)
    endif ()
    if (NOT DEFINED CXX_VECTORIZATION_REPORT)
        set(CXX_VECTORIZATION_REPORT OFF)
    endif ()
    if (NOT DEFINED CXX_OPENMP)
        set(CXX_OPENMP OFF)
    endif ()

    # --- Create interface library ---
    if (NOT TARGET ${CXX_TARGET})
        add_library(${CXX_TARGET} INTERFACE)
    endif ()

    # --- Apply shared GCC backend flags ---
    gcc_base_apply_options(
            TARGET ${CXX_TARGET}
            TARGET_TYPE ${CXX_TARGET_TYPE}
            LTO ${CXX_LTO}
            PGO_GENERATE ${CXX_PGO_GENERATE}
            PGO_USE ${CXX_PGO_USE}
            SANITIZERS ${CXX_SANITIZERS}
            COVERAGE ${CXX_COVERAGE}
            DEAD_CODE_ELIMINATION ${CXX_DEAD_CODE_ELIMINATION}
            GDB_OPTIMIZATION ${CXX_GDB_OPTIMIZATION}
            VECTORIZATION_REPORT ${CXX_VECTORIZATION_REPORT}
            OPENMP ${CXX_OPENMP}
    )

    # =========================================================================
    # C++ dialect
    # =========================================================================
    target_compile_options(${CXX_TARGET} INTERFACE
            -std=c++${CXX_STANDARD}
    )

    # C++ always needs exceptions
    target_compile_options(${CXX_TARGET} INTERFACE
            -fexceptions
            $<$<CONFIG:Debug>:-fasynchronous-unwind-tables>
    )

    # RTTI
    if (NOT CXX_RTTI)
        target_compile_options(${CXX_TARGET} INTERFACE -fno-rtti)
    endif ()

    # =========================================================================
    # Core warnings
    # Reference: https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html
    # =========================================================================
    target_compile_options(${CXX_TARGET} INTERFACE
            -Wall
            -Wextra
            -Wpedantic
            -Wconversion
            -Wdouble-promotion
            -Wfloat-equal
            -Wformat=2
            -Wformat-security
            -Wimplicit-fallthrough
            -Wlogical-op
            -Wmissing-declarations
            -Wmissing-include-dirs
            -Wpointer-arith
            -Wredundant-decls
            -Wshadow
            -Wsign-conversion
            -Wswitch-default
            -Wswitch-enum
            -Wundef
            -Wuninitialized
            -Wunused
            -Wcast-align
            -Wcast-qual
            -Wnull-dereference
    )

    # =========================================================================
    # C++-specific warnings
    # =========================================================================
    target_compile_options(${CXX_TARGET} INTERFACE
            -Wnon-virtual-dtor
            -Woverloaded-virtual
            -Wctor-dtor-privacy
            -Wdangling-reference
            -Weffc++
            -Wnoexcept
            -Wsign-promo
            -Wstrict-null-sentinel
            -Wsuggest-override
            -Wold-style-cast
            -Wuseless-cast
            -Wzero-as-null-pointer-constant
    )

    # =========================================================================
    # Extra warnings
    # =========================================================================
    target_compile_options(${CXX_TARGET} INTERFACE
            -Walloca
            -Warray-bounds=2
            -Wformat-overflow=2
            -Wformat-truncation=2
            -Wstringop-overflow=4
            $<$<CONFIG:Debug>:-Wstack-usage=8192>
            $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:-Wduplicated-cond>
            $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:-Wduplicated-branches>
    )

    # =========================================================================
    # Werror
    # =========================================================================
    if (CXX_WARNINGS_AS_ERRORS)
        target_compile_options(${CXX_TARGET} INTERFACE
                -Werror
                -fmax-errors=1
        )
    endif ()

    # =========================================================================
    # C++ standard property
    # =========================================================================
    set_target_properties(${CXX_TARGET} PROPERTIES
            INTERFACE_CXX_STANDARD ${CXX_STANDARD}
            INTERFACE_CXX_STANDARD_REQUIRED ON
            INTERFACE_CXX_EXTENSIONS OFF
    )

    message(STATUS "CXXCompilerOptions: Created '${CXX_TARGET}' (C++${CXX_STANDARD}, ${CXX_TARGET_TYPE})")
endfunction()

# =============================================================================
# create_cxx_library_interface — Forces TARGET_TYPE=LIBRARY
# =============================================================================
function(create_cxx_library_interface)
    set(options "")
    set(oneValueArgs
            TARGET STANDARD
            PEDANTIC_WARNINGS WARNINGS_AS_ERRORS RTTI
            LTO PGO_GENERATE PGO_USE
            SANITIZERS COVERAGE DEAD_CODE_ELIMINATION
            GDB_OPTIMIZATION VECTORIZATION_REPORT OPENMP
    )
    set(multiValueArgs "")
    cmake_parse_arguments(CXX "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (NOT CXX_TARGET)
        set(CXX_TARGET cxx_library_options)
    endif ()

    create_cxx_interface(
            TARGET ${CXX_TARGET}
            TARGET_TYPE LIBRARY
            STANDARD ${CXX_STANDARD}
            PEDANTIC_WARNINGS ${CXX_PEDANTIC_WARNINGS}
            WARNINGS_AS_ERRORS ${CXX_WARNINGS_AS_ERRORS}
            RTTI ${CXX_RTTI}
            LTO ${CXX_LTO}
            PGO_GENERATE ${CXX_PGO_GENERATE}
            PGO_USE ${CXX_PGO_USE}
            SANITIZERS ${CXX_SANITIZERS}
            COVERAGE ${CXX_COVERAGE}
            DEAD_CODE_ELIMINATION ${CXX_DEAD_CODE_ELIMINATION}
            GDB_OPTIMIZATION ${CXX_GDB_OPTIMIZATION}
            VECTORIZATION_REPORT ${CXX_VECTORIZATION_REPORT}
            OPENMP ${CXX_OPENMP}
    )
endfunction()

# =============================================================================
# create_cxx_executable_interface — Forces TARGET_TYPE=EXECUTABLE
# =============================================================================
function(create_cxx_executable_interface)
    set(options "")
    set(oneValueArgs
            TARGET STANDARD
            PEDANTIC_WARNINGS WARNINGS_AS_ERRORS RTTI
            LTO PGO_GENERATE PGO_USE
            SANITIZERS COVERAGE DEAD_CODE_ELIMINATION
            GDB_OPTIMIZATION VECTORIZATION_REPORT OPENMP
    )
    set(multiValueArgs "")
    cmake_parse_arguments(CXX "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (NOT CXX_TARGET)
        set(CXX_TARGET cxx_executable_options)
    endif ()

    create_cxx_interface(
            TARGET ${CXX_TARGET}
            TARGET_TYPE EXECUTABLE
            STANDARD ${CXX_STANDARD}
            PEDANTIC_WARNINGS ${CXX_PEDANTIC_WARNINGS}
            WARNINGS_AS_ERRORS ${CXX_WARNINGS_AS_ERRORS}
            RTTI ${CXX_RTTI}
            LTO ${CXX_LTO}
            PGO_GENERATE ${CXX_PGO_GENERATE}
            PGO_USE ${CXX_PGO_USE}
            SANITIZERS ${CXX_SANITIZERS}
            COVERAGE ${CXX_COVERAGE}
            DEAD_CODE_ELIMINATION ${CXX_DEAD_CODE_ELIMINATION}
            GDB_OPTIMIZATION ${CXX_GDB_OPTIMIZATION}
            VECTORIZATION_REPORT ${CXX_VECTORIZATION_REPORT}
            OPENMP ${CXX_OPENMP}
    )
endfunction()
