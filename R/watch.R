#' Watch a Filesystem Location
#'
#' Create a 'Watcher' on a filesystem location to monitor for changes in the
#' background.
#'
#' Uses the optimal event-driven API for each platform: 'ReadDirectoryChangesW'
#' on Windows, 'FSEvents' on MacOS, 'inotify' on Linux, 'kqueue' on BSD, and
#' 'File Events Notification' on Solaris/Illumos.
#'
#' Note: the `latency` setting does not mean that changes are polled for at this
#' interval, these still rely on the optimal platform-specific monitor. The
#' implementation of 'latency' is also platform-dependent.
#'
#' Events are 'bubbled' such that a single change that triggers multiple event
#' flags will cause the callback to be called only once.
#'
#' It is possible to set a watch on a path that does not currently exist, and it
#' will be monitored once created.
#'
#' @param path Character path to a file, or directory to watch recursively.
#'   Defaults to the current working directory.
#' @param callback A function or formula (see [rlang::as_function]), which takes
#'   at least one argument. It will be called back with a character vector
#'   comprising the paths of all files that have changed. The default, `NULL`,
#'   causes the paths that have changed to be written to `stdout` instead.
#' @param latency Numeric latency in seconds for events to be reported or
#'   callbacks triggered. The default is 1s.
#'
#' @return A 'Watcher' R6 class object. Start and stop background monitoring
#'   using the `$start()` and `$stop()` methods - these return a logical value
#'   whether or not they have succeeded.
#'
#' @examples
#' w <- watcher(tempdir())
#' w$start()
#' w
#' w$stop()
#' w
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
    path = NULL,
    running = FALSE,
    initialize = function(path, callback, latency) {
      if (is.null(self$path)) {
        self$path <- path.expand(path)
        if (!is.null(callback) && !is.function(callback)) {
          callback <- rlang::as_function(callback)
        }
        latency <- as.double(latency)
        private$watch <- .Call(watcher_create, self$path, callback, latency)
        lockBinding("path", self)
      }
      invisible(self)
    },
    start = function() {
      res <- self$running
      if (!res) {
        self$running <- .Call(watcher_start_monitor, private$watch)
        res <- !self$running
      }
      invisible(!res)
    },
    stop = function() {
      res <- self$running
      if (res) {
        res <- .Call(watcher_stop_monitor, private$watch)
        self$running <- !res
      }
      invisible(res)
    }
  ),
  private = list(
    watch = NULL
  ),
  cloneable = FALSE,
  lock_class = TRUE
)
