# Changelog

## watcher (development version)

## watcher 0.1.4

CRAN release: 2025-07-16

- Watcher can now use a system ‘libfswatch’ installed in a non-standard
  location ([\#28](https://github.com/r-lib/watcher/issues/28)).

## watcher 0.1.3

CRAN release: 2025-04-09

- [`watcher()`](https://watcher.r-lib.org/dev/reference/watcher.md) now
  accepts a vector for the `path` argument to monitor multiple files or
  directories ([\#16](https://github.com/r-lib/watcher/issues/16)).

- Fixes Windows bi-arch source builds for R \<= 4.1 using rtools40 and
  earlier ([\#19](https://github.com/r-lib/watcher/issues/19)).

## watcher 0.1.2

CRAN release: 2025-02-25

- Adds `$get_path()` and `$is_running()` methods to the `Watcher` R6
  class.
  - Use these rather than the fields `path` and `running`, as they have
    been made private.

## watcher 0.1.1

CRAN release: 2025-02-10

- Updates bundled ‘libfswatch’ source package to 1.19.0-dev.

## watcher 0.1.0

CRAN release: 2025-02-06

- Initial CRAN release.
