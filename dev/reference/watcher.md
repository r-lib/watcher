# Watch a Filesystem Location

Create a 'Watcher' on a filesystem location to monitor for changes in
the background.

## Usage

``` r
watcher(path = getwd(), callback = NULL, latency = 1)
```

## Arguments

- path:

  Character path to a file, or directory to watch recursively, or a
  vector of paths. Defaults to the current working directory.

- callback:

  A function or formula (see
  [rlang::as_function](https://rlang.r-lib.org/reference/as_function.html)),
  which takes at least one argument. It will be called back with a
  character vector comprising the paths of all files that have changed.
  The default, `NULL`, causes the paths that have changed to be written
  to `stdout` instead.

- latency:

  Numeric latency in seconds for events to be reported or callbacks
  triggered. The default is 1s.

## Value

A 'Watcher' R6 class object.

## Details

Uses an optimal event-driven API for each platform:
'ReadDirectoryChangesW' on Windows, 'FSEvents' on MacOS, 'inotify' on
Linux, 'kqueue' on BSD, and 'File Events Notification' on
Solaris/Illumos.

Note: the `latency` setting controls how often the changes are
processed, and does not mean that changes are polled for at this
interval. The changes are monitored in an event-driven fashion by the
platform-specific monitor. Events are 'bubbled' such that a single
change that triggers multiple filesystem events will cause the callback
to be called only once.

It is possible to set a watch on a path that does not currently exist,
and it will be monitored once created.

## Watcher Methods

A `Watcher` is an R6 class with the following methods:

- `$start()` starts background monitoring. Returns logical `TRUE` upon
  success, `FALSE` otherwise.

- `$stop()` stops background monitoring. Returns logical `TRUE` upon
  success, `FALSE` otherwise.

- `$get_path()` returns the watched path as a character string.

- `$is_running()` returns logical `TRUE` or `FALSE` depending on whether
  the monitor is running.

## Examples

``` r
w <- watcher(tempdir())
w$start()
w
#> <Watcher>
#>   Public:
#>     get_path: function () 
#>     initialize: function (path, callback, latency) 
#>     is_running: function () 
#>     start: function () 
#>     stop: function () 
#>   Private:
#>     path: /tmp/RtmpToD90W
#>     running: TRUE
#>     watch: externalptr
w$get_path()
#> [1] "/tmp/RtmpToD90W"
w$stop()
w$is_running()
#> [1] FALSE

Sys.sleep(1)
```
