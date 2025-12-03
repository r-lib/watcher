# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

`watcher` is an R package that provides R bindings for libfswatch, a cross-platform file system monitoring library. It enables asynchronous background monitoring of filesystem changes using optimal event-driven APIs for each platform (ReadDirectoryChangesW on Windows, FSEvents on macOS, inotify on Linux, kqueue on BSD, File Events Notification on Solaris/Illumos).

## Build and Test Commands

### Package Development
```bash
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
```r
# In R console
testthat::test_file("tests/testthat/test-watch.R")
```

### Documentation
```bash
# Generate documentation with roxygen2
Rscript -e "roxygen2::roxygenize()"
```

### CI/CD
The package uses GitHub Actions workflows in `.github/workflows/`:
- `R-CMD-check.yaml`: Comprehensive R CMD check across multiple OS/R versions
- `test-coverage.yaml`: Code coverage reporting
- `pkgdown.yaml`: Documentation site generation

## Architecture

### Core Components

**R Layer (`R/watch.R`):**
- `watcher()`: Factory function that creates a `Watcher` R6 object
- `Watcher`: R6 class that wraps the C interface with methods:
  - `$start()`: Start background monitoring
  - `$stop()`: Stop monitoring
  - `$is_running()`: Check monitor status
  - `$get_path()`: Get watched path(s)
- The R6 class maintains a reference to the C-level FSW_HANDLE via an external pointer

**C Layer (`src/`):**
- `watcher.c`: Core implementation with three main entry points:
  - `watcher_create()`: Initialize fswatch session with paths, callback, and latency
  - `watcher_start_monitor()`: Spawn detached pthread running `fsw_start_monitor()`
  - `watcher_stop_monitor()`: Stop the monitoring thread
- `init.c`: R package initialization that:
  - Initializes libfswatch library
  - Obtains `execLaterNative2` from the 'later' package for async callbacks
  - Registers C callable methods
- `watcher.h`: Header file defining structures and function signatures

**Callback Mechanism:**
- File events trigger `process_events()` callback in C
- Events are bundled by path and passed to R via the 'later' package's `execLaterNative2`
- R callbacks execute when R is idle or when `later::run_now()` is called
- If no callback is provided, events are printed to stdout

### Build System

**Configure Scripts:**
- `configure` (Linux/macOS): Detects system-installed libfswatch in standard locations (`/usr/local`, `/usr`, homebrew paths). If not found, compiles bundled libfswatch (v1.19.0-dev) using cmake. Handles special cases like ARM atomic operations.
- `configure.win` (Windows non-UCRT): Compiles libfswatch from source for both x64 and i386 architectures
- `configure.ucrt` (Windows UCRT): Simplified version for modern Windows R builds
- All scripts generate `src/Makevars` with appropriate compiler flags

**Key Dependencies:**
- libfswatch (bundled source in `src/fswatch/`)
- cmake (required for compiling libfswatch from source)
- pthread (for background monitoring thread)
- 'later' R package (for async callback execution)

### Event Filtering

The package filters filesystem events to only report main event types (Created, Updated, Removed, Renamed) to prevent excessive callbacks. Some platforms generate events for file reads, which are intentionally excluded.

### Threading Model

- File monitoring runs in a detached pthread spawned by `watcher_start_monitor()`
- The thread runs `fsw_start_monitor()` which blocks until stopped
- Events from the monitoring thread are safely passed to R via the 'later' package
- External pointer finalizer ensures proper cleanup when Watcher objects are garbage collected

## Platform-Specific Notes

### Windows
- Uses ReadDirectoryChangesW API (always recursive)
- Windows latency has been specifically addressed (see NEWS.md - patch in v0.1.4.9000)
- Builds require cmake and compile libfswatch from bundled source

### macOS
- Uses FSEvents API (always recursive)
- Can use system libfswatch if installed via homebrew/MacPorts
- MACOSX_DEPLOYMENT_TARGET is automatically extracted from compiler flags

### Linux
- Uses inotify API
- Recursive monitoring is explicitly enabled to match Windows/macOS behavior
- May require -latomic on ARM architectures (Raspberry Pi)

### Testing
Tests in `tests/testthat/test-watch.R` cover:
- Basic start/stop lifecycle
- Multiple watched paths
- Callbacks with rlang-style formulas
- Unicode/international filenames (Japanese, French, Chinese characters)
- Error handling (negative latency)
- Some tests skip on aarch64 unless NOT_CRAN=true
