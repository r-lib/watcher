
<!-- README.md is generated from README.Rmd. Please edit that file -->

# watcher

<!-- badges: start -->

[![R-CMD-check](https://github.com/shikokuchuo/watcher/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/shikokuchuo/watcher/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/shikokuchuo/watcher/graph/badge.svg)](https://app.codecov.io/gh/shikokuchuo/watcher)
<!-- badges: end -->

Watch the File System for Changes

R binding for ‘libfswatch’, a filesystem monitoring library.

All functions are asynchronous and do not block your session.

- Set watches on files or directories recursively.
- Log activity, or trigger an R function to run when a specified event
  occurs.

## Installation

You can install the development version of watcher from:

``` r
pak::pak("shikokuchuo/watcher")
```

## Example

Create a ‘watch’ using `watcher::watcher()`.

By default this will watch your current working directory recursively
and write events to `stdout`.

Set the `callback` argument to run an arbitrary R function every time an
event triggers. This uses the `later` package to execute the callback
when R is idle at the top level, or whenever `later::run_now()` is
called, for example automatically as part of Shiny’s event loop.

``` r
library(watcher)
dir <- file.path(tempdir(), "watcher-example")
dir.create(dir)

w <- watcher(dir, recursive = TRUE, callback = function() print("event triggered"))

watcher_start(w)
Sys.sleep(1L)
file.create(file.path(dir, "oldfile"))
#> [1] TRUE
later::run_now(2L)
#> [1] "event triggered"
file.rename(file.path(dir, "oldfile"), file.path(dir, "newfile"))
#> [1] TRUE
later::run_now(2L)
#> [1] "event triggered"
file.remove(file.path(dir, "newfile"))
#> [1] TRUE
later::run_now(2L)
#> [1] "event triggered"
watcher_stop(w)

unlink(dir, force = TRUE)
```
