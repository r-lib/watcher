#' Watch a Filesystem Location
#'
#' Create a 'Watcher' on a filesystem location to monitor for changes in the
#' background.
#'
#' A limited subset of filesystem events are watched, namely: Created, Updated,
#' Removed and Renamed. Events are 'bubbled' such that if a single event
#' triggers multiple event flag types, the callback will be called only once.
#' Default latency is 1s.
#'
#' @param path Character path to a file, or directory to watch recursively.
#'   Defaults to the current working directory.
#' @param callback A function or formula (see [rlang::as_function]) - to be
#'   called each time an event is triggered. The default, `NULL`, causes event
#'   flag types and paths to be written to `stdout` instead.
#'
#' @return A 'Watcher' R6 class object. Start and stop background monitoring
#'   using the `$start()` and `$stop()` methods - these return a logical value
#'   whether or not they have succeeded.
#'
#' @examples
#' w <- watcher(tempdir())
#' isTRUE(w$start())
#' w
#' isTRUE(w$stop())
#' w
#'
#' @export
#'
watcher <- function(path = getwd(), callback = NULL) {
  Watcher$new(path, callback)
}

# Note: R6 class uses a field for 'running' instead of using 'fsw_is_running()'
# as the latter does not update immediately after stopping the monitor.

Watcher <- R6Class(
  "Watcher",
  public = list(
    path = NULL,
    running = FALSE,
    initialize = function(path, callback) {
      if (is.null(self$path)) {
        self$path <- path.expand(path)
        if (!is.null(callback) && !is.function(callback)) {
          callback <- rlang::as_function(callback)
        }
        private$watch <- .Call(watcher_create, self$path, callback)
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
