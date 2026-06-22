# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## Overview

`watcher` is an R package that provides R bindings for libfswatch, a
cross-platform file system monitoring library. It enables asynchronous
background monitoring of filesystem changes using optimal event-driven
APIs for each platform (ReadDirectoryChangesW on Windows, FSEvents on
macOS, inotify on Linux, kqueue on BSD, File Events Notification on
Solaris/Illumos).

## Build and Test Commands

### Package Development

``` bash
# Build and check the package
R CMD build .
R CMD check watcher_*.tar.gz

# Install from source (triggers configure script)
R CMD INSTALL .

# Run tests
Rscript -e "testthat::test_dir('tests/testthat')"

# Or interactively in R
R -e "devtools::test()"
```

### Single Test Execution

``` r

# In R console
testthat::test_file("tests/testthat/test-watch.R")
```

### Documentation

``` bash
# Generate documentation with roxygen2
Rscript -e "roxygen2::roxygenize()"
```

### CI/CD

The package uses GitHub Actions workflows in `.github/workflows/`: -
`R-CMD-check.yaml`: Comprehensive R CMD check across multiple OS/R
versions - `test-coverage.yaml`: Code coverage reporting -
`pkgdown.yaml`: Documentation site generation

## Architecture

### Core Components

**R Layer (`R/watch.R`):** -
[`watcher()`](https://watcher.r-lib.org/reference/watcher.md): Factory
function that creates a `Watcher` R6 object - `Watcher`: R6 class that
wraps the C interface with methods: - `$start()`: Start background
monitoring - `$stop()`: Stop monitoring - `$is_running()`: Check monitor
status - `$get_path()`: Get watched path(s) - The R6 class maintains a
reference to the C-level FSW_HANDLE via an external pointer

**C Layer (`src/`):** - `watcher.c`: Core implementation with three main
entry points: - `watcher_create()`: Initialize fswatch session with
paths, callback, and latency - `watcher_start_monitor()`: Spawn detached
pthread running `fsw_start_monitor()` - `watcher_stop_monitor()`: Stop
the monitoring thread - `init.c`: R package initialization that: -
Initializes libfswatch library - Obtains `execLaterNative2` from the
‘later’ package for async callbacks - Registers C callable methods -
`watcher.h`: Header file defining structures and function signatures

**Callback Mechanism:** - File events trigger `process_events()`
callback in C - Events are bundled by path and passed to R via the
‘later’ package’s `execLaterNative2` - R callbacks execute when R is
idle or when
[`later::run_now()`](https://later.r-lib.org/reference/run_now.html) is
called - If no callback is provided, events are printed to stdout

### Build System

The bundled libfswatch sources (`src/fswatch/`) are compiled **directly
into the package shared object** alongside `init.c`/`watcher.c` — no
cmake, no static archive, no separate library. Platform feature
selection comes from a hand-maintained config header, not host probing.

**Configure scripts:** - `configure` (Linux/macOS/other Unix): detects a
system libfswatch (`/usr/local`, `/usr`, Homebrew); if absent, sets up
the in-place bundled build. Probes for `-latomic` (ARM) and adds
`-framework CoreServices` (macOS), emits the `CXX_STD` line (only on R
\< 4.3), and substitutes `src/Makevars.in` → `src/Makevars`. -
`configure.ucrt` (Windows UCRT): computes only the `CXX_STD` line,
substituting `src/Makevars.ucrt.in` → `src/Makevars.ucrt`. - Legacy
non-UCRT Windows has no `configure.win`; it uses the static
`src/Makevars.win`, and `Biarch: true` keeps the dual i386/x64 build.

**Key pieces:** - `src/fswatch/.../libfswatch_config.h`:
hand-maintained; selects `HAVE_*` features from compiler platform macros
(replaces the cmake/autotools probe). -
`src/Makevars{.in,.win,.ucrt.in}`: declare the bundled objects and carry
one portable explicit compile rule per object (no GNU-make extensions).
The POSIX object list is `tools/fsw_objects_posix.list`; the Windows
object list is separate because those files include `<windows.h>`. -
`src/link.cpp`: empty `.cpp` that forces R to link with the C++
linker. - `tools/update_libfswatch.sh`: re-vendors libfswatch and
regenerates the config header, object list, and Makevars; calls
`tools/patch_libfswatch.sh`. - `tools/patch_libfswatch.sh`: idempotent
source patches — a null-format guard in `string_utils`, self-guards on
the fsevents/inotify/fanotify monitors, and neutering of libfswatch’s
stdout/stderr/cerr logging (for the R CMD check “compiled code” policy).

**Key dependencies:** an R C/C++ toolchain plus `make`; pthread; the
‘later’ R package. A system libfswatch is used automatically when
present.

### C++ Standard and Minimum R Version

The bundled libfswatch uses `std::filesystem` (in `path_utils`,
`poll_monitor`, and every monitor’s
[`scan()`](https://rdrr.io/r/base/scan.html)), which mandates **C++17**
— there is no portable pre-C++17 substitute. Because the package now
compiles libfswatch itself rather than via cmake, it relies on R’s own
`CXX_STD = CXX17`, support for which was added in **R 3.5.0**. That is
precisely why `DESCRIPTION` requires `R (>= 3.5)`: it is the lowest R
that can build the package (R \< 3.5 cannot request C++17), not an
arbitrary floor. `configure`/`configure.ucrt` emit `CXX_STD = CXX17`
only on R \< 4.3, since R \>= 4.3 defaults to C++17 and specifying it
then trips a CRAN “drop specification unless essential” NOTE.

### Event Filtering

The package filters filesystem events to only report main event types
(Created, Updated, Removed, Renamed) to prevent excessive callbacks.
Some platforms generate events for file reads, which are intentionally
excluded.

### Threading Model

- File monitoring runs in a detached pthread spawned by
  `watcher_start_monitor()`
- The thread runs `fsw_start_monitor()` which blocks until stopped
- Events from the monitoring thread are safely passed to R via the
  ‘later’ package
- External pointer finalizer ensures proper cleanup when Watcher objects
  are garbage collected

## Platform-Specific Notes

### Windows

- Uses ReadDirectoryChangesW API (always recursive)
- Windows latency has been specifically addressed (see NEWS.md - patch
  in v0.1.4.9000)
- Compiles the bundled libfswatch in place: UCRT via `Makevars.ucrt`
  (generated by `configure.ucrt`), legacy non-UCRT via the static
  `Makevars.win` (gcc 8.3 needs `-lstdc++fs` for `std::filesystem`);
  `Biarch: true` builds i386 + x64

### macOS

- Uses FSEvents API (always recursive)
- Links `-framework CoreServices`; can use a system libfswatch
  (Homebrew/MacPorts)

### Linux

- Uses inotify API
- Recursive monitoring is explicitly enabled to match Windows/macOS
  behavior
- May require -latomic on ARM architectures (Raspberry Pi)

### Testing

Tests in `tests/testthat/test-watch.R` cover: - Basic start/stop
lifecycle - Multiple watched paths - Callbacks with rlang-style
formulas - Unicode/international filenames (Japanese, French, Chinese
characters) - Error handling (negative latency) - Some tests skip on
aarch64 unless NOT_CRAN=true
