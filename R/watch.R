#' Watch a Filesystem Location
#'
#' Create a 'Watcher' on a filesystem location to monitor for changes in the
#' background.
#'
#' A limited subset of filesystem events are watched, namely: Created, Updated,
#' Removed and Renamed. Default latency is 1s.
#'
#' @param path character path to a file or directory to watch. Defaults to the
#'   current working directory.
#' @param recursive logical value, default TRUE, whether to recursively scan
#'   `path`, including all subdirectories.
#' @param callback (optional) a function (taking no arguments) to be called each
#'   time an event is triggered - requires the \pkg{later} package. The default,
#'   `NULL`, causes event paths and types to be written to `stdout` instead.
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
watcher <- function(path = getwd(), recursive = TRUE, callback = NULL) {
  Watcher$new(path, recursive, callback)
}

Watcher <- R6Class(
  "Watcher",
  public = list(
    active = FALSE,
    callback = NULL,
    path = NULL,
    recursive = NULL,
    initialize = function(path = getwd(), recursive = TRUE, callback = NULL) {
      if (is.null(self$path)) {
        self$path <- path.expand(path)
        self$recursive <- as.logical(recursive)
        self$callback <- callback
        private$watch <- .Call(watcher_create, self$path, self$recursive, self$callback)
      }
      invisible(self)
    },
    start = function() {
      res <- self$active
      if (!res) {
        self$active <- .Call(watcher_start_monitor, private$watch)
        res <- !self$active
      }
      invisible(!res)
    },
    stop = function() {
      res <- self$active
      if (res) {
        res <- .Call(watcher_stop_monitor, private$watch)
        self$active <- !res
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
