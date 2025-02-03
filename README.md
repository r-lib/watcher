
<!-- README.md is generated from README.Rmd. Please edit that file -->

# watcher

<!-- badges: start -->

[![R-CMD-check](https://github.com/shikokuchuo/watcher/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/shikokuchuo/watcher/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/shikokuchuo/watcher/graph/badge.svg)](https://app.codecov.io/gh/shikokuchuo/watcher)
<!-- badges: end -->

Watch the File System for Changes

R binding for ‘libfswatch’, a file system monitoring library. This uses
the optimal event-driven API for each platform: `ReadDirectoryChangesW`
on Windows, `FSEvents` on MacOS, `inotify` on Linux, `kqueue` on BSD,
and `File Events Notification` on Solaris/Illumos.

Watching is done asynchronously in the background, without blocking the
session.

- Watch files, or directories recursively.
- Log activity, or trigger an R function to run every time an event
  occurs.

## Installation

You can install the development version of watcher from:

``` r
pak::pak("shikokuchuo/watcher")
```

## Example

Create a ‘Watcher’ using `watcher::watcher()`.

By default this will watch the current working directory recursively and
write events to `stdout`.

Set the `callback` argument to run an arbitrary R function, or
`rlang`-style formula, every time a file changes:

- Uses the `later` package to execute the callback when R is idle at the
  top level, or
- Whenever `later::run_now()` is called, for instance automatically in
  Shiny’s event loop.

``` r
library(watcher)
dir <- file.path(tempdir(), "watcher-example")
dir.create(dir)

w <- watcher(dir, callback = ~print("event triggered"), latency = 0.1)
w
#> <Watcher>
#>   Public:
#>     initialize: function (path, callback, latency) 
#>     path: /tmp/Rtmp3M0FZQ/watcher-example
#>     running: FALSE
#>     start: function () 
#>     stop: function () 
#>   Private:
#>     watch: externalptr
w$start()

Sys.sleep(0.1)
file.create(file.path(dir, "oldfile"))
#> [1] TRUE
later::run_now(0.1)
#> [1] "event triggered"

file.rename(file.path(dir, "oldfile"), file.path(dir, "newfile"))
#> [1] TRUE
later::run_now(0.1)
#> [1] "event triggered"

file.remove(file.path(dir, "newfile"))
#> [1] TRUE
later::run_now(0.1)
#> [1] "event triggered"

w$stop()
unlink(dir, recursive = TRUE, force = TRUE)
```
