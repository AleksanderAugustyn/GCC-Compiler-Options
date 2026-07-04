# Changelog

## 1.5.0 — 2026-07-04

Flags audited against GCC 13.3.0 (empirically, via `gcc -Q --help` diffs and
compile probes). Full audit spec: `docs/superpowers/specs/` (untracked).

### Behavior fixes
- **Release keeps frame pointers.** The Release block listed
  `-fno-omit-frame-pointer` followed by `-fomit-frame-pointer`; the later flag
  silently won, so Release shipped without frame pointers. Resolved to
  `-fno-omit-frame-pointer` — perf profiling now measures byte-identical
  production code.
- **realloc-on-assignment is consistent across configs.** Release carried
  `-fno-realloc-lhs` (shape-changing allocatable assignment silently kept the
  old shape) while Debug/RelWithDebInfo carried `-frealloc-lhs` plus
  `-Wrealloc-lhs`/`-Wrealloc-lhs-all` under `-Werror` (the same assignment
  failed to compile). All four flags removed; every config now follows F2018
  semantics.
- Debug FPE trapping no longer traps `underflow` (gradual underflow is benign
  in exp-heavy numerical code); `invalid,zero,overflow` remain.
- Legacy F77 interface (`create_fortran_optimization_only_interface`) gains
  `SANITIZERS`, `GDB_OPTIMIZATION`, `VECTORIZATION_REPORT` pass-through.
- `PEDANTIC_WARNINGS` was parsed but never read in both language modules;
  `-Wpedantic` is now actually conditional (default ON — no change unless you
  pass OFF).

### New
- `PROFILING_SYMBOLS` option on every factory function: appends
  `-g -fno-omit-frame-pointer` (Release only, after all other flags). Wire it
  from a preset via `ENABLE_PROFILING_SYMBOLS`; see the new `profiling` preset.
- Flag-contradiction guard test: resolved per-config flag dumps are scanned
  for `-fX`/`-fno-X` pairs (the bug class behind the frame-pointer defect).
- `release` and `profiling` test presets; `debug-sanitizers` preset now
  actually enables sanitizers in the test build.

### Removed (no behavior change at GCC 13; each site names the umbrella)
- Base: `-mtune=native`, `-g3` (beside `-ggdb3`), 7 `-ffast-math` component
  flags, 6 vectorizer flags default at `-O2`/`-O3`, `-finline-functions`,
  `-fuse-linker-plugin`, `leak` (inside ASan), `-fdiagnostics-show-caret`,
  `-fdiagnostics-show-option`.
- Fortran: 23 warnings inside `-Wall`/`-Wextra`/defaults, `-ffrontend-optimize`,
  `-ffrontend-loop-interchange`, Debug `-fexceptions` +
  `-fasynchronous-unwind-tables`, `-fno-inline-small-functions`.
- C++: 6 warnings inside `-Wall`/`-Wextra`/`-Wformat=2`/`-Weffc++`,
  `-fexceptions`, Debug `-fasynchronous-unwind-tables`, the decorative
  `INTERFACE_CXX_STANDARD` properties (`-std=c++<N>` is the single source).

Earlier releases: see git history.
