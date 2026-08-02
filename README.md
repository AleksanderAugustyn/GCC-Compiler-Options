# GCC CMake Options

Reusable CMake modules that define compiler flags for GCC-based Fortran and C++ projects.

Provides interface targets with comprehensive flag sets for Debug, RelWithDebInfo, and Release build types, including optimization tiers, warnings, sanitizers, LTO, PGO, coverage, and OpenMP support.

Supported build types: Debug, RelWithDebInfo, Release (MinSizeRel and custom
configs receive only the unconditional flags). Flag redundancy decisions are
verified against GCC 13; see CHANGELOG.md.

## Requirements

- CMake 3.14+
- GCC (gfortran / g++)

## Usage

### Via FetchContent (recommended)

```cmake
include(FetchContent)
FetchContent_Declare(
    gcc_compiler_options
    GIT_REPOSITORY https://github.com/AleksanderAugustyn/gcc-cmake-options.git
    GIT_TAG        2.0.0
)
FetchContent_MakeAvailable(gcc_compiler_options)

include(GCCCompilerOptions/FortranCompilerOptions)
include(GCCCompilerOptions/CXXCompilerOptions)
include(GCCCompilerOptions/CompilerFlagSummary)
```

### Via git submodule

```bash
git submodule add https://github.com/AleksanderAugustyn/gcc-cmake-options.git extern/gcc-cmake-options
```

```cmake
add_subdirectory(extern/gcc-cmake-options)

include(GCCCompilerOptions/FortranCompilerOptions)
include(GCCCompilerOptions/CXXCompilerOptions)
include(GCCCompilerOptions/CompilerFlagSummary)
```

## Build profiles

`GCC_OPTS_PROFILE` names what the build is *for*. It resolves to `-march` and
`-mtune` for Release and RelWithDebInfo; Debug is unaffected.

| value | GCC >= 11 | GCC < 11 | use for |
|---|---|---|---|
| `portable` (default) | `-march=x86-64-v2` | `-march=nehalem -mtune=generic` | published wheels, anything that runs on a machine you do not control |
| `performance` | `-march=native` | `-march=native` | in-house perf-critical builds on the machine that will run them |

On non-x86 hosts `portable` emits no `-march`/`-mtune` at all — the generic ABI
baseline is already portable there.

`GCC_OPTS_MARCH` is the escape hatch. It defaults to empty ("the profile
decides"); any non-empty value overrides the profile's `-march`, and the profile
then contributes no `-mtune`, because `-march=<cpu>` already implies
`-mtune=<cpu>`. Use it to pin a cluster partition's ISA:

    cmake -B build -DGCC_OPTS_MARCH=haswell

### Preprocessing note

gcc-opts adds `-cpp` only where CMake does not already drive preprocessing:
never under Ninja (whose module-dependency scan preprocesses every Fortran
target and compiles with `-fpreprocessed`), and under Makefiles only when the
consuming target's `Fortran_PREPROCESS` property is unset. The check is a
generator expression on the consuming target, so it does not matter when you set
`CMAKE_Fortran_PREPROCESS`. It cannot see the **per-source** `Fortran_PREPROCESS`
property — if you set that, pass `PREPROCESSOR OFF` and manage `-cpp` yourself.

## Modules

| Module | Description |
|--------|-------------|
| `GCCBaseOptions` | Shared GCC backend flags (optimization, LTO, PGO, sanitizers, etc.) |
| `FortranCompilerOptions` | gfortran dialect, warnings, and runtime checks |
| `CXXCompilerOptions` | C++ dialect, warnings, and features |
| `CompilerFlagSummary` | Flag introspection and pretty-print reporting |

## Example

```cmake
# Create interface targets
create_fortran_library_interface(TARGET fortran_lib_flags OPENMP ON)
create_fortran_executable_interface(TARGET fortran_exe_flags OPENMP ON)
create_cxx_executable_interface(TARGET cxx_flags STANDARD 17)

# Perf profiling (production-as-built): wire a cache option through
# PROFILING_SYMBOLS — when ON, Release additionally gets
# -g -fno-omit-frame-pointer, appended after all other flags.
# option(ENABLE_PROFILING_SYMBOLS "..." OFF), then per interface:
#   create_fortran_library_interface(... PROFILING_SYMBOLS ${ENABLE_PROFILING_SYMBOLS})

# Link against them
target_link_libraries(my_fortran_lib PRIVATE fortran_lib_flags)
target_link_libraries(my_fortran_exe PRIVATE fortran_exe_flags)
target_link_libraries(my_cxx_exe PRIVATE cxx_flags)

# Print summary
print_compiler_flag_summary(
    TARGETS fortran_lib_flags fortran_exe_flags cxx_flags
    LABELS  "Fortran library" "Fortran executable" "C++ executable"
)
```

## License

MIT
