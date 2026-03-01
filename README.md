# GCC CMake Options

Reusable CMake modules that define compiler flags for GCC-based Fortran and C++ projects.

Provides interface targets with comprehensive flag sets for Debug, RelWithDebInfo, and Release build types, including optimization tiers, warnings, sanitizers, LTO, PGO, coverage, and OpenMP support.

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
    GIT_TAG        v1.0.0
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
