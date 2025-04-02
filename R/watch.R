#' Watch a Filesystem Location
#'
#' Create a 'Watcher' on a filesystem location to monitor for changes in the
#' background.
#'
#' Uses an optimal event-driven API for each platform: 'ReadDirectoryChangesW'
#' on Windows, 'FSEvents' on MacOS, 'inotify' on Linux, 'kqueue' on BSD, and
#' 'File Events Notification' on Solaris/Illumos.
#'
#' Note: the `latency` setting controls how often the changes are processed, and
#' does not mean that changes are polled for at this interval. The changes are
#' monitored in an event-driven fashion by the platform-specific monitor. Events
#' are 'bubbled' such that a single change that triggers multiple filesystem
#' events will cause the callback to be called only once.
#'
#' It is possible to set a watch on a path that does not currently exist, and it
#' will be monitored once created.
#'
#' @param path Character path to a file, or directory to watch recursively, or a
#'   vector of paths. Defaults to the current working directory.
#' @param callback A function or formula (see [rlang::as_function]), which takes
#'   at least one argument. It will be called back with a character vector
#'   comprising the paths of all files that have changed. The default, `NULL`,
#'   causes the paths that have changed to be written to `stdout` instead.
#' @param latency Numeric latency in seconds for events to be reported or
#'   callbacks triggered. The default is 1s.
#'
#' @return A 'Watcher' R6 class object.
#'
#' @section Watcher Methods:
#'
#' A `Watcher` is an R6 class with the following methods:
#'
#' - `$start()` starts background monitoring. Returns logical `TRUE` upon
#'   success, `FALSE` otherwise.
#' - `$stop()` stops background monitoring. Returns logical `TRUE` upon success,
#'   `FALSE` otherwise.
#' - `$get_path()` returns the watched path as a character string.
#' - `$is_running()` returns logical `TRUE` or `FALSE` depending on whether the
#'   monitor is running.
#'
#' @examples
#' w <- watcher(tempdir())
#' w$start()
#' w
#' w$get_path()
#' w$stop()
#' w$is_running()
#'
#' Sys.sleep(1)
#'
#' @export
#'
watcher <- function(path = getwd(), callback = NULL, latency = 1) {
  Watcher$new(path, callback, latency)
}

# Note: R6 class uses a field for 'running' instead of using 'fsw_is_running()'
# as the latter does not update immediately after stopping the monitor.

Watcher <- R6Class(
  "Watcher",
  public = list(
    initialize = function(path, callback, latency) {
      if (is.null(private$path)) {
        private$path <- path.expand(path)
        if (!is.null(callback) && !is.function(callback)) {
          callback <- rlang::as_function(callback)
        }
        latency <- as.double(latency)
        private$watch <- .Call(watcher_create, private$path, callback, latency)
      }
      invisible(self)
    },
    get_path = function() {
      private$path
    },
    is_running = function() {
      private$running
    },
    start = function() {
      res <- private$running
      if (!res) {
        private$running <- .Call(watcher_start_monitor, private$watch)
        res <- !private$running
      }
      invisible(!res)
    },
    stop = function() {
      res <- private$running
      if (res) {
        res <- .Call(watcher_stop_monitor, private$watch)
        private$running <- !res
      }
      invisible(res)
    }
  ),
  private = list(
    path = NULL,
    running = FALSE,
    watch = NULL
  ),
  cloneable = FALSE,
  lock_class = TRUE
)
