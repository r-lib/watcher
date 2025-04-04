# watcher (development version)

* `watcher()` now accepts a vector for the `path` argument to monitor multiple files or directories (#16).
* Fixes Windows bi-arch source builds for R <= 4.1 using rtools40 and earlier (#19).

# watcher 0.1.2

* Adds `$get_path()` and `$is_running()` methods to the `Watcher` R6 class.
  + Use these rather than the fields `path` and `running`, as they have been made private.

# watcher 0.1.1

* Updates bundled 'libfswatch' source package to 1.19.0-dev.

# watcher 0.1.0

* Initial CRAN release.
