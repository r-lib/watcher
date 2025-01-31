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
#' @param watch a 'watch' object.
#'
#' @return For [watcher]: a 'watch' object. \cr
#'   For [watcher_start] and [watcher_stop]: invisibly, `TRUE` upon success or
#'   `FALSE` otherwise.
#'
#' @examples
#' watch <- watcher(tempdir())
#' isTRUE(watcher_start(watch))
#' watch
#' isTRUE(watcher_stop(watch))
#' watch
#'
#' @export
#'
watcher <- function(path = getwd(), recursive = TRUE, callback = NULL) {
  .Call(watcher_create, path, recursive, callback)
}

#' @rdname watcher
#' @export
#'
watcher_start <- function(watch) {
  invisible(.Call(watcher_start_monitor, watch))
}

#' @rdname watcher
#' @export
#'
watcher_stop <- function(watch) {
  invisible(.Call(watcher_stop_monitor, watch))
}

#' @export
#'
print.watch <- function(x, ...) {

  cat(sprintf("< watch >\n  path: %s\n  recursive: %s\n  active: %s\n",
              attr(x, "path"), attr(x, "recursive"), attr(x, "active")))
  invisible(x)

}
