#' Watch a Filesystem Location
#'
#' Create a watch on a filesystem location. Start and stop monitoring
#' asynchronously.
#'
#' A limited subset of events are watched, namely: Created, Updated, Removed and
#' Renamed. Default latency is 1s.
#'
#' @param path character path to a file or directory to watch. Defaults to the
#'   current working directory.
#' @param recursive logical value, default TRUE, whether to recursively scan
#'   `path`, including all subdirectories.
#' @param callback (optional) a function (taking no arguments) to be called each
#'   time an event is triggered - requires the \pkg{later} package. The default,
#'   `NULL`, causes event paths and types to be written to `stdout` instead.
#'
#' @return A 'Watcher' R6 class object.
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
    recursive = TRUE,
    initialize = function(path = getwd(), recursive = TRUE, callback = NULL) {
      self$path <- path.expand(path)
      self$recursive <- as.logical(recursive)
      self$callback <- callback
      private$watch <- .Call(watcher_create, self$path, self$recursive, self$callback)
    },
    start = function() {
      res <- .Call(watcher_start_monitor, private$watch)
      if (res) self$active <- TRUE
      invisible(res)
    },
    stop = function() {
      res <- invisible(.Call(watcher_stop_monitor, private$watch))
      if (res) self$active <- FALSE
      invisible(res)
    },
    print = function(...) {
      cat(sprintf("<Watcher>\n  start()\n  stop()\n  path: %s\n  recursive: %s\n  active: %s\n",
                  self$path, self$recursive, self$active))
    }
  ),
  private = list(
    watch = NULL
  )
)
